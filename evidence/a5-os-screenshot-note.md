# In-engine capture vs OS screenshot (done once, as the assignment asks)

2026-10-28, Compatibility, hint-experiment scene, by Kiran Gowda.

- OS screenshot: `os_screenshot_hint_experiment.png` (macOS Cmd+Shift+4, window capture, 1504 × 1008, carries an ICC colour-profile tag). Bands measured: 64, 128 and 192 on both quads (about 64,800 pixels each).
- In-engine capture: `hint_experiment.png` (viewport texture saved by `capture_a5.gd`). Bands measured: 64, 128 and 192 on both quads.

They agree exactly on this display. I still trust the in-engine capture for measurements: it reads the frame Godot drew, at viewport resolution, while an OS screenshot passes through the display's colour profile and window scaling (the window frame, title bar and shadow are in the image), which can shift values on other displays or settings.
