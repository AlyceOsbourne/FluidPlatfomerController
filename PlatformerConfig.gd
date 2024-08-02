extends Resource
class_name PlatformerConfig

@export_group("Input Settings")
@export var move_left_button: String = "move_left"
@export var move_right_button: String = "move_right"
@export var move_up_button: String = "move_up"
@export var move_down_button: String = "move_down"
@export var jump_button: String = "jump"
@export var dash_button: String = "dash"
@export var climb_button: String = "climb"

@export_group("Movement Settings")
@export_range(100, 1000, 50, "or_less", "or_greater") var speed: float = 450.0
@export_range(100, 3000, 50, "or_less", "or_greater") var acceleration: float = 1000.0
@export_range(100, 3000, 50, "or_less", "or_greater") var deacceleration: float = 900.0

@export_group("Jump Settings")
@export var allow_double_jump: bool = false
@export var jump_cut_off_factor: float = 0.5
@export_range(100, 1000, 50, "or_less", "or_greater") var jump_velocity: float = 450.0
@export_range(1, 10, 1, "or_less", "or_greater") var max_jumps: int = 2

@export_group("Wall Jump Settings")
@export var allow_wall_jumping: bool = false
@export_range(100, 1000, 50, "or_less", "or_greater") var wall_jump_velocity: float = 450.0
@export_range(10, 1000, 50, "or_less", "or_greater") var wall_jump_horizontal_boost: float = 300.0
@export_range(0.1, 2, 0.1, "or_less", "or_greater") var wall_jump_cooldown: float = 2

@export_group("Dash Settings")
@export var allow_dashing: bool = false
@export_range(100, 1000, 50, "or_less", "or_greater") var dash_speed: float = 600.0
@export_range(0.1, 1, 0.1, "or_less", "or_greater") var dash_duration: float = 0.2
@export_range(0.1, 2, 0.1, "or_less", "or_greater") var dash_cooldown: float = 0.5

@export_group("Climb Settings")
@export var allow_wall_climbing: bool = false
@export var allow_ceiling_climbing: bool = false
@export_range(100, 1000, 50, "or_less", "or_greater") var climb_speed: float = 200.0
@export_range(0.1, 5, 0.1, "or_less", "or_greater") var max_climb_duration: float = 2.0
@export_range(0.1, 5, 0.1, "or_less", "or_greater") var climb_cooldown: float = 1.0

@export_group("Wall Sliding")
@export var enable_wall_sliding: bool = false
@export_range(1.0, 100.0, 0.5, "or_less", "or_greater") var wall_slide_speed: float = 225

@export_group("Forgiveness")
@export_range(0.1, 1, 0.1, "or_less", "or_greater") var peak_gravity_multiplier: float = 0.8
@export_range(0.1, 1, 0.1, "or_less", "or_greater") var corner_correction_threshold: float = 0.1
@export_range(0.1, 1, 0.1, "or_less", "or_greater") var coyote_time: float = 0.5
@export_range(0.001, 2, 0.001, "or_greater") var input_buffer_time: float = 0.2

@export_group("Node Config")
@export_range(1, 100, 1, "or_greater") var default_ray_length: int = 32
