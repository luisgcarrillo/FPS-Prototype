extends CanvasLayer

@onready var current_weapon = $VBoxContainer/HBoxContainer/CurrentWeapon
@onready var current_ammo_count = $VBoxContainer/HBoxContainer2/CurrentAmmoCount
@onready var weapon_inventory = $VBoxContainer/HBoxContainer3/WeaponInventory

func _ready():
	current_weapon.text = ""
	current_ammo_count.text = ""
	weapon_inventory.text = ""


func _on_weapons_manager_update_ammo(Ammo):
	current_ammo_count.set_text(str(Ammo[0] + " / " + str(Ammo[1])))


func _on_weapons_manager_update_weapon_inventory(WeaponInventory):
	weapon_inventory = ""
	for i in WeaponInventory:
		weapon_inventory  += "\n" + i


func _on_weapons_manager_weapon_changed(WeaponName):
	current_weapon.text = WeaponName
