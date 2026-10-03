#!/usr/bin/env python3
"""Batch 3 audio generation for Jelly Hop: Fork From Above (AUDIO-BRIEF.md section 2, step 2).

Runs inside ~/Documents/jellyhop-audio-env. Every prompt, negative prompt and setting is read
from gen-inputs/batch3-audio-prompts.md as committed in 5fc8efb; the file's committed text must be
unchanged (checked), and dated notes may only be appended after it.

  python tools/batch3_generate.py --test DIR   one short test take per model into DIR (timing only)
  python tools/batch3_generate.py              all takes: 3 seeds x 7 sounds

Raw WAVs (32-bit float, exactly as the model returned them) go to
~/Documents/jellyhop-generations/audio/<ID>-take<N>-seed<SEED>.wav; an existing file is never
overwritten (the script stops). For every take it records: model ID and Hugging Face revision,
library versions, device, prompt, negative prompt, seed, length, sampling settings, run time and
the output file's SHA-256. Log: evidence/batch3-generation-log.txt (+ .json).
The Hugging Face token is never read by this script; huggingface_hub uses the saved login itself.
"""
import argparse, hashlib, json, platform, re, subprocess, sys, time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PROMPTS = REPO / "gen-inputs" / "batch3-audio-prompts.md"
PROMPTS_COMMIT = "5fc8efb"
RAW_DIR = Path.home() / "Documents" / "jellyhop-generations" / "audio"
LOG_TXT = REPO / "evidence" / "batch3-generation-log.txt"
LOG_JSON = REPO / "evidence" / "batch3-generation-log.json"

SAO_ID, SAO_REV = "stabilityai/stable-audio-open-1.0", "f21265c1e2710b3bd2386596943f0007f55f802e"
MG_ID, MG_REV = "facebook/musicgen-small", "4c8334b02c6ec4e8664a91979669a501ec497792"
SEEDS = [7270, 7271, 7272]
SFX_ORDER = ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN"]


def stop(msg):
    print(f"\nSTOPPED: {msg}", file=sys.stderr)
    sys.exit(1)


def read_prompts():
    """Parse the committed prompts file; stop if it changed since the pre-generation commit."""
    # The committed text must be unchanged; dated notes may only be appended after it.
    committed = subprocess.run(["git", "-C", str(REPO), "show", f"{PROMPTS_COMMIT}:gen-inputs/{PROMPTS.name}"],
                               capture_output=True, text=True, check=True).stdout
    if not PROMPTS.read_text().startswith(committed):
        stop(f"{PROMPTS.name}: the text committed in {PROMPTS_COMMIT} has been changed (only appended notes are allowed)")
    text = committed   # prompts and settings are read from the committed text only
    for needle in ["seeds **7270, 7271, 7272**", "100 diffusion steps, CFG scale 7.0",
                   "1,500 tokens at 50 Hz", "top-k 250, temperature 1.0, guidance scale 3.0"]:
        if needle not in text:
            stop(f"expected setting not found in the prompts file: {needle}")
    neg_all = re.search(r"Negative prompt for every sound effect except SFX-WIN: `([^`]+)`", text).group(1)
    neg_win = re.search(r"Negative prompt for SFX-WIN: `([^`]+)`", text).group(1)
    sfx = {}
    for m in re.finditer(r"^\| (SFX-[A-Z-]+) \| [^|]+ \| ([0-9.]+) s \| `([^`]+)` \|$", text, re.M):
        sfx[m.group(1)] = {"length_s": float(m.group(2)), "prompt": m.group(3),
                           "negative_prompt": neg_win if m.group(1) == "SFX-WIN" else neg_all}
    if list(sfx) != SFX_ORDER:
        stop(f"sound effect rows not as expected: {list(sfx)}")
    music = re.search(r"^\| MUS-LOOP \| [^|]+ \| `([^`]+)` \|$", text, re.M).group(1)
    return sfx, music


def versions():
    import torch, diffusers, transformers, numpy, soundfile, huggingface_hub, accelerate
    return {"python": platform.python_version(), "torch": torch.__version__, "diffusers": diffusers.__version__,
            "transformers": transformers.__version__, "accelerate": accelerate.__version__,
            "numpy": numpy.__version__, "soundfile": soundfile.__version__,
            "huggingface_hub": huggingface_hub.__version__, "macos": platform.mac_ver()[0],
            "machine": platform.machine()}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def write_wav(path, audio, rate):
    import soundfile as sf
    if path.exists():
        stop(f"refusing to overwrite {path}")
    sf.write(str(path), audio, rate, subtype="FLOAT")


SNAP_NOTE = ("workaround: diffusers BrownianTreeNoiseSampler query times within torchsde's tolerance (1e-6) of the "
             "sampler bounds (sigma_min 0.3, sigma_max 500) are snapped onto the bound. Without it, the final step's "
             "float32 sigma 0.30000001 vs bound 0.3 becomes a zero-width interval after torchsde's rounding and recurses "
             "forever (RecursionError on MPS and CPU). It only changes that degenerate final query, which then returns "
             "torchsde's zero increment; prompts, seeds, steps, CFG and the default sampler are unchanged.")


