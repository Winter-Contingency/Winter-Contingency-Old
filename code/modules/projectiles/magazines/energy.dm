//Energy weapons

/obj/item/cell/lasgun
	name = "\improper lasgun Battery"
	desc = "A specialized high density battery used to power lasguns."
	icon = 'icons/obj/items/ammo.dmi'
	icon_state = "m43"
	maxcharge = 1000
	w_class = WEIGHT_CLASS_NORMAL
	var/base_ammo_icon = "m43"
	var/gun_type = /obj/item/weapon/gun/energy/lasgun
	var/reload_delay = 0

/obj/item/cell/lasgun/M43
	name = "\improper M43 lasgun battery"
	desc = "A specialized high density battery used to power the M43 lasgun."
	base_ammo_icon = "m43"
	icon_state = "m43"
	gun_type = /obj/item/weapon/gun/energy/lasgun/M43

/obj/item/cell/lasgun/M43/highcap// Large battery
	name = "\improper M43 highcap lasgun battery"
	desc = "An advanced, ultrahigh capacity battery used to power the M43 lasgun; has sixty percent more charge capacity than standard laspacks."
	base_ammo_icon = "m43_e"
	icon_state = "m43_e"
	maxcharge = 1600

/obj/item/cell/lasgun/M43/Initialize()
	. = ..()
	update_icon()

/obj/item/cell/lasgun/M43/update_icon()
	var/remaining = CEILING((charge / max(maxcharge, 1)) * 100, 25)
	icon_state = "[base_ammo_icon]_[remaining]"

/obj/item/cell/lasgun/pulse
	name = "\improper M19C4 pulse battery"
	desc = "An advanced, ultrahigh capacity battery used to power the M19C4 pulse rifle system; Uses pulse-based energy rather than laser energy, massively increasing its firepower. It can also recharge on its own."
	base_ammo_icon = "pulse"
	icon_state = "pulse"
	gun_type = /obj/item/weapon/gun/energy/lasgun/pulse
	maxcharge = 2000 // 100 shots.
	self_recharge = TRUE
	charge_amount = 25 // 10%, 1 shot
	charge_delay = 2 SECONDS

/obj/item/cell/lasgun/pulse/Initialize()
	. = ..()
	update_icon()

/obj/item/cell/lasgun/pulse/update_icon()
	var/remaining = CEILING((charge / max(maxcharge, 1)) * 100, 25)
	icon_state = "[base_ammo_icon]_[remaining]"

/obj/item/cell/lasgun/M43/practice
	name = "\improper M43-P lasgun battery"
	desc = "A specialized high density battery used to power the M43-P practice lasgun. It lacks any potential to harm someone, but it has the ability to recharge."
	gun_type = /obj/item/weapon/gun/energy/lasgun/M43/practice
	self_recharge = TRUE
	charge_amount = 25 // 10%, 2 shots
	charge_delay = 2 SECONDS

/obj/item/cell/lasgun/update_icon()
	return FALSE

/obj/item/cell/lasgun/lasrifle
	name = "\improper TX-73 lasrifle battery"
	desc = "A specialized high density battery used to power the TX-73 lasrifle."
	base_ammo_icon = "tx73"
	icon_state = "tx73"
	gun_type = /obj/item/weapon/gun/energy/lasgun/lasrifle

/obj/item/cell/lasgun/lasrifle/highcap// Large battery
	name = "\improper TX-73 highcap lasrifle battery"
	desc = "An advanced, ultrahigh capacity battery used to power the TX-73 lasrifle; has sixty percent more charge capacity than standard laspacks."
	base_ammo_icon = "tx73_e"
	icon_state = "tx73_e"
	maxcharge = 1600

/obj/item/cell/lasgun/lasrifle/Initialize()
	. = ..()
	update_icon()

/obj/item/cell/lasgun/lasrifle/update_icon()
	var/remaining = CEILING((charge / max(maxcharge, 1)) * 100, 25)
	icon_state = "[base_ammo_icon]_[remaining]"

/obj/item/cell/lasgun/plasma
	name = "plasma cell"
	desc = "A specialized and universal high density plasma cell used in many covenant weapons."
	icon = 'icons/obj/items/ammo.dmi'
	icon_state = "plasmacell"
	gun_type = /obj/item/weapon/gun/energy/lasgun/plasma
	maxcharge = 1000

/obj/item/cell/lasgun/plasma/large
	name = "large plasma cell"
	desc = "A specialized and universal high density plasma cell used in many covenant weapons."
	icon = 'icons/obj/items/ammo.dmi'
	icon_state = "plasmacell"
	gun_type = /obj/item/weapon/gun/energy/lasgun/plasma/repeater
	maxcharge = 3500

/obj/item/cell/lasgun/needles
	name = "blamite cartridge"
	desc = "A specialized high density blamite cartridge used for ammunition in needler weapons."
	icon = 'icons/obj/items/ammo.dmi'
	icon_state = "needles"
	gun_type = /obj/item/weapon/gun/energy/lasgun/needler
	maxcharge = 350
