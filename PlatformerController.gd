class_name PlatformerController
extends Node

@export var config: PlatformerConfig = PlatformerConfig.new()

@export_group("Nodes")

@export var target: CharacterBody2D:
    get:
        if target == null:
            target = self.get_parent()
        return target

@export var right_ray: RayCast2D:
    get:
        if right_ray == null:
            right_ray = create_ray(Vector2(config.default_ray_length, 0))
        return right_ray

@export var left_ray: RayCast2D:
    get:
        if left_ray == null:
            left_ray = create_ray(Vector2(-config.default_ray_length, 0))
        return left_ray

@export var top_ray: RayCast2D:
    get:
        if top_ray == null:
            top_ray = create_ray(Vector2(0, -config.default_ray_length))
        return top_ray

@export var bottom_ray: RayCast2D:
    get:
        if bottom_ray == null:
            bottom_ray = create_ray(Vector2(0, config.default_ray_length))
        return bottom_ray

signal started_dash(motion: Motion)
signal finished_dash(motion: Motion)
signal began_climbing_wall(motion: Motion)
signal stopped_climbing_wall(motion: Motion)
signal began_climbing_ceiling(motion: Motion)
signal stopped_climbing_ceiling(motion: Motion)
signal began_wall_slide(motion: Motion)
signal stopped_wall_slide(motion: Motion)
signal jumped(motion: Motion)
signal wall_jumped(motion: Motion)
signal started_moving(motion: Motion)
signal stopped_moving(motion: Motion)
signal reset()

enum MotionType { IDLE, MOVING, JUMPING, WALL_JUMPING, DASHING, WALL_SLIDING, CLIMBING_WALL, CLIMBING_CEILING }

class Motion:
    var type: MotionType
    var direction: int
    var speed: float
    var additional_info: Dictionary

    func _init(type: MotionType, direction: int, speed: float, additional_info: Dictionary = {}):
        self.type = type
        self.direction = direction
        self.speed = speed
        self.additional_info = additional_info

var coyote_timer: float = 0.0
var jump_count: int = 0
var is_dashing: bool = false
var dash_timer: float = 0.0
var last_direction: int = 1
var is_touching_wall: bool = false
var wall_jump_direction: int = 0
var is_touching_ceiling: bool = false

var left_wall_jump_timer: float = 0.0
var right_wall_jump_timer: float = 0.0

var climb_timer: float = 0.0
var climb_cooldown_timer: float = 0.0
var is_at_jump_peak: bool = false

var jump_buffer_timer: float = 0.0
var dash_buffer_timer: float = 0.0

var was_climbing_wall: bool = false
var was_climbing_ceiling: bool = false
var was_wall_sliding: bool = false
var was_moving: bool = false

# Variable to store the climbed object
var climbed_object: Node = null
var last_climbed_object_position: Vector2 = Vector2.ZERO

func create_ray(position: Vector2) -> RayCast2D:
    var ray = RayCast2D.new()
    ray.target_position = position
    target.add_child(ray)
    return ray

func handle_gravity(delta: float) -> void:
    var gravity: Vector2 = target.get_gravity()
    if not target.is_on_floor() and not is_dashing and not is_wall_sliding():
        if target.velocity.y > 0:  # Peak of jump
            target.velocity += gravity * delta * config.peak_gravity_multiplier
            is_at_jump_peak = true
        else:
            target.velocity += gravity * delta
            is_at_jump_peak = false
        coyote_timer -= delta
    else:
        coyote_timer = config.coyote_time
        jump_count = 0

    left_wall_jump_timer -= delta
    right_wall_jump_timer -= delta
    climb_cooldown_timer -= delta

func handle_jump(delta: float) -> void:
    if is_dashing:
        return

    if Input.is_action_just_pressed(config.jump_button):
        jump_buffer_timer = config.input_buffer_time

    jump_buffer_timer -= delta

    if jump_buffer_timer > 0:
        if config.allow_wall_jumping and (is_touching_wall or (config.allow_ceiling_climbing and is_touching_ceiling)) and not target.is_on_floor():
            var direction := Input.get_axis(config.move_left_button, config.move_right_button)
            if wall_jump_direction == 1 and direction > 0 and left_wall_jump_timer <= 0:
                execute_wall_jump(1)
                jump_buffer_timer = 0
                return
            elif wall_jump_direction == -1 and direction < 0 and right_wall_jump_timer <= 0:
                execute_wall_jump(-1)
                jump_buffer_timer = 0
                return
        elif target.is_on_floor() or coyote_timer > 0 or (config.allow_double_jump and jump_count < config.max_jumps):
            execute_jump()
            jump_buffer_timer = 0
        elif (is_touching_wall or (config.allow_ceiling_climbing and is_touching_ceiling)) and config.allow_wall_climbing and climb_timer > 0 and climb_cooldown_timer <= 0:
            execute_jump()
            climb_timer = 0.0
            climb_cooldown_timer = config.climb_cooldown
            jump_buffer_timer = 0

    if Input.is_action_just_released(config.jump_button):
        if target.velocity.y < 0:
            target.velocity.y *= config.jump_cut_off_factor

