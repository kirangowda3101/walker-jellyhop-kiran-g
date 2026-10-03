extends Resource
## Jelly Hop slice: the one place for the open values of SLICE-BRIEF.md §9 and the art sizes.
## Values marked DEFAULT are build defaults, to be tuned in playtesting.
## Values marked DECIDED come from Kiran's decisions or the Batch 2 review; values marked
## MEASURED come from the art itself. Movement (speed, jump) lives in features/player/tuning.gd.

# ---- Screen and table (Batch 2 review sizes) ----
const VIEW := Vector2(1280, 720)
const TABLE_TOP := 520.0                      ## DECIDED: 200 px table strip along the bottom
const TABLE_SCALE := 0.3378                   ## DECIDED: ENV-TABLE 592 px tall -> 200 px
const PLATE_SCALE := 0.1986                   ## DECIDED: plate 200 px wide
const SAUCE_SCALE := 0.1299                   ## DECIDED: sauce 120 x 19
const DOME_SCALE := 0.2452                    ## DECIDED: dome 180 x 128
const JELLY_SCALE := 0.1060                   ## DECIDED: resting cube 64 x 64
const JELLY_ANCHOR := Vector2(512, 812)       ## MEASURED: every pose's bottom edge is at y 811-812

# ---- Plate art, measured from ENV-PLATE.png (rows are art pixels) ----
const PLATE_ART_BOTTOM_ROW := 144.0           ## MEASURED: last opaque row
const PLATE_ART_LANDING_ROW := 33.0           ## MEASURED: ~5 game px below the rim's top row 8
const PLATE_ART_LANDING_SPAN := Vector2(16, 1008)  ## MEASURED: opaque x range on the landing row
const PLATE_ART_CENTER_X := 511.5             ## MEASURED: centre of the drawn plate (8 + 1007 / 2)

# ---- Fork (Kiran, 2026-10-03: the tines span the plate's full width; hit zone = visible tines) ----
const FORK_TINE_SPAN_PX := 200.0              ## DECIDED: visible tine span on screen
const FORK_TINE_ART_SPAN := Vector2(9, 326)   ## MEASURED: x range of the four tines in ENV-FORK.png
const FORK_RAISED_TIP_Y := 240.0              ## DEFAULT: tine tips while raised (above the jelly's hop peak)

# ---- Level layout ----
const FIRST_PLATE_LEFT := 160.0               ## DEFAULT
const PLATE_GAPS := [120.0, 140.0, 150.0, 160.0, 170.0]  ## DEFAULT: edge to edge, plate 1 -> 6
const SAUCE_IN_GAP := [false, true, false, true, true]   ## DEFAULT: sauce in gaps 2, 4 and 5
const DOME_GAP := 150.0                       ## DEFAULT: bare table between plate 6 and the dome
const LEVEL_MARGIN_RIGHT := 250.0             ## DEFAULT: table beyond the dome

# ---- Fork cycles, per plate (seconds). null = no fork. ----
## Each cycle: SAFE (raised) -> SHADOW (grows) -> STRIKE (down, hold, up) -> SAFE.
## offset = seconds into the cycle at the start of play (the cycle starts with the safe window).
## Forks on screen at the start begin in their safe window (offset < safe), so nothing warns at
## the start. Forks off screen at the start (plates 5 and 6) begin halfway into their shadow
## phase (offset = safe + shadow / 2), frozen during the intro pan, so the pan shows shadows
## as panel 1 lists (Kiran, 2026-10-03).
const FORK_CYCLES := [                        ## DEFAULT (all)
	null,
	{"shadow": 1.6, "safe": 2.2, "offset": 0.0},
	{"shadow": 1.4, "safe": 1.9, "offset": 1.0},
	{"shadow": 1.3, "safe": 1.6, "offset": 0.4},
	{"shadow": 1.2, "safe": 1.4, "offset": 2.0},   # off screen at the start: mid-shadow
	{"shadow": 1.0, "safe": 1.2, "offset": 1.7},   # off screen at the start: mid-shadow
]
const STRIKE_DOWN := 0.12                     ## DEFAULT
const STRIKE_HOLD := 0.30                     ## DEFAULT
const STRIKE_UP := 0.28                       ## DEFAULT