def patch_noise_sampler():
    """See SNAP_NOTE. Applied once, before the pipeline runs."""
    import torch
    from diffusers.schedulers import scheduling_dpmsolver_sde as sde
    cls = sde.BrownianTreeNoiseSampler
    if getattr(cls, "_jellyhop_snap", False):
        return
    orig_init, orig_call = cls.__init__, cls.__call__

    def init(self, x, sigma_min, sigma_max, seed=None, transform=lambda v: v):
        self._bounds = (float(sigma_min), float(sigma_max))
        orig_init(self, x, sigma_min, sigma_max, seed=seed, transform=transform)

    def snap(self, v):
        f = float(v)
        for b in self._bounds:
            if abs(f - b) < 1e-6:
                return torch.as_tensor(b, dtype=torch.float64)
        return v

    def call(self, sigma, sigma_next):
        return orig_call(self, snap(self, sigma), snap(self, sigma_next))

    cls.__init__, cls.__call__, cls._jellyhop_snap = init, call, True


class SAO:
    """Stable Audio Open 1.0 through diffusers' StableAudioPipeline (MPS, CPU fallback)."""
    steps, cfg = 100, 7.0

    def __init__(self, device):
        import torch
        from diffusers import StableAudioPipeline
        patch_noise_sampler()
        self.torch = torch
        self.pipe = StableAudioPipeline.from_pretrained(SAO_ID, revision=SAO_REV, torch_dtype=torch.float32)
        self.pipe.to(device)
        self.device = device
        self.rate = self.pipe.vae.sampling_rate
        self.sampler = type(self.pipe.scheduler).__name__

    def take(self, prompt, negative, seed, length):
        gen = self.torch.Generator("cpu").manual_seed(seed)   # CPU generator: same noise on any device
        out = self.pipe(prompt, negative_prompt=negative, num_inference_steps=self.steps, guidance_scale=self.cfg,
                        audio_end_in_s=length, num_waveforms_per_prompt=1, generator=gen)
        audio = out.audios[0].T.float().cpu().numpy()          # (samples, channels)
        return audio, self.rate

    def settings(self):
        return {"num_inference_steps": self.steps, "guidance_scale": self.cfg, "sampler": f"{self.sampler} (library default)",
                "dtype": "float32", "sample_rate": self.rate, "channels": 2, "noise_sampler_patch": SNAP_NOTE}


class MusicGen:
    """MusicGen-small through transformers (MPS, CPU fallback)."""
    tokens, top_k, temperature, guidance = 1500, 250, 1.0, 3.0

    def __init__(self, device):
        import torch
        from transformers import AutoProcessor, MusicgenForConditionalGeneration
        self.torch = torch
        self.processor = AutoProcessor.from_pretrained(MG_ID, revision=MG_REV)
        self.model = MusicgenForConditionalGeneration.from_pretrained(MG_ID, revision=MG_REV).to(device)
        self.device = device
        self.rate = self.model.config.audio_encoder.sampling_rate

    def take(self, prompt, negative, seed, length, tokens=None):
        self.torch.manual_seed(seed)                            # seeds CPU and MPS generators
        inputs = self.processor(text=[prompt], padding=True, return_tensors="pt").to(self.device)
        audio = self.model.generate(**inputs, do_sample=True, top_k=self.top_k, temperature=self.temperature,
                                    guidance_scale=self.guidance, max_new_tokens=tokens or self.tokens)
        return audio[0, 0].float().cpu().numpy(), self.rate      # mono

    def settings(self, tokens=None):
        return {"max_new_tokens": tokens or self.tokens, "frame_rate_hz": 50, "do_sample": True, "top_k": self.top_k,
                "temperature": self.temperature, "guidance_scale": self.guidance, "sample_rate": self.rate, "channels": 1}


def load(cls, wanted):
    """Load on MPS; if that fails, record why and use the CPU."""
    try:
        return cls(wanted), None
    except Exception as e:  # noqa: BLE001 - recorded, then CPU fallback
        return cls("cpu"), f"{wanted} failed to load: {type(e).__name__}: {e}"