func execute_jump() -> void:
    target.velocity.y = -config.jump_velocity
    coyote_timer = 0.0
    jump_count += 1
    emit_signal("jumped", Motion.new(MotionType.JUMPING, last_direction, target.velocity.length()))

func execute_wall_jump(direction: int) -> void:
    target.velocity.y = -config.wall_jump_velocity
    target.velocity.x = direction * config.wall_jump_horizontal_boost
    if direction == 1:
        left_wall_jump_timer = config.wall_jump_cooldown
        right_wall_jump_timer = 0
    else:
        right_wall_jump_timer = config.wall_jump_cooldown
        left_wall_jump_timer = 0
    emit_signal("wall_jumped", Motion.new(MotionType.WALL_JUMPING, direction, target.velocity.length()))

func handle_move(delta: float) -> void:
    if is_dashing:
        return
    var direction := Input.get_axis(config.move_left_button, config.move_right_button)
    var is_currently_moving = direction != 0
    if is_currently_moving:
        target.velocity.x += direction * config.acceleration * delta
        target.velocity.x = clamp(target.velocity.x, -config.speed, config.speed)
        last_direction = direction
    else:
        target.velocity.x = approach(target.velocity.x, 0, config.deacceleration * delta)

    if is_currently_moving and not was_moving:
        emit_signal("started_moving", Motion.new(MotionType.MOVING, direction, target.velocity.length()))
    elif not is_currently_moving and was_moving:
        emit_signal("stopped_moving", Motion.new(MotionType.IDLE, last_direction, target.velocity.length()))
    was_moving = is_currently_moving

func approach(value: float, target: float, delta: float) -> float:
    if value < target:
        return min(value + delta, target)
    else:
        return max(value - delta, target)

func handle_wall_climb(delta: float) -> void:
    var is_currently_climbing_wall = false
    var is_currently_climbing_ceiling = false
    if config.allow_wall_climbing and (is_touching_wall or (config.allow_ceiling_climbing and is_touching_ceiling)) and Input.is_action_pressed(config.climb_button) and climb_cooldown_timer <= 0:
        if is_touching_wall:
            is_currently_climbing_wall = true
        elif is_touching_ceiling:
            is_currently_climbing_ceiling = true

        if climb_timer > 0:
            var climb_direction := Input.get_axis(config.move_up_button, config.move_down_button)
            if climb_direction != 0:
                target.velocity.y = climb_direction * config.climb_speed
            else:
                target.velocity.y = 0
            climb_timer -= delta
        else:
            target.velocity += target.get_gravity() * delta
    elif target.is_on_floor() or not is_touching_wall:
        climb_timer = config.max_climb_duration

    if is_currently_climbing_wall and not was_climbing_wall:
        emit_signal("began_climbing_wall", Motion.new(MotionType.CLIMBING_WALL, last_direction, target.velocity.length()))
        set_climbed_object(left_ray.get_collider() if left_ray.is_colliding() else right_ray.get_collider())
    elif not is_currently_climbing_wall and was_climbing_wall:
        emit_signal("stopped_climbing_wall", Motion.new(MotionType.IDLE, last_direction, target.velocity.length()))
        set_climbed_object(null)
    was_climbing_wall = is_currently_climbing_wall

    if is_currently_climbing_ceiling and not was_climbing_ceiling:
        emit_signal("began_climbing_ceiling", Motion.new(MotionType.CLIMBING_CEILING, last_direction, target.velocity.length()))
        set_climbed_object(top_ray.get_collider())
    elif not is_currently_climbing_ceiling and was_climbing_ceiling:
        emit_signal("stopped_climbing_ceiling", Motion.new(MotionType.IDLE, last_direction, target.velocity.length()))
        set_climbed_object(null)
    was_climbing_ceiling = is_currently_climbing_ceiling

func set_climbed_object(obj: Node) -> void:
    climbed_object = obj
    if climbed_object:
        last_climbed_object_position = climbed_object.global_position

