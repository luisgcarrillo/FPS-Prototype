extends Resource

class_name WeaponsResource

@export var WeaponName: String
@export var AltFireName: String

@export_category("Animation")
@export var ActivateAnimation: String
@export var DeactivateAnimation: String
@export var ShootAnimation: String
@export var StartingShootAnimation: String
@export var ReloadAnimation: String
@export var OutOfAmmoAnimation: String
@export var AltFireAnimation: String

@export_category("Ammo")
@export var CurrentAmmo : int
@export var ReserveAmmo : int
@export var StartingAmmo : int
@export var StartingReserveAmmo : int
@export var CurrentAltFireAmmo : int
@export var MaxAltFireAmmo: int
@export var StartingAltFireAmmo: int
@export var MagazineSize : int
@export var MaxAmmoAmount : int
@export var AmmoRefillAmount: int
@export var AltRefillAmount: int

@export_category("Variables")
@export var Autofire : bool
@export_flags("Hitscan", "Projectile") var Type
@export var WeaponRange: int
@export var Damage: int
@export var AltFireDamage: int
@export var KnockbackStrength: float
