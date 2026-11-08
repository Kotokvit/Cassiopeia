extends Node

## Fundamental 10 Runes Management System
## Handles reality alterations: material density reduction, quantum tunneling,
## local gravitational constant manipulation.

signal rune_activated(rune_name: String, target: Node)

const FUNDAMENTAL_RUNES: Array[String] = [
	"Tet", "Oro", "Vex", "Sol", "Kael",
	"Axiom", "Nir", "Val", "Zeph", "Chron"
]

func _ready() -> void:
	print("[RuneSystem] Initialized with 10 Fundamental Runes.")

## Cast a rune effect onto a target or environment
func cast_rune(rune_name: String, target: Node = null) -> bool:
	if not rune_name in FUNDAMENTAL_RUNES:
		push_warning("Unknown rune: " + rune_name)
		return false
	
	# ATF Cost check
	if not ATFSystem.consume_atf(20.0, 5.0, 10.0):
		print("[RuneSystem] Failed to cast %s: Insufficient ATP!" % rune_name)
		return false
	
	match rune_name:
		"Tet":
			_apply_density_reduction(target)
		"Oro":
			_apply_quantum_tunnel()
		"Vex":
			_alter_local_gravity(0.5) # Temporarily lower local g constant
		_:
			print("[RuneSystem] Cast default rune: ", rune_name)
	
	rune_activated.emit(rune_name, target)
	return true

func _apply_density_reduction(target: Node) -> void:
	if target and target.has_method("set_material_density"):
		target.call("set_material_density", 0.1) # Wolfram -> Aerogel density shift
		print("[RuneSystem] Material density lowered: Wolfram -> Aerogel!")

func _apply_quantum_tunnel() -> void:
	print("[RuneSystem] Quantum Tunnel created.")

func _alter_local_gravity(scale_factor: float) -> void:
	var modified_g: float = GravitySystem.BASE_GRAVITY * scale_factor
	GravitySystem.set_local_gravity(modified_g)
	print("[RuneSystem] Local Gravity Constant modified to: %.2f m/s^2" % modified_g)