func handle_climbed_object_movement() -> void:
    if climbed_object and climbed_object is PhysicsBody2D:
        var current_position = climbed_object.global_position
        var movement = current_position - last_climbed_object_position
        target.global_position += movement
        last_climbed_object_position = current_position

func handle_dash(delta: float) -> void:
    var direction := Input.get_axis(config.move_left_button, config.move_right_button)
    if Input.is_action_just_pressed(config.dash_button):
        dash_buffer_timer = config.input_buffer_time

    dash_buffer_timer -= delta

    if dash_buffer_timer > 0:
        if not is_dashing and dash_timer <= 0 and direction != 0:
            is_dashing = true
            dash_timer = config.dash_duration
            last_direction = sign(direction)
            dash_buffer_timer = 0
            emit_signal("started_dash", Motion.new(MotionType.DASHING, last_direction, config.dash_speed))

    if is_dashing:
        target.velocity.x = last_direction * config.dash_speed
        dash_timer -= delta
        if dash_timer <= 0:
            is_dashing = false
            emit_signal("finished_dash", Motion.new(MotionType.IDLE, last_direction, target.velocity.length()))

func handle_wall_slide(delta: float) -> void:
    var is_currently_wall_sliding = false
    if config.enable_wall_sliding and is_touching_wall and target.velocity.y > 0 and not Input.is_action_pressed(config.climb_button):
        target.velocity.y = config.wall_slide_speed
        is_currently_wall_sliding = true

    if is_currently_wall_sliding and not was_wall_sliding:
        emit_signal("began_wall_slide", Motion.new(MotionType.WALL_SLIDING, last_direction, target.velocity.length()))
    elif not is_currently_wall_sliding and was_wall_sliding:
        emit_signal("stopped_wall_slide", Motion.new(MotionType.IDLE, last_direction, target.velocity.length()))
    was_wall_sliding = is_currently_wall_sliding

func check_wall_collision() -> void:
    left_ray.force_raycast_update()
    right_ray.force_raycast_update()
    top_ray.force_raycast_update()
    bottom_ray.force_raycast_update()

    is_touching_wall = false
    wall_jump_direction = 0
    is_touching_ceiling = false

    if left_ray.is_colliding():
        is_touching_wall = true
        wall_jump_direction = 1
    elif right_ray.is_colliding():
        is_touching_wall = true
        wall_jump_direction = -1
    elif config.allow_ceiling_climbing and top_ray.is_colliding():
        is_touching_ceiling = true

func handle_corner_correction() -> void:
    if is_dashing and (is_touching_wall or (config.allow_ceiling_climbing and is_touching_ceiling)):
        if right_ray.is_colliding() and not bottom_ray.is_colliding() and fmod(target.position.y, 1.0) < config.corner_correction_threshold:
            target.position.y = round(target.position.y)
        elif left_ray.is_colliding() and not bottom_ray.is_colliding() and fmod(target.position.y, 1.0) < config.corner_correction_threshold:
            target.position.y = round(target.position.y)

    if target.velocity.y < 0 and top_ray.is_colliding() and not bottom_ray.is_colliding() and fmod(target.position.y, 1.0) < config.corner_correction_threshold:
        target.position.y = round(target.position.y)

func is_wall_sliding() -> bool:
    return config.enable_wall_sliding and is_touching_wall and target.velocity.y > 0 and not Input.is_action_pressed(config.climb_button)

func _physics_process(delta: float) -> void:
    check_wall_collision()
    handle_gravity(delta)
    handle_jump(delta)
    handle_move(delta)
    handle_wall_climb(delta)
    handle_wall_slide(delta)
    handle_dash(delta)
    handle_corner_correction()
    handle_climbed_object_movement()
    target.move_and_slide()

func _ready() -> void:
    connect("reset", _on_reset)

func _on_reset() -> void:
    coyote_timer = 0.0
    jump_count = 0
    is_dashing = false
    dash_timer = 0.0
    is_touching_wall = false
    wall_jump_direction = 0
    is_touching_ceiling = false
    left_wall_jump_timer = 0.0
    right_wall_jump_timer = 0.0
    climb_timer = 0.0
    climb_cooldown_timer = 0.0
    is_at_jump_peak = false
    jump_buffer_timer = 0.0
    dash_buffer_timer = 0.0
    was_climbing_wall = false
    was_climbing_ceiling = false
    was_wall_sliding = false
    was_moving = false
    set_climbed_object(null)