# ---- Jelly timing ----
const BORED_DELAY := 4.0                      ## DEFAULT: seconds without input before the bored slump
const ANTIC_TICKS := 4                        ## DEFAULT: crouch pose at takeoff (visual only, no input delay)
const LAND_TICKS := 8                         ## DEFAULT: landing squash pose
const SCOOT_FRAME := 0.12                     ## DEFAULT: scoot A/B swap time
const SPLAT_TIME := 0.6                       ## DEFAULT
const REFORM_TIME := 0.7                      ## DEFAULT
const WIN_SLIDE := 0.3                        ## DEFAULT: slide to the dome's centre
const PROMPT_DELAY := 1.0                     ## DEFAULT: "press any key to play again" appears after this

# ---- Camera ----
const INTRO_PAN := 4.0                        ## DEFAULT: dome -> jelly, ease in-out
const LOOK_AHEAD := 240.0                     ## DEFAULT: camera centre is this far right of the jelly
const CAMERA_SMOOTHING := 4.0                 ## DEFAULT: Camera2D smoothing speed (gives the respawn glide)
const SHAKE_PX := 8.0                         ## DEFAULT: fork splat only, camera offset only
const SHAKE_TIME := 0.25                      ## DEFAULT

# ---- Music targets: volume dB on the Music bus, low-pass cutoff Hz (20500 = open) ----
const MUSIC := {                              ## DEFAULT (all)
	"intro": {"db": -8.0, "cutoff": 20500.0},
	"normal": {"db": 0.0, "cutoff": 20500.0},
	"warning": {"db": -9.0, "cutoff": 900.0},
	"splat": {"db": -12.0, "cutoff": 20500.0},
	"pause": {"db": -20.0, "cutoff": 500.0},
	"win_fade": {"db": -40.0, "cutoff": 20500.0},
	"end_quiet": {"db": -40.0, "cutoff": 20500.0},
}
const MUSIC_RAMP := 0.25                      ## DEFAULT: seconds for a change of target
const WIN_FADE_TIME := 1.5                    ## DEFAULT

# ---- Room ----
const ROOM_PARALLAX := false                  ## DEFAULT: static room; parallax only if approved
const ROOM_BRIGHTNESS := 1.0                  ## DEFAULT: unchanged; flagged for review

# ---- Derived values ----
static func plate_lefts() -> Array[float]:
	var out: Array[float] = [FIRST_PLATE_LEFT]
	for gap in PLATE_GAPS:
		out.append(out.back() + plate_width() + gap)
	return out

static func plate_width() -> float:  ## drawn width (1007 art px; the canvas adds an 8 px empty border)
	return 1007.0 * PLATE_SCALE

static func plate_landing_y() -> float:
	return TABLE_TOP - (PLATE_ART_BOTTOM_ROW - PLATE_ART_LANDING_ROW) * PLATE_SCALE

static func plate_landing_half_width() -> float:
	return (PLATE_ART_LANDING_SPAN.y - PLATE_ART_LANDING_SPAN.x) * PLATE_SCALE / 2.0

static func fork_scale() -> float:
	return FORK_TINE_SPAN_PX / (FORK_TINE_ART_SPAN.y - FORK_TINE_ART_SPAN.x)

static func dome_left() -> float:
	return plate_lefts().back() + plate_width() + DOME_GAP

static func dome_width() -> float:
	return 750.0 * DOME_SCALE

static func level_width() -> float:
	return dome_left() + dome_width() + LEVEL_MARGIN_RIGHT

static func ticks(seconds: float) -> int:
	return int(round(seconds * 60.0))