def run_take(model, kind_id, rev, take_id, seed, prompt, negative, length, out_path, note, **kw):
    t0 = time.perf_counter()
    fallback = None
    try:
        audio, rate = model.take(prompt, negative, seed, length, **kw)
    except Exception as e:  # noqa: BLE001
        if model.device == "cpu":
            raise
        fallback = f"{model.device} failed during generation: {type(e).__name__}: {e}"
        stop(f"{take_id}: {fallback} (not retried on CPU automatically; report and decide)")
    seconds = time.perf_counter() - t0
    write_wav(out_path, audio, rate)
    settings = model.settings(**({"tokens": kw["tokens"]} if "tokens" in kw else {}))
    return {"take": take_id, "model": kind_id, "revision": rev, "device": model.device, "seed": seed,
            "prompt": prompt, "negative_prompt": negative, "requested_length_s": length,
            "output_length_s": round(len(audio) / rate, 3), "settings": settings,
            "run_time_s": round(seconds, 2), "file": str(out_path), "sha256": sha256(out_path),
            "created": datetime.now().isoformat(timespec="seconds"), "note": note}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--test", metavar="DIR", help="one short test take per model into DIR")
    ap.add_argument("--sao-device", choices=["mps", "cpu"], default="mps", help="device for Stable Audio Open")
    ap.add_argument("--mg-device", choices=["mps", "cpu"], default="mps", help="device for MusicGen")
    ap.add_argument("--device-note", default="", help="why these devices (recorded in the log)")
    args = ap.parse_args()
    sfx, music = read_prompts()
    import torch
    if not torch.backends.mps.is_available():
        args.sao_device = args.mg_device = "cpu"
    env = versions()
    records, notes = [], []

    if args.test:
        out = Path(args.test)
        out.mkdir(parents=True, exist_ok=True)
        t0 = time.perf_counter()
        sao, why = load(SAO, args.sao_device)
        load_s = time.perf_counter() - t0
        notes.append(f"SAO load {load_s:.1f} s on {sao.device}" + (f" ({why})" if why else ""))
        s = sfx["SFX-HOP"]
        records.append(run_take(sao, SAO_ID, SAO_REV, "TEST-SFX-HOP", 7270, s["prompt"], s["negative_prompt"],
                                s["length_s"], out / "TEST-SFX-HOP-seed7270.wav", "test take: full settings, timing only"))
        del sao
        t0 = time.perf_counter()
        mg, why = load(MusicGen, args.mg_device)
        load_s = time.perf_counter() - t0
        notes.append(f"MusicGen load {load_s:.1f} s on {mg.device}" + (f" ({why})" if why else ""))
        records.append(run_take(mg, MG_ID, MG_REV, "TEST-MUS-LOOP-5s", 7270, music, None, 5.0,
                                out / "TEST-MUS-LOOP-5s-seed7270.wav", "test take: 250 tokens (5 s) instead of 1,500, timing only",
                                tokens=250))
        print(json.dumps({"environment": env, "devices": {"sao": args.sao_device, "musicgen": args.mg_device}, "notes": notes, "takes": records}, indent=2))
        return

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    planned = [(sid, n + 1, seed) for sid in SFX_ORDER for n, seed in enumerate(SEEDS)]
    for sid, n, seed in planned + [("MUS-LOOP", i + 1, s) for i, s in enumerate(SEEDS)]:
        p = RAW_DIR / f"{sid}-take{n}-seed{seed}.wav"
        if p.exists():
            stop(f"{p} already exists; nothing generated")
    log = open(LOG_TXT, "w")

    def say(line):
        print(line, flush=True)
        log.write(line + "\n")
        log.flush()

    say(f"== Batch 3 generation  {datetime.now():%Y-%m-%d %H:%M:%S}")
    say(f"prompts: {PROMPTS.relative_to(REPO)} (unchanged since {PROMPTS_COMMIT}); raw output: {RAW_DIR}")
    say("environment: " + json.dumps(env))
    say(f"devices: Stable Audio Open {args.sao_device}, MusicGen {args.mg_device}; reason: {args.device_note or '-'}")
    t0 = time.perf_counter()
    sao, why = load(SAO, args.sao_device)
    say(f"Stable Audio Open loaded on {sao.device} in {time.perf_counter() - t0:.1f} s" + (f"; {why}" if why else ""))
    for sid, n, seed in planned:
        s = sfx[sid]
        r = run_take(sao, SAO_ID, SAO_REV, f"{sid}-take{n}", seed, s["prompt"], s["negative_prompt"], s["length_s"],
                     RAW_DIR / f"{sid}-take{n}-seed{seed}.wav", "")
        records.append(r)
        say(json.dumps(r))
    del sao
    t0 = time.perf_counter()
    mg, why = load(MusicGen, args.mg_device)
    say(f"MusicGen-small loaded on {mg.device} in {time.perf_counter() - t0:.1f} s" + (f"; {why}" if why else ""))
    for n, seed in enumerate(SEEDS, 1):
        r = run_take(mg, MG_ID, MG_REV, f"MUS-LOOP-take{n}", seed, music, None, 30.0,
                     RAW_DIR / f"MUS-LOOP-take{n}-seed{seed}.wav", "")
        records.append(r)
        say(json.dumps(r))
    LOG_JSON.write_text(json.dumps({"environment": env, "takes": records}, indent=2) + "\n")
    say(f"DONE: {len(records)} takes")
    log.close()


if __name__ == "__main__":
    main()
