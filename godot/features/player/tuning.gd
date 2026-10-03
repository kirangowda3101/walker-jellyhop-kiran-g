extends Resource
## Values from GDD 0.2.0. A shared resource for gameplay and fixtures.
## Jelly Hop: every length and speed is x2 because the world moved from a 640x360 to a
## 1280x720 base. Unit conversion only; on screen the jump is unchanged. Ticks unchanged.
@export var speed: float = 320.0
@export var acceleration: float = 2560.0
@export var deceleration: float = 3840.0
@export var jump_velocity: float = -640.0
@export var gravity: float = 1920.0
@export var terminal_velocity: float = 960.0
@export var coyote_ticks: int = 6
@export var buffer_ticks: int = 6
