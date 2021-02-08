extends RigidBody

var runner: BoardRunner = null
var _disabled: bool = false

onready var _wheels: Array = [$RightFront, $LeftFront, $RightBack, $LeftBack]
onready var _cosmetic_wheels: Array = [$RightFront/wheel, $LeftFront/wheel, $RightBack/wheel, $LeftBack/wheel]

onready var _rightw: Array = [$RightFront, $RightBack]
onready var _leftw: Array = [$LeftFront, $LeftBack]

var lmotor: BrushedMotor = null
var rmotor: BrushedMotor = null

func set_runner(runner: BoardRunner):
	if ! runner:
		return
	runner.connect("status_changed", self, "_on_board_status_changed")
	
	lmotor = BrushedMotor.new()
	lmotor.set_boardview(runner.view())
	lmotor.set_pins(2,3,4)
	
	rmotor = BrushedMotor.new()
	rmotor.set_boardview(runner.view())
	rmotor.set_pins(5,6,7)
	
	$Attachments/RayCast.set_boardview(runner.view())

func _process(delta):
	$Attachments/SpotLight.light_color.h += delta * 0.1

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	for i in range(_wheels.size()):
		_wheels[i].add_force(state)
		if _wheels[i].is_colliding():
			_cosmetic_wheels[i].global_transform.origin = _wheels[i].get_collision_point()

	var key_direction: int = int(Input.is_action_pressed("ui_up")) - int(Input.is_action_pressed("ui_down"))
	
	for wheel in _rightw:
		if lmotor:
			wheel.throttle = lmotor.get_speed()
		else:
			wheel.throttle = key_direction * int(!Input.is_action_pressed("ui_right"))
	
	for wheel in _leftw:
		if rmotor:
			wheel.throttle = rmotor.get_speed()
		else:
			wheel.throttle = key_direction * int(!Input.is_action_pressed("ui_left"))


func _on_board_status_changed(status) -> void:
	if status == SMCE.Status.STOPPED:
		queue_free()  # just die