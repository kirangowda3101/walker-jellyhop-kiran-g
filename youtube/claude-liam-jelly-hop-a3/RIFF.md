# RIFF — A3 film

Observations Liam's lines are built on, each from something inspected:

- Screenshot 12's status bar reads "Tris:72" with six objects listed (Handle, Head, Prong_1…). The fork is built from boxes only, so the prong tips are blunt (TEST-REPORT A3.12).
- Screenshot 13 vs 15: the cover goes from near-white to pink; the cherry picker in 15 shows #DA303F, the restored original, not the final #A6111E (INDEX.md row 15).
- Screenshot 19: the platform's right side and the reference cube's left side render pure black under one DirectionalLight3D with no WorldEnvironment (TEST-REPORT A3.12).
- The headless log's fork lowest Y is 2.98e-08 m, not 0: export rounding inside the 1 mm tolerance (A3.4).
- The check's expected values are typed from the brief (test line 7), so it can catch an export that drifts from the brief; it cannot catch a brief that was wrong.
