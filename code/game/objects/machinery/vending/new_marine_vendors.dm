#define MARINE_CAN_BUY_UNIFORM 		(1 << 0)
#define MARINE_CAN_BUY_SHOES	 	(1 << 1)
#define MARINE_CAN_BUY_HELMET 		(1 << 2)
#define MARINE_CAN_BUY_ARMOR	 	(1 << 3)
#define MARINE_CAN_BUY_GLOVES 		(1 << 4)
#define MARINE_CAN_BUY_EAR	 		(1 << 5)
#define MARINE_CAN_BUY_BACKPACK 	(1 << 6)
#define MARINE_CAN_BUY_R_POUCH 		(1 << 7)
#define MARINE_CAN_BUY_L_POUCH 		(1 << 8)
#define MARINE_CAN_BUY_BELT 		(1 << 9)
#define MARINE_CAN_BUY_GLASSES		(1 << 10)
#define MARINE_CAN_BUY_MASK			(1 << 11)
#define MARINE_CAN_BUY_ESSENTIALS	(1 << 12)
#define MARINE_CAN_BUY_ATTACHMENT	(1 << 13)
#define MARINE_CAN_BUY_ATTACHMENT2	(1 << 14)

#define MARINE_CAN_BUY_WEBBING		(1 << 15)



#define MARINE_CAN_BUY_ALL			((1 << 16) - 1)

#define MARINE_TOTAL_BUY_POINTS		45

#define CAT_ESS "ESSENTIALS"
#define CAT_STD "STANDARD EQUIPMENT"
#define CAT_SHO "SHOES"
#define CAT_HEL "HATS"
#define CAT_AMR "ARMOR"
#define CAT_GLO "GLOVES"
#define CAT_EAR "EAR"
#define CAT_BAK "BACKPACK"
#define CAT_POU "POUCHES"
#define CAT_WEB "WEBBING"
#define CAT_BEL "BELT"
#define CAT_MAS "MASKS"
#define CAT_ATT "GUN ATTACHMENTS"
#define CAT_EXP "EXPLOSIVES"

#define CAT_MEDSUP "MEDICAL SUPPLIES"
#define CAT_ENGSUP "ENGINEERING SUPPLIES"
#define CAT_LEDSUP "LEADER SUPPLIES"
#define CAT_SPEAMM "SPECIAL AMMUNITION"

/obj/item/card/id/var/marine_points = MARINE_TOTAL_BUY_POINTS
/obj/item/card/id/var/marine_buy_flags = MARINE_CAN_BUY_ALL

GLOBAL_LIST_INIT(marine_selector_cats, list(
		CAT_STD = list(MARINE_CAN_BUY_UNIFORM),
		CAT_SHO = list(MARINE_CAN_BUY_SHOES),
		CAT_HEL = list(MARINE_CAN_BUY_HELMET),
		CAT_AMR = list(MARINE_CAN_BUY_ARMOR),
		CAT_GLO = list(MARINE_CAN_BUY_GLOVES),
		CAT_EAR = list(MARINE_CAN_BUY_EAR),
		CAT_BAK = list(MARINE_CAN_BUY_BACKPACK),
		CAT_WEB = list(MARINE_CAN_BUY_WEBBING),
		CAT_POU = list(MARINE_CAN_BUY_R_POUCH,MARINE_CAN_BUY_L_POUCH),
		CAT_BEL = list(MARINE_CAN_BUY_BELT),
		CAT_GLA = list(MARINE_CAN_BUY_GLASSES),
		CAT_MAS = list(MARINE_CAN_BUY_MASK),
		CAT_ATT = list(MARINE_CAN_BUY_ATTACHMENT,MARINE_CAN_BUY_ATTACHMENT2),
		CAT_ESS = list(MARINE_CAN_BUY_ESSENTIALS),
		CAT_MEDSUP = null,
		CAT_ENGSUP = null,
		CAT_LEDSUP = null,
		CAT_SPEAMM = null,
		CAT_EXP = null,
	))

/obj/machinery/marine_selector
	name = "\improper Theoretical Marine selector"
	desc = ""
	icon = 'icons/obj/machines/vending.dmi'
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	req_access = null
	req_one_access = null
	interaction_flags = INTERACT_MACHINE_TGUI

	idle_power_usage = 60
	active_power_usage = 3000

	var/gives_webbing = FALSE
	var/vendor_role //to be compared with job.type to only allow those to use that machine.
	var/squad_tag = ""
	var/use_points = FALSE
	var/lock_flags = SQUAD_LOCK|JOB_LOCK

	var/icon_vend
	var/icon_deny

	var/list/categories
	var/list/listed_products

	ui_x = 600
	ui_y = 700

/obj/machinery/marine_selector/update_icon()
	if(is_operational())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"



/obj/machinery/marine_selector/can_interact(mob/user)
	. = ..()
	if(!.)
		return FALSE

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!allowed(H))
			return FALSE

		var/obj/item/card/id/I = H.get_idcard()
		if(!istype(I)) //not wearing an ID
			return FALSE

		if(I.registered_name != H.real_name)
			return FALSE

		if(lock_flags & JOB_LOCK && vendor_role && !istype(H.job, vendor_role))
			return FALSE

		if(lock_flags & SQUAD_LOCK && (!H.assigned_squad || (squad_tag && H.assigned_squad.name != squad_tag)))
			return FALSE

	return TRUE

/obj/machinery/marine_selector/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
										datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)

	if(!ui)
		ui = new(user, src, ui_key, "MarineSelector", name, ui_x, ui_y, master_ui, state)
		ui.open()

/obj/machinery/marine_selector/ui_static_data(mob/user)
	. = list()
	.["displayed_records"] = list()
	for(var/c in categories)
		.["displayed_records"][c] = list()

	.["vendor_name"] = name
	.["show_points"] = use_points
	.["total_marine_points"] = MARINE_TOTAL_BUY_POINTS

	for(var/i in listed_products)
		var/list/myprod = listed_products[i]
		var/category = myprod[1]
		var/p_name = myprod[2]
		var/p_cost = myprod[3]
		var/atom/productpath = i

		LAZYADD(.["displayed_records"][category], list(list("prod_index" = i, "prod_name" = p_name, "prod_color" = myprod[4], "prod_cost" = p_cost, "prod_desc" = initial(productpath.desc))))

/obj/machinery/marine_selector/ui_data(mob/user)
	. = list()

	var/obj/item/card/id/I = user.get_idcard()
	.["current_m_points"] = I?.marine_points || 0
	var/buy_flags = I?.marine_buy_flags || NONE


	.["cats"] = list()
	for(var/i in GLOB.marine_selector_cats)
		.["cats"][i] = list("remaining" = 0, "total" = 0)
		for(var/flag in GLOB.marine_selector_cats[i])
			.["cats"][i]["total"]++
			if(buy_flags & flag)
				.["cats"][i]["remaining"]++

/obj/machinery/marine_selector/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("vend")
			if(!allowed(usr))
				to_chat(usr, "<span class='warning'>Access denied.</span>")
				if(icon_deny)
					flick(icon_deny, src)
				return

			var/idx = text2path(params["vend"])
			var/obj/item/card/id/I = usr.get_idcard()

			var/list/L = listed_products[idx]
			var/cost = L[3]

			if(use_points && I.marine_points < cost)
				to_chat(usr, "<span class='warning'>Not enough points.</span>")
				if(icon_deny)
					flick(icon_deny, src)
				return

			var/turf/T = loc
			if(length(T.contents) > 25)
				to_chat(usr, "<span class='warning'>The floor is too cluttered, make some space.</span>")
				if(icon_deny)
					flick(icon_deny, src)
				return
			var/bitf = NONE
			var/list/C = GLOB.marine_selector_cats[L[1]]
			for(var/i in C)
				bitf |= i
			if(bitf)
				if(bitf == MARINE_CAN_BUY_ESSENTIALS && vendor_role == /datum/job/terragov/squad/specialist)
					if(!isliving(usr))
						return
					var/mob/living/user = usr
					if(!ismarinespecjob(user.job))
						to_chat(usr, "<span class='warning'>Only specialists can take specialist sets.</span>")
						return
					if(usr.skills.getRating("spec_weapons") != SKILL_SPEC_TRAINED)
						to_chat(usr, "<span class='warning'>You already have a specialist specialization.</span>")
						return
					var/p_name = L[2]
					if(findtext(p_name, "Scout Set")) //Makes sure there can only be one Scout kit taken despite the two variants.
						p_name = "Scout Set"
					else if(findtext(p_name, "Heavy Armor Set")) //Makes sure there can only be one Heavy kit taken despite the two variants.
						p_name = "Heavy Armor Set"
					if(!GLOB.available_specialist_sets.Find(p_name))
						to_chat(usr, "<span class='warning'>That set is already taken</span>")
						return

				if(I.marine_buy_flags & bitf)
					if(bitf == (MARINE_CAN_BUY_R_POUCH|MARINE_CAN_BUY_L_POUCH))
						if(I.marine_buy_flags & MARINE_CAN_BUY_R_POUCH)
							I.marine_buy_flags &= ~MARINE_CAN_BUY_R_POUCH
						else
							I.marine_buy_flags &= ~MARINE_CAN_BUY_L_POUCH
					else if(bitf == (MARINE_CAN_BUY_ATTACHMENT|MARINE_CAN_BUY_ATTACHMENT2))
						if(I.marine_buy_flags & MARINE_CAN_BUY_ATTACHMENT)
							I.marine_buy_flags &= ~MARINE_CAN_BUY_ATTACHMENT
						else
							I.marine_buy_flags &= ~MARINE_CAN_BUY_ATTACHMENT2
					else
						I.marine_buy_flags &= ~bitf
				else
					to_chat(usr, "<span class='warning'>You can't buy things from this category anymore.</span>")
					return

			var/obj/item/vended_item = new idx(loc)

			if(istype(vended_item)) // in case of spawning /obj
				usr.put_in_any_hand_if_possible(vended_item, warning = FALSE)

			if(icon_vend)
				flick(icon_vend, src)

			use_power(active_power_usage)

			if(bitf == MARINE_CAN_BUY_UNIFORM && ishumanbasic(usr))
				var/mob/living/carbon/human/H = usr
				new /obj/item/radio/headset/mainship/marine(loc, H.assigned_squad, vendor_role)
				if(!istype(H.job, /datum/job/terragov/squad/engineer))
					new /obj/item/clothing/gloves/marine(loc, H.assigned_squad, vendor_role)
				if(istype(H.job, /datum/job/terragov/squad/leader))
					new /obj/item/hud_tablet(loc, vendor_role, H.assigned_squad)
				if(SSmapping.configs[GROUND_MAP].environment_traits[MAP_COLD])
					new /obj/item/clothing/mask/rebreather/scarf(loc)

			if(bitf == MARINE_CAN_BUY_ESSENTIALS && vendor_role == /datum/job/terragov/squad/specialist && ishuman(usr))
				var/mob/living/carbon/human/H = usr
				if(ismarinespecjob(H.job))
					var/p_name = L[2]
					if(findtext(p_name, "Scout Set")) //Makes sure there can only be one Scout kit taken despite the two variants.
						p_name = "Scout Set"
					else if(findtext(p_name, "Heavy Armor Set")) //Makes sure there can only be one Heavy kit taken despite the two variants.
						p_name = "Heavy Armor Set"
					if(p_name)
						H.specset = p_name
					H.update_action_buttons()
					GLOB.available_specialist_sets -= p_name

			if(use_points)
				I.marine_points -= cost
			. = TRUE

	updateUsrDialog()

/obj/machinery/marine_selector/clothes
	name = "GHMME Automated Closet"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	vendor_role = /datum/job/terragov/squad/standard
	categories = list(
		CAT_STD = list(MARINE_CAN_BUY_UNIFORM),
		CAT_HEL = list(MARINE_CAN_BUY_HELMET),
		CAT_AMR = list(MARINE_CAN_BUY_ARMOR),
		CAT_BAK = list(MARINE_CAN_BUY_BACKPACK),
		CAT_WEB = list(MARINE_CAN_BUY_WEBBING),
		CAT_BEL = list(MARINE_CAN_BUY_BELT),
		CAT_POU = list(MARINE_CAN_BUY_R_POUCH,MARINE_CAN_BUY_L_POUCH),
		CAT_MAS = list(MARINE_CAN_BUY_MASK),
		CAT_ATT = list(MARINE_CAN_BUY_ATTACHMENT,MARINE_CAN_BUY_ATTACHMENT2),
	)

	listed_products = list(
		/obj/effect/essentials_set/basic = list(CAT_STD, "Standard Kit", 0, "white"),
		/obj/effect/essentials_set/basicmodular = list(CAT_STD, "Essential Jaeger Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "orange"),
		/obj/item/clothing/head/helmet/marine/standard = list(CAT_HEL, "Regular helmet", 0, "orange"),
		/obj/item/clothing/suit/storage/marine/pasvest = list(CAT_AMR, "Regular armor", 0, "orange"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "orange"),
		/obj/item/storage/backpack/marine/standard = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "orange"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical Webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "Utility belt", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "orange"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "orange"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "black"),
		/obj/item/belt_harness/marine = list(CAT_BEL, "Belt harness", 0, "black"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/magazine = list(CAT_POU, "Magazine pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0,"black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0,"black"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0,"black"),
		/obj/item/clothing/mask/bandanna = list(CAT_MAS, "Tan bandanna", 0,"black"),
		/obj/item/clothing/mask/bandanna/green = list(CAT_MAS, "Green bandanna", 0,"black"),
		/obj/item/clothing/mask/bandanna/white = list(CAT_MAS, "White bandanna", 0,"black"),
		/obj/item/clothing/mask/bandanna/black = list(CAT_MAS, "Black bandanna", 0,"black"),
		/obj/item/clothing/mask/bandanna/skull = list(CAT_MAS, "Skull bandanna", 0,"black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0,"black"),
		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0,"black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0,"orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0,"black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0,"orange"),
 		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0,"black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0,"black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0,"black"),
		/obj/item/attachable/scope/mini = list(CAT_ATT, "Mini scope", 0,"black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0,"orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0,"black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0,"black"),
	)







/obj/machinery/marine_selector/clothes/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_DELTA)



/obj/machinery/marine_selector/clothes/engi
	name = "GHMME Automated Engineer Closet"
	req_access = list(ACCESS_MARINE_ENGPREP)
	vendor_role = /datum/job/terragov/squad/engineer
	gives_webbing = FALSE

	listed_products = list(
		/obj/effect/essentials_set/basic_engineer = list(CAT_STD, "Standard kit", 0, "white"),
		/obj/effect/essentials_set/basic_engineermodular = list(CAT_STD, "Essential Jaeger Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "orange"),
		/obj/item/clothing/suit/storage/marine/pasvest = list(CAT_AMR, "Regular armor", 0, "orange"),
		/obj/item/storage/backpack/marine/satchel/tech = list(CAT_BAK, "Satchel", 0, "orange"),
		/obj/item/storage/backpack/marine/tech = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/storage/backpack/marine/engineerpack = list(CAT_BAK, "Welderpack", 0, "black"),
		/obj/item/clothing/tie/storage/brown_vest = list(CAT_WEB, "Tactical brown vest", 0, "orange"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/utility/full = list(CAT_BEL, "Tool belt", 0, "white"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/construction = list(CAT_POU, "Construction pouch", 0, "orange"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tools pouch", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/electronics/full = list(CAT_POU, "Electronics pouch", 0, "black"),
		/obj/item/storage/pouch/magazine = list(CAT_POU, "Magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)

/obj/machinery/marine_selector/clothes/engi/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/engi/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/engi/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/engi/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_ENGPREP, ACCESS_MARINE_DELTA)



/obj/machinery/marine_selector/clothes/medic
	name = "GHMME Automated Corpsman Closet"
	req_access = list(ACCESS_MARINE_MEDPREP)
	vendor_role = /datum/job/terragov/squad/corpsman
	gives_webbing = FALSE

	listed_products = list(
		/obj/effect/essentials_set/basic_medic = list(CAT_STD, "Standard kit", 0, "white"),
		/obj/effect/essentials_set/basic_medicmodular = list(CAT_STD, "Essential Jaeger Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "orange"),
		/obj/item/clothing/suit/storage/marine/pasvest = list(CAT_AMR, "Regular armor", 0, "orange"),
		/obj/item/storage/backpack/marine/satchel/corpsman = list(CAT_BAK, "Satchel", 0, "orange"),
		/obj/item/storage/backpack/marine/corpsman = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/clothing/tie/storage/brown_vest = list(CAT_WEB, "Tactical brown vest", 0, "orange"),
		/obj/item/clothing/tie/storage/white_vest/medic = list(CAT_WEB, "Corpsman white vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/clothing/tie/storage/white_vest = list(CAT_WEB, "Corpsman surgical vest", 0, "black"),
		/obj/item/storage/belt/combatLifesaver = list(CAT_BEL, "Lifesaver belt", 0, "orange"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/pouch/medical = list(CAT_POU, "Medical pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "orange"),
		/obj/item/storage/pouch/autoinjector/full = list(CAT_POU, "Autoinjector pouch", 0, "orange"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/magazine = list(CAT_POU, "Magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)



/obj/machinery/marine_selector/clothes/medic/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/medic/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/medic/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/medic/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_MEDPREP, ACCESS_MARINE_DELTA)







/obj/machinery/marine_selector/clothes/smartgun
	name = "GHMME Automated Smartgunner Closet"
	req_access = list(ACCESS_MARINE_SMARTPREP)
	vendor_role = /datum/job/terragov/squad/smartgunner
	gives_webbing = FALSE

	listed_products = list(
		/obj/effect/essentials_set/basic_smartgunner = list(CAT_STD, "Standard kit", 0, "white"),
		/obj/effect/essentials_set/basic_smartgunnermodular = list(CAT_STD, "Essential Jaeger Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "orange"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "orange"),
		/obj/item/clothing/suit/storage/marine/pasvest = list(CAT_AMR, "Regular armor", 0, "orange"),
		/obj/item/clothing/head/helmet/marine/standard = list(CAT_HEL, "Regular helmet", 0, "orange"),
		/obj/item/clothing/head/helmet/marine/heavy = list(CAT_HEL, "Heavy helmet", 0, "orange"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "orange"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "orange"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "orange"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "orange"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/magazine = list(CAT_POU, "Magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "orange"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)



/obj/machinery/marine_selector/clothes/smartgun/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/smartgun/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/smartgun/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/smartgun/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_SMARTPREP, ACCESS_MARINE_DELTA)



/obj/machinery/marine_selector/clothes/specialist
	name = "GHMME Automated Specialist Closet"
	req_access = list(ACCESS_MARINE_SPECPREP)
	vendor_role = /datum/job/terragov/squad/specialist
	gives_webbing = FALSE


	listed_products = list(
		/obj/effect/essentials_set/basic_specialist = list(CAT_STD, "Standard Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "black"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "black"),
		/obj/item/storage/backpack/marine/standard = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical Black Vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical Webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder Handgun Holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "black"),
		/obj/item/belt_harness/marine = list(CAT_BEL, "Belt Harness", 0, "black"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (Grenades included)", 0,"black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)

/obj/machinery/marine_selector/clothes/specialist/Initialize()
    . = ..()
    new /obj/effect/decal/cleanable/cobweb(loc)
    for(var/d in GLOB.alldirs)
        var/turf/T = get_step(src, d)
        if(!T.density)
            new /obj/effect/decal/cleanable/cobweb(T)


/obj/machinery/marine_selector/clothes/specialist/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_SPECPREP, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/specialist/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_SPECPREP, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/specialist/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_SPECPREP, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/specialist/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_SPECPREP, ACCESS_MARINE_DELTA)



/obj/machinery/marine_selector/clothes/leader
	name = "GHMME Automated Leader Closet"
	req_access = list(ACCESS_MARINE_LEADER)
	vendor_role = /datum/job/terragov/squad/leader
	gives_webbing = FALSE

	listed_products = list(
		/obj/effect/essentials_set/basic_squadleader = list(CAT_STD, "Standard kit (vest included)", 0, "white"),
		/obj/effect/essentials_set/basic_squadleadermodular = list(CAT_STD, "Essential Jaeger Kit", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Medium Infantry Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Light Skirmisher Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Heavy Assault Jaeger kit", 0, "black"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "black"),
		/obj/item/storage/backpack/marine/standard = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "black"),
		/obj/item/belt_harness/marine = list(CAT_BEL, "Belt Harness", 0, "black"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/general/large = list(CAT_POU, "Large general pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
	)



/obj/machinery/marine_selector/clothes/leader/alpha
	squad_tag = "Alpha"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_ALPHA)

/obj/machinery/marine_selector/clothes/leader/bravo
	squad_tag = "Bravo"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_BRAVO)

/obj/machinery/marine_selector/clothes/leader/charlie
	squad_tag = "Charlie"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_CHARLIE)

/obj/machinery/marine_selector/clothes/leader/delta
	squad_tag = "Delta"
	req_access = list(ACCESS_MARINE_LEADER, ACCESS_MARINE_DELTA)

/obj/machinery/marine_selector/clothes/commander
	name = "GHMME Automated Commander Closet"
	req_access = list(ACCESS_MARINE_COMMANDER)
	vendor_role = /datum/job/terragov/command/fieldcommander
	lock_flags = JOB_LOCK
	gives_webbing = FALSE

	listed_products = list(
		/obj/effect/essentials_set/commander = list(CAT_STD, "Standard Commander kit ", 0, "white"),
		/obj/effect/essentials_set/modular/infantry = list(CAT_AMR, "Infantry Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/skirmisher = list(CAT_AMR, "Skirmisher Jaeger kit", 0, "black"),
		/obj/effect/essentials_set/modular/assault = list(CAT_AMR, "Assault Jaeger kit", 0, "black"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "black"),
		/obj/item/storage/backpack/marine/standard = list(CAT_BAK, "Backpack", 0, "black"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/knifepouch = list(CAT_BEL, "Knives belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"),
		/obj/item/storage/belt/gun/revolver/standard_revolver = list(CAT_BEL, "Revolver belt", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "black"),
		/obj/item/belt_harness/marine = list(CAT_BEL, "Belt Harness", 0, "black"),
		/obj/item/storage/pouch/shotgun = list(CAT_POU, "Shotgun shell pouch", 0, "black"),
		/obj/item/storage/pouch/general/large = list(CAT_POU, "Large general pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0, "black"),
		/obj/item/storage/pouch/grenade/slightlyfull = list(CAT_POU, "Grenade pouch (grenades included)", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0, "black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
		/obj/item/clothing/head/headband/red = list(CAT_HEL, "FC Headband", 0, "black"),
		/obj/item/clothing/head/tgmcberet/fc = list(CAT_HEL, "FC Beret", 0, "black"),
		/obj/item/clothing/head/helmet/marine/leader = list(CAT_HEL, "FC Helmet", 0, "black"),
	)


/obj/machinery/marine_selector/clothes/synth
	name = "M57 Synthetic Equipment Vendor"
	desc = "An automated synthetic equipment vendor hooked up to a modest storage unit."
	icon_state = "synth"
	icon_vend = "synth-vend"
	icon_deny = "synth-deny"
	vendor_role = /datum/job/terragov/silicon/synthetic
	lock_flags = JOB_LOCK

	listed_products = list(
		/obj/effect/essentials_set/synth = list(CAT_ESS, "Essential synthetic set", 0, "white"),
		/obj/item/clothing/under/marine = list(CAT_STD, "TGMC marine uniform", 0, "black"),
		/obj/item/clothing/under/rank/medical/blue = list(CAT_STD, "Medical scrubs (blue)", 0, "black"),
		/obj/item/clothing/under/rank/medical/green = list(CAT_STD, "Medical scrubs (green)", 0, "black"),
		/obj/item/clothing/under/rank/medical/purple = list(CAT_STD, "Medical scrubs (purple)", 0, "black"),
		/obj/item/clothing/under/marine/officer/engi = list(CAT_STD, "Engineering uniform", 0, "black"),
		/obj/item/clothing/under/marine/officer/logistics = list(CAT_STD, "Officer uniform", 0, "black"),
		/obj/item/clothing/under/whites = list(CAT_STD, "TGMC dress uniform", 0, "black"),
		/obj/item/clothing/under/marine/officer/pilot = list(CAT_STD, "Pilot bodysuit", 0, "black"),
		/obj/item/clothing/under/marine/mp = list(CAT_STD, "Military police uniform", 0, "black"),
		/obj/item/clothing/under/marine/officer/researcher = list(CAT_STD, "Researcher outfit", 0, "black"),
		/obj/item/clothing/under/rank/chef = list(CAT_STD, "Chef uniform", 0, "black"),
		/obj/item/clothing/under/rank/bartender = list(CAT_STD, "Bartender uniform", 0, "black"),
		/obj/item/clothing/suit/storage/hazardvest = list(CAT_AMR, "Hazard vest", 0, "black"),
		/obj/item/clothing/suit/surgical = list(CAT_AMR, "Surgical apron", 0, "black"),
		/obj/item/clothing/suit/storage/labcoat = list(CAT_AMR, "Labcoat", 0, "black"),
		/obj/item/clothing/suit/storage/labcoat/researcher = list(CAT_AMR, "Researcher's labcoat", 0, "black"),
		/obj/item/clothing/suit/storage/snow_suit = list(CAT_AMR, "Snow suit", 0, "black"),
		/obj/item/clothing/suit/armor/vest/pilot = list(CAT_AMR, "M70 flak jacket", 0, "black"),
		/obj/item/clothing/suit/storage/marine/MP = list(CAT_AMR, "N2 pattern MA armor", 0, "black"),
		/obj/item/clothing/suit/storage/marine/MP/RO = list(CAT_AMR, "M3 pattern officer armor", 0, "black"),
		/obj/item/clothing/suit/chef = list(CAT_AMR, "Chef's apron", 0, "black"),
		/obj/item/clothing/suit/wcoat = list(CAT_AMR, "Waistcoat", 0, "black"),
		/obj/item/storage/backpack/marine/satchel = list(CAT_BAK, "Satchel", 0, "black"),
		/obj/item/storage/backpack/marine = list(CAT_BAK, "Lightweight IMP backpack", 0, "black"),
		/obj/item/storage/backpack/industrial = list(CAT_BAK, "Industrial backpack", 0, "black"),
		/obj/item/storage/backpack/marine/corpsman = list(CAT_BAK, "TGMC corpsman backpack", 0, "black"),
		/obj/item/storage/backpack/marine/tech = list(CAT_BAK, "TGMC technician backpack", 0, "black"),
		/obj/item/storage/backpack/marine/engineerpack = list(CAT_BAK, "TGMC technician welderpack", 0, "black"),
		/obj/item/storage/backpack/lightpack = list(CAT_BAK, "Lightweight combat pack", 0, "black"),
		/obj/item/storage/backpack/marine/satchel/officer_cloak = list(CAT_BAK, "Officer cloak", 0, "black"),
		/obj/item/storage/backpack/marine/satchel/officer_cloak_red = list(CAT_BAK, "Officer cloak, red", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Webbing", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical Black Vest", 0, "black"),
		/obj/item/clothing/tie/storage/white_vest/medic = list(CAT_WEB, "White medical vest", 0, "black"),
		/obj/item/clothing/gloves/yellow = list(CAT_GLO, "Insulated gloves", 0, "black"),
		/obj/item/clothing/gloves/latex = list(CAT_GLO, "Latex gloves", 0, "black"),
		/obj/item/clothing/gloves/marine/officer = list(CAT_GLO, "Officer gloves", 0, "black"),
		/obj/item/clothing/gloves/white = list(CAT_GLO, "White gloves", 0, "black"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "M276 pattern medical storage rig", 0, "black"),
		/obj/item/storage/belt/combatLifesaver = list(CAT_BEL, "M276 pattern lifesaver bag", 0, "black"),
		/obj/item/storage/belt/utility/full = list(CAT_BEL, "M276 pattern toolbelt rig", 0, "black"),
		/obj/item/storage/belt/security/MP/full = list(CAT_BEL, "M276 pattern security rig ", 0, "black"),
		/obj/item/storage/belt/sparepouch = list(CAT_BEL, "G8 general utility pouch", 0, "black"),
		/obj/item/clothing/shoes/marine = list(CAT_SHO, "Marine combat boots", 0, "black"),
		/obj/item/clothing/shoes/white = list(CAT_SHO, "White shoes", 0, "black"),
		/obj/item/clothing/shoes/marinechief = list(CAT_SHO, "Formal shoes", 0, "black"),
		/obj/item/storage/pouch/general/large = list(CAT_POU, "Large general pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch", 0, "black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch", 0, "black"),
		/obj/item/storage/pouch/electronics/full = list(CAT_POU, "Electronics pouch", 0, "black"),
		/obj/item/storage/pouch/medical = list(CAT_POU, "Medical pouch", 0, "black"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/autoinjector/full = list(CAT_POU, "Autoinjector pouch", 0, "orange"),
		/obj/item/storage/pouch/flare/full = list(CAT_POU, "Flare pouch", 0, "black"),
		/obj/item/storage/pouch/radio = list(CAT_POU, "Radio pouch", 0, "black"),
		/obj/item/storage/pouch/field_pouch/full = list(CAT_POU, "Field pouch", 0, "black"),
		/obj/item/clothing/head/hardhat = list(CAT_HEL, "Hard hat", 0, "black"),
		/obj/item/clothing/head/welding = list(CAT_HEL, "Welding helmet", 0, "black"),
		/obj/item/clothing/head/surgery/green = list(CAT_HEL, "Surgical cap", 0, "black"),
		/obj/item/clothing/head/tgmccap = list(CAT_HEL, "TGMC cap", 0, "black"),
		/obj/item/clothing/head/boonie = list(CAT_HEL, "Boonie hat", 0, "black"),
		/obj/item/clothing/head/beret/marine = list(CAT_HEL, "Marine beret", 0, "black"),
		/obj/item/clothing/head/tgmcberet/red = list(CAT_HEL, "MP beret", 0, "black"),
		/obj/item/clothing/head/beret/eng = list(CAT_HEL, "Engineering beret", 0, "black"),
		/obj/item/clothing/head/ushanka = list(CAT_HEL, "Ushanka", 0, "black"),
		/obj/item/clothing/head/collectable/tophat = list(CAT_HEL, "Top hat", 0, "black"),
		/obj/item/clothing/mask/surgical = list(CAT_MAS, "Sterile mask", 0, "black"),
		/obj/item/clothing/mask/rebreather = list(CAT_MAS, "Rebreather", 0, "black"),
		/obj/item/clothing/mask/rebreather/scarf = list(CAT_MAS, "Heat absorbent coif", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0, "black"),
	)



////////////////////// Gear ////////////////////////////////////////////////////////



/obj/machinery/marine_selector/gear
	name = "NEXUS Automated Equipment Rack"
	desc = "An automated equipment rack hooked up to a colossal storage unit."
	icon_state = "marinearmory"
	use_points = TRUE
	listed_products = list(
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical Grip", 0, "black"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red-dot sight", 0, "black"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil Compensator", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser Sight", 0, "black")
	)



/obj/machinery/marine_selector/gear/medic
	name = "NEXUS Automated Medical Equipment Rack"
	desc = "An automated medic equipment rack hooked up to a colossal storage unit."
	icon_state = "medic"
	vendor_role = /datum/job/terragov/squad/corpsman
	req_access = list(ACCESS_MARINE_MEDPREP)

	listed_products = list(
		/obj/effect/essentials_set/medic = list(CAT_ESS, "Essential Medic Set", 0, "white"),

		/obj/item/storage/firstaid/regular = list(CAT_MEDSUP, "Firstaid kit", 2, "black"),
		/obj/item/storage/firstaid/adv = list(CAT_MEDSUP, "Advanced firstaid kit", 4, "orange"),
		/obj/item/storage/pouch/autoinjector/advanced/full = list(CAT_MEDSUP, "Advanced Medical Injectors", 15, "orange"),
		/obj/item/storage/pill_bottle/paracetamol = list(CAT_MEDSUP, "Paracetamol pills", 10, "black"),
		/obj/item/storage/syringe_case/meralyne = list(CAT_MEDSUP, "syringe Case (120u Meralyne)", 9, "orange"),
		/obj/item/storage/syringe_case/dermaline = list(CAT_MEDSUP, "syringe Case (120u Dermaline)", 9, "orange"),
		/obj/item/storage/syringe_case/meraderm = list(CAT_MEDSUP, "syringe Case (120u Meraderm)", 9, "orange"),
		/obj/item/storage/syringe_case/ironsugar = list(CAT_MEDSUP, "syringe Case (120u Ironsugar)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = list(CAT_MEDSUP, "Injector (Advanced)", 5, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = list(CAT_MEDSUP, "Injector (Oxycodone)", 1, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/hypervene = list(CAT_MEDSUP, "Injector (Hypervene)", 1, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/synaptizine = list(CAT_MEDSUP, "Injector (Synaptizine)", 4, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/neuraline = list(CAT_MEDSUP, "Injector (Neuraline)", 15, "orange"),
		/obj/item/reagent_containers/hypospray/advanced = list(CAT_MEDSUP, "Advanced hypospray", 2, "black"),
		/obj/item/clothing/glasses/hud/health = list(CAT_MEDSUP, "Medical HUD glasses", 2, "black"),

		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0, "black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0, "orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0, "black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0, "orange"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0, "black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0, "black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0, "orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0, "black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0, "black"),
	)



/obj/machinery/marine_selector/gear/engi
	name = "NEXUS Automated Engineer Equipment Rack"
	desc = "An automated engineer equipment rack hooked up to a colossal storage unit."
	icon_state = "engineer"
	vendor_role = /datum/job/terragov/squad/engineer
	req_access = list(ACCESS_MARINE_ENGPREP)

	listed_products = list(
		/obj/effect/essentials_set/engi = list(CAT_ESS, "Essential Engineer Set", 0, "white"),

		/obj/item/stack/sheet/metal/small_stack = list(CAT_ENGSUP, "Metal x10", 5, "orange"),
		/obj/item/stack/sheet/plasteel/small_stack = list(CAT_ENGSUP, "Plasteel x10", 7, "orange"),
		/obj/item/stack/sandbags_empty/half = list(CAT_ENGSUP, "Sandbags x25", 10, "orange"),
		/obj/item/tool/pickaxe/plasmacutter = list(CAT_ENGSUP, "Plasma cutter", 20, "black"),
		/obj/item/storage/box/minisentry = list(CAT_ENGSUP, "UA-580 point defense sentry kit", 26, "black"),
		/obj/item/explosive/plastique = list(CAT_ENGSUP, "Plastique explosive", 3, "black"),
		/obj/item/detpack = list(CAT_ENGSUP, "Detonation pack", 5, "black"),
		/obj/item/tool/shovel/etool = list(CAT_ENGSUP, "Entrenching tool", 1, "black"),
		/obj/item/binoculars/tactical/range = list(CAT_ENGSUP, "Range Finder", 10, "black"),
		/obj/item/cell/high = list(CAT_ENGSUP, "High capacity powercell", 1, "black"),
		/obj/item/storage/box/explosive_mines = list(CAT_ENGSUP, "M20 mine box", 18, "black"),
		/obj/item/explosive/grenade/incendiary = list(CAT_ENGSUP, "Incendiary grenade", 6, "black"),
		/obj/item/multitool = list(CAT_ENGSUP, "Multitool", 1, "black"),
		/obj/item/circuitboard/general = list(CAT_ENGSUP, "General circuit board", 1, "black"),
		/obj/item/assembly/signaler = list(CAT_ENGSUP, "Signaler (for detpacks)", 1, "black"),
		/obj/item/stack/voucher/sentry = list(CAT_ENGSUP, "UA-580 point defense sentry voucher", 26, "black"),

		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0, "black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0, "orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0, "black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0, "orange"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0, "black"),
		/obj/item/attachable/scope/mini = list(CAT_ATT, "Mini-Scope", 0,"black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0, "black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0, "orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0, "black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0, "black"),
	)



/obj/machinery/marine_selector/gear/smartgun
	name = "NEXUS Automated Smartgunner Equipment Rack"
	desc = "An automated smartgunner equipment rack hooked up to a colossal storage unit."
	icon_state = "smartgunner"
	vendor_role = /datum/job/terragov/squad/smartgunner
	req_access = list(ACCESS_MARINE_SMARTPREP)

	listed_products = list(
		/obj/item/storage/box/t26_system = list(CAT_ESS, "Essential Smartgunner Set", 0, "white"),

		/obj/item/ammo_magazine/standard_smartmachinegun = list(CAT_SPEAMM, "T26 ammo drum", 45, "black"),

		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0, "black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0, "orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0, "black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0, "orange"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0, "black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0, "black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0, "orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0, "black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0, "black"),
	)


//todo: move this to some sort of kit controller/datum
//the global list of specialist sets that haven't been claimed yet.
GLOBAL_LIST_INIT(available_specialist_sets, list("Scout Set", "Sniper Set", "Demolitionist Set", "Heavy Grenadier Set","Heavy Gunner Set", "Pyro Set"))


/obj/machinery/marine_selector/gear/spec
	name = "NEXUS Automated Specialist Equipment Rack"
	desc = "An automated specialist equipment rack hooked up to a colossal storage unit."
	icon_state = "specialist"
	vendor_role = /datum/job/terragov/squad/specialist
	req_access = list(ACCESS_MARINE_SPECPREP)

	listed_products = list(
		/obj/item/storage/box/spec/scout = list(CAT_ESS, "Scout Set (Battle Rifle)", 0, "white"),
		/obj/item/storage/box/spec/tracker = list(CAT_ESS, "Scout Set (Shotgun)", 0, "white"),
		/obj/item/storage/box/spec/sniper = list(CAT_ESS, "Sniper Set", 0, "white"),
		/obj/item/storage/box/spec/demolitionist = list(CAT_ESS, "Demolitionist Set", 0, "white"),
		/obj/item/storage/box/spec/heavy_grenadier = list(CAT_ESS, "Heavy Grenadier Set", 0, "white"),
		/obj/item/storage/box/spec/heavy_gunner = list(CAT_ESS, "Heavy Gunner Set", 0, "white"),
		/obj/item/storage/box/spec/pyro = list(CAT_ESS, "Pyro Set", 0, "white"),

		/obj/item/ammo_magazine/pistol/vp70 = list(CAT_SPEAMM, "88M4 AP magazine", 15, "black"),

		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0, "black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0, "orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0, "black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0, "orange"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0, "black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0, "black"),
		/obj/item/attachable/scope/mini = list(CAT_ATT, "Mini-Scope", 0,"black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0, "orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0, "black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0, "black"),
	)

/obj/machinery/marine_selector/gear/spec/Initialize()
    . = ..()
    new /obj/effect/decal/cleanable/cobweb(loc)
    for(var/d in GLOB.alldirs)
        var/turf/T = get_step(src, d)
        if(!T.density)
            new /obj/effect/decal/cleanable/cobweb(T)



/obj/machinery/marine_selector/gear/leader
	name = "NEXUS Automated Squad Leader Equipment Rack"
	desc = "An automated squad leader equipment rack hooked up to a colossal storage unit."
	icon_state = "squadleader"
	vendor_role = /datum/job/terragov/squad/leader
	req_access = list(ACCESS_MARINE_LEADER)

	listed_products = list(
		/obj/effect/essentials_set/leader = list(CAT_ESS, "Essential SL Set", 0, "white"),

		/obj/item/squad_beacon = list(CAT_LEDSUP, "Supply beacon", 10, "black"),
		/obj/item/squad_beacon/bomb = list(CAT_LEDSUP, "Orbital beacon", 15, "black"),
		/obj/item/tool/shovel/etool = list(CAT_LEDSUP, "Entrenching tool", 1, "black"),
		/obj/item/stack/sandbags_empty/half = list(CAT_LEDSUP, "Sandbags x25", 10, "black"),
		/obj/item/explosive/plastique = list(CAT_LEDSUP, "Plastique explosive", 3, "black"),
		/obj/item/detpack = list(CAT_LEDSUP, "Detonation pack", 5, "black"),
		/obj/item/explosive/grenade/smokebomb = list(CAT_LEDSUP, "Smoke grenade", 2, "black"),
		/obj/item/explosive/grenade/cloakbomb = list(CAT_LEDSUP, "Cloak grenade", 3, "black"),
		/obj/item/explosive/grenade/incendiary = list(CAT_LEDSUP, "M40 HIDP incendiary grenade", 3, "black"),
		/obj/item/explosive/grenade/frag = list(CAT_LEDSUP, "M40 HEDP grenade", 3, "black"),
		/obj/item/weapon/gun/flamer = list(CAT_LEDSUP, "Flamethrower", 12, "orange"),
		/obj/item/ammo_magazine/flamer_tank = list(CAT_LEDSUP, "Flamethrower tank", 4, "black"),
		/obj/item/whistle = list(CAT_LEDSUP, "Whistle", 5, "black"),
		/obj/item/radio = list(CAT_LEDSUP, "Station bounced radio", 1, "black"),
		/obj/item/assembly/signaler = list(CAT_LEDSUP, "Signaler (for detpacks)", 1, "black"),
		/obj/item/motiondetector = list(CAT_LEDSUP, "Motion detector", 5, "black"),
		/obj/item/storage/firstaid/adv = list(CAT_LEDSUP, "Advanced firstaid kit", 10, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/synaptizine = list(CAT_MEDSUP, "Injector (Synaptizine)", 10, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = list(CAT_MEDSUP, "Injector (Advanced)", 15, "orange"),
		/obj/item/storage/box/zipcuffs = list(CAT_LEDSUP, "Ziptie box", 5, "black"),
		/obj/structure/closet/bodybag/tarp = list(CAT_LEDSUP, "V1 thermal-dampening tarp", 5, "black"),
		/obj/item/storage/box/m94/cas = list(CAT_LEDSUP, "CAS flare box", 10, "orange"),

		/obj/item/attachable/suppressor = list(CAT_ATT, "Suppressor", 0, "black"),
		/obj/item/attachable/extended_barrel = list(CAT_ATT, "Extended barrel", 0, "orange"),
		/obj/item/attachable/compensator = list(CAT_ATT, "Recoil compensator", 0, "black"),
		/obj/item/attachable/magnetic_harness = list(CAT_ATT, "Magnetic harness", 0, "orange"),
		/obj/item/attachable/reddot = list(CAT_ATT, "Red dot sight", 0, "black"),
		/obj/item/attachable/lasersight = list(CAT_ATT, "Laser sight", 0, "black"),
		/obj/item/attachable/scope/mini = list(CAT_ATT, "Mini-Scope", 0,"black"),
		/obj/item/attachable/verticalgrip = list(CAT_ATT, "Vertical grip", 0, "black"),
		/obj/item/attachable/angledgrip = list(CAT_ATT, "Angled grip", 0, "orange"),
		/obj/item/attachable/stock/t35stock = list(CAT_ATT, "T-35 stock", 0, "black"),
		/obj/item/attachable/stock/t19stock = list(CAT_ATT, "T-19 machine pistol stock", 0, "black"),
	)
//halo

//UNSC Marine Gear

/obj/machinery/marine_selector/clothes/unscMarine
	name = "C9912 Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_UNSC_MARINE)
	lock_flags = JOB_LOCK
	vendor_role = /datum/job/unsc/marine/basic
	listed_products = list(
		/obj/effect/essentials_set/halo/basic = list(CAT_ESS, "Marine Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloMarine/armorPieces = list(CAT_AMR, "UNSC Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/utility/full = list(CAT_BEL, "Full toolbelt", 0, "black"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"),
	)

/obj/machinery/marine_selector/clothes/unscMarine/medic
	name = "C9912-M Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "medic"
	req_access = list(ACCESS_UNSC_MEDIC)
	lock_flags = JOB_LOCK
	vendor_role = /datum/job/unsc/marine/medic
	listed_products = list(
		/obj/effect/essentials_set/halo/basic/medic = list(CAT_ESS, "Marine Medical Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloMarine/armorPieces = list(CAT_AMR, "UNSC Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/brown_vest = list(CAT_WEB, "Tactical brown vest", 0, "black"),
		/obj/item/clothing/tie/storage/white_vest/medic = list(CAT_WEB, "Corpsman white vest", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/clothing/tie/storage/white_vest = list(CAT_WEB, "Corpsman surgical vest", 0, "black"),
		/obj/item/storage/belt/combatLifesaver = list(CAT_BEL, "Lifesaver belt", 0, "white"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/pouch/medical = list(CAT_POU, "Medical pouch", 0, "black"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "white"),
		/obj/item/storage/pouch/autoinjector/full = list(CAT_POU, "Autoinjector pouch", 0, "white"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/unscMarine/engineer
	name = "C9912-E Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "engineer"
	req_access = list(ACCESS_UNSC_ENGINEER)
	vendor_role = /datum/job/unsc/marine/engineer
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/basic/engineer = list(CAT_ESS, "Marine Engineer Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloMarine/armorPieces = list(CAT_AMR, "UNSC Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/utility/full = list(CAT_BEL, "Full toolbelt", 0, "white"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/storage/backpack/marine/engineerpack = list(CAT_BAK, "Welderpack", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0, "white"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/unscMarine/leader
	name = "C9913 Automated Squad Leader Equipment Locker"
	req_access = list(ACCESS_UNSC_LEADER)
	lock_flags = JOB_LOCK
	vendor_role = /datum/job/unsc/marine/leader // both req_access and vendor_role are holdovers for now
	listed_products = list(
		/obj/effect/essentials_set/halo/basic = list(CAT_ESS, "Marine Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloMarine/armorPieces = list(CAT_AMR, "UNSC Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"))

/obj/machinery/marine_selector/gear/unscEquipment
	name = "A127 Automated Requisitions Vendor"
	desc = "An automated requisitions vendor, with a strict limit in how much each marine requests."
	icon_state = "synth"
	req_access = list(ACCESS_UNSC_MARINE)
	vendor_role = /datum/job/unsc/marine/basic
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 15, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 15, "black"),
		/obj/item/explosive/plastique = list(CAT_EXP, "Plastique explosive", 15, "black"),
		/obj/item/explosive/grenade/frag/m9 = list(CAT_EXP, "M9 Grenade", 15, "black"),
		/obj/item/stack/sandbags_empty/half = list(CAT_ENGSUP, "Sandbags x25", 10, "orange"),
		/obj/item/tool/shovel/etool = list(CAT_ENGSUP, "Entrenching tool", 5, "black"),
		/obj/item/storage/firstaid/regular = list(CAT_MEDSUP, "Firstaid kit", 5, "black"),
		/obj/item/storage/firstaid/adv = list(CAT_MEDSUP, "Advanced firstaid kit", 15, "orange"),
		/obj/item/storage/pouch/autoinjector/advanced/full = list(CAT_MEDSUP, "Advanced Medical Injectors", 30, "orange"),
		/obj/item/storage/pill_bottle/paracetamol = list(CAT_MEDSUP, "Paracetamol pills", 10, "black"),
		/obj/item/storage/syringe_case/meralyne = list(CAT_MEDSUP, "syringe Case (120u Meralyne)", 10, "orange"),
		/obj/item/storage/syringe_case/dermaline = list(CAT_MEDSUP, "syringe Case (120u Dermaline)", 10, "orange"),
		/obj/item/storage/syringe_case/meraderm = list(CAT_MEDSUP, "syringe Case (120u Meraderm)", 10, "orange"),
		/obj/item/storage/syringe_case/ironsugar = list(CAT_MEDSUP, "syringe Case (120u Ironsugar)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = list(CAT_MEDSUP, "Injector (Advanced)", 5, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = list(CAT_MEDSUP, "Injector (Oxycodone)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/hypervene = list(CAT_MEDSUP, "Injector (Hypervene)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/synaptizine = list(CAT_MEDSUP, "Injector (Synaptizine)", 5, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/neuraline = list(CAT_MEDSUP, "Injector (Neuraline)", 15, "orange"))

//ODST Gear

/obj/machinery/marine_selector/clothes/odst/rifleman
	name = "ODST Rifleman Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_ODST_RIFLEMAN)
	vendor_role = /datum/job/unsc/odst/rifleman
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstRifleman = list(CAT_AMR, "ODST Rifleman Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/odst/medic
	name = "ODST Medic Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_ODST_MEDIC)
	vendor_role = /datum/job/unsc/odst/medic
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstMedic = list(CAT_AMR, "ODST Medic Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/odst/engineer
	name = "ODST Engineer Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_ODST_ENGINEER)
	vendor_role = /datum/job/unsc/odst/engineer
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstRifleman = list(CAT_AMR, "ODST Engineer Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/odst/sniper
	name = "ODST Sniper Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_SNIPER)
	vendor_role = /datum/job/unsc/odst/sniper
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstSniper = list(CAT_AMR, "ODST Sniper Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/odst/cqc
	name = "ODST CQC Specialist Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_ODST_CQC)
	vendor_role = /datum/job/unsc/odst/cqc
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstCQC = list(CAT_AMR, "ODST CQC Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/odst/sl
	name = "ODST Squad Leader Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_ODST_SQUADLEADER)
	vendor_role = /datum/job/unsc/odst/sl
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/odst = list (CAT_ESS, "ODST Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/odstRifleman = list(CAT_AMR, "ODST Squad Leader Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

//innie Gear

/obj/machinery/marine_selector/gear/innieEquipment
	name = "Stolen A124 Automated Requisitions Vendor"
	desc = "An automated requisitions vendor, with a strict limit in how much each insurrectionist requests."
	icon_state = "synth"
	req_access = list(ACCESS_INSURRECTIONIST_SOLDIER)
	lock_flags = JOB_LOCK
	vendor_role = /datum/job/insurrectionist/basic
	listed_products = list(
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 15, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 15, "black"),
		/obj/item/explosive/plastique = list(CAT_EXP, "Plastique explosive", 15, "black"),
		/obj/item/explosive/grenade/frag/m9 = list(CAT_EXP, "M9 Grenade", 15, "black"),
		/obj/item/stack/sandbags_empty/half = list(CAT_ENGSUP, "Sandbags x25", 10, "orange"),
		/obj/item/tool/shovel/etool = list(CAT_ENGSUP, "Entrenching tool", 5, "black"),
		/obj/item/storage/firstaid/regular = list(CAT_MEDSUP, "Firstaid kit", 5, "black"),
		/obj/item/storage/firstaid/adv = list(CAT_MEDSUP, "Advanced firstaid kit", 15, "orange"),
		/obj/item/storage/pouch/autoinjector/advanced/full = list(CAT_MEDSUP, "Advanced Medical Injectors", 30, "orange"),
		/obj/item/storage/pill_bottle/paracetamol = list(CAT_MEDSUP, "Paracetamol pills", 10, "black"),
		/obj/item/storage/syringe_case/meralyne = list(CAT_MEDSUP, "syringe Case (120u Meralyne)", 10, "orange"),
		/obj/item/storage/syringe_case/dermaline = list(CAT_MEDSUP, "syringe Case (120u Dermaline)", 10, "orange"),
		/obj/item/storage/syringe_case/meraderm = list(CAT_MEDSUP, "syringe Case (120u Meraderm)", 10, "orange"),
		/obj/item/storage/syringe_case/ironsugar = list(CAT_MEDSUP, "syringe Case (120u Ironsugar)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced = list(CAT_MEDSUP, "Injector (Advanced)", 5, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/oxycodone = list(CAT_MEDSUP, "Injector (Oxycodone)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/hypervene = list(CAT_MEDSUP, "Injector (Hypervene)", 5, "black"),
		/obj/item/reagent_containers/hypospray/autoinjector/synaptizine = list(CAT_MEDSUP, "Injector (Synaptizine)", 5, "orange"),
		/obj/item/reagent_containers/hypospray/autoinjector/neuraline = list(CAT_MEDSUP, "Injector (Neuraline)", 15, "orange"))



/obj/machinery/marine_selector/clothes/insurrection
	name = "Stolen C8912 Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_INSURRECTIONIST_SOLDIER)
	vendor_role = /datum/job/insurrectionist/basic
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/innie = list (CAT_ESS, "Insurrection Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloinnie/armorPieces = list(CAT_AMR, "URF Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/medic
	name = "Stolen C8912-M Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "medic"
	req_access = list(ACCESS_INSURRECTIONIST_MEDIC)
	lock_flags = JOB_LOCK
	vendor_role = /datum/job/insurrectionist/medic
	listed_products = list(
		/obj/effect/essentials_set/halo/innie/medic = list(CAT_ESS, "Insurrection Medical Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/innie/medic/two = list(CAT_ESS, "Insurrection Alternative Medical Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloinnie/armorPieces = list(CAT_AMR, "URF Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/brown_vest = list(CAT_WEB, "Tactical brown vest", 0, "orange"),
		/obj/item/clothing/tie/storage/white_vest/medic = list(CAT_WEB, "Corpsman white vest", 0, "black"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/clothing/tie/storage/white_vest = list(CAT_WEB, "Corpsman surgical vest", 0, "black"),
		/obj/item/storage/belt/combatLifesaver = list(CAT_BEL, "Lifesaver belt", 0, "white"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/pouch/medical = list(CAT_POU, "Medical pouch", 0, "black"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "white"),
		/obj/item/storage/pouch/autoinjector/full = list(CAT_POU, "Autoinjector pouch", 0, "white"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/engineer
	name = "Stolen C8912-E Automated Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "engineer"
	req_access = list(ACCESS_INSURRECTIONIST_ENGINEER)
	vendor_role = /datum/job/insurrectionist/engineer
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/innie/engineer = list (CAT_ESS, "Insurrection Emgineer Essentials Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloinnie/armorPieces/heavy = list(CAT_AMR, "URF Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/utility/full = list(CAT_BEL, "Full toolbelt", 0, "white"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/storage/backpack/marine/engineerpack = list(CAT_BAK, "Welderpack", 0, "white"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/construction/full = list(CAT_POU, "Construction pouch (materials included)", 0, "white"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/leader
	name = "Stolen C8913 Squad Leader Equipment Locker"
	req_access = list(ACCESS_INSURRECTIONIST_LEADER)
	vendor_role = /datum/job/insurrectionist/leader
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/innie/sl = list (CAT_ESS, "Traditional Officer Armor Set", 0, "white"),
		/obj/effect/essentials_set/halo/innie/sl/blue = list (CAT_ESS, "Officer Armor Set", 0, "white"),
		/obj/effect/essentials_set/halo/innie/sl/reno = list (CAT_ESS, "Western 'Reno' Armor Set", 0, "white"),
		/obj/effect/essentials_set/modular/haloinnie/armorPieces/heavy = list(CAT_AMR, "URF Modular Armor Pieces", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/clothing/tie/storage/black_vest = list(CAT_WEB, "Tactical black vest", 0, "black"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"orange"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "orange"),
		/obj/item/storage/pouch/medkit = list(CAT_POU, "Medkit pouch", 0, "black"),
		/obj/item/storage/pouch/tools/full = list(CAT_POU, "Tool pouch (tools included)", 0, "black"),
		/obj/item/storage/pouch/explosive = list(CAT_POU, "Explosive pouch", 0, "black"),
		/obj/item/storage/pouch/magazine/pistol/large = list(CAT_POU, "Large pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"),
		/obj/item/storage/large_holster/machete/full = list(CAT_BAK, "Machete scabbard", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/belt/medical = list(CAT_BEL, "Medical belt", 0, "black"),
		/obj/item/storage/belt/gun/pistol/standard_pistol = list(CAT_BEL, "Pistol belt", 0, "black"))

//URFC Gear

/obj/machinery/marine_selector/clothes/insurrection/urfc/rifleman
	name = "URFC Rifleman Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_RIFLEMAN)
	vendor_role = /datum/job/insurrectionist/commando/rifleman
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcRifleman = list(CAT_AMR, "URFC Rifleman Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))


/obj/machinery/marine_selector/clothes/insurrection/urfc/medic
	name = "URFC Medic Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_MEDIC)
	vendor_role = /datum/job/insurrectionist/commando/medic
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcMedic = list(CAT_AMR, "URFC Medic Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))


/obj/machinery/marine_selector/clothes/insurrection/urfc/engineer
	name = "URFC Engineer Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_ENGINEER)
	vendor_role = /datum/job/insurrectionist/commando/engineer
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcEngi = list(CAT_AMR, "URFC Engineer Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/urfc/sniper
	name = "URFC Sniper Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_SNIPER)
	vendor_role = /datum/job/insurrectionist/commando/sniper
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcSniper = list(CAT_AMR, "URFC Sniper Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/urfc/cqb
	name = "URFC CQB Specialist Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_CQB)
	vendor_role = /datum/job/insurrectionist/commando/cqb
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcCQB = list(CAT_AMR, "URFC CQB Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/urfc/sl
	name = "URFC Squad Leader Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_SQUADLEADER)
	vendor_role = /datum/job/insurrectionist/commando/sl
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcSL = list(CAT_AMR, "URFC Squad Leader Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))

/obj/machinery/marine_selector/clothes/insurrection/urfc/commander
	name = "URFC Commander Equipment Locker"
	desc = "An automated closet hooked up to a colossal storage unit of standard-issue uniform and armor."
	icon_state = "marineuniform"
	req_access = list(ACCESS_URFC_COMMANDER)
	vendor_role = /datum/job/insurrectionist/commando/commander
	lock_flags = JOB_LOCK
	listed_products = list(
		/obj/effect/essentials_set/halo/urfc = list (CAT_ESS, "URFC Essentials Set", 0, "white"),
		/obj/effect/essentials_set/halo/urfcCommander = list(CAT_AMR, "URFC Commander Armor", 0, "white"),
		/obj/item/clothing/tie/storage/webbing = list(CAT_WEB, "Tactical webbing", 0, "black"),
		/obj/item/clothing/tie/holster = list(CAT_WEB, "Shoulder handgun holster", 0, "black"),
		/obj/item/storage/belt/marine = list(CAT_BEL, "Standard ammo belt", 0, "white"),
		/obj/item/storage/belt/shotgun = list(CAT_BEL, "Shotgun ammo belt", 0, "black"),
		/obj/item/storage/pouch/magazine/large = list(CAT_POU, "Large magazine pouch", 0, "black"),
		/obj/item/storage/pouch/general/medium = list(CAT_POU, "Medium general pouch", 0, "white"),
		/obj/item/storage/pouch/firstaid/injectors/full = list(CAT_POU, "Injector pouch", 0,"black"),
		/obj/item/storage/pouch/firstaid/full = list(CAT_POU, "Firstaid pouch", 0, "white"),
		/obj/item/storage/pouch/magazine/pistol = list(CAT_POU, "Pistol magazine pouch", 0,"black"),
		/obj/item/storage/pouch/pistol = list(CAT_POU, "Sidearm pouch", 0,"black"),
		/obj/item/clothing/mask/gas = list(CAT_MAS, "Gas mask", 0,"black"))


/obj/effect/essentials_set
	var/list/spawned_gear_list

/obj/effect/essentials_set/Initialize()
	. = ..()
	for(var/typepath in spawned_gear_list)
		if(spawned_gear_list[typepath])
			new typepath(loc, spawned_gear_list[typepath])
		else
			new typepath(loc)
	qdel(src)


/obj/effect/essentials_set/basic
	spawned_gear_list = list(
						/obj/item/clothing/under/marine,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						)

/obj/effect/essentials_set/basicmodular
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/jaeger,
						/obj/item/clothing/suit/modular,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/armor_module/attachable/better_shoulder_lamp,
						/obj/item/facepaint/green,
						)

/obj/effect/essentials_set/basic_smartgunner
	spawned_gear_list = list(
						/obj/item/clothing/under/marine,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE
						)

/obj/effect/essentials_set/basic_smartgunnermodular
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/jaeger,
						/obj/item/clothing/suit/modular,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/armor_module/attachable/better_shoulder_lamp,
						/obj/item/facepaint/green,
						)

/obj/effect/essentials_set/basic_specialist
	spawned_gear_list = list(
						/obj/item/clothing/under/marine,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE
						)

/obj/effect/essentials_set/basic_squadleader
	spawned_gear_list = list(
						/obj/item/clothing/suit/storage/marine/pasvest,
						/obj/item/clothing/head/helmet/marine/leader,
						/obj/item/clothing/glasses/hud/health,
						/obj/item/clothing/under/marine,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE
						)

/obj/effect/essentials_set/basic_commander
	spawned_gear_list = list(
						/obj/item/clothing/suit/storage/marine/pasvest,
						/obj/item/clothing/head/helmet/marine/leader,
						/obj/item/clothing/glasses/hud/health,
						/obj/item/clothing/under/marine,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE
						)

/obj/effect/essentials_set/basic_squadleadermodular
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/jaeger,
						/obj/item/clothing/suit/modular,
						/obj/item/clothing/head/helmet/marine/leader,
						/obj/item/clothing/glasses/hud/health,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/armor_module/attachable/better_shoulder_lamp,
						/obj/item/facepaint/green,
						)

/obj/effect/essentials_set/basic_medic
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/corpsman,
						/obj/item/clothing/glasses/hud/health,
						/obj/item/clothing/under/marine/corpsman,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE
						)

/obj/effect/essentials_set/basic_medicmodular
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/jaeger,
						/obj/item/clothing/suit/modular,
						/obj/item/clothing/head/helmet/marine/corpsman,
						/obj/item/clothing/glasses/hud/health,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/armor_module/attachable/better_shoulder_lamp,
						/obj/item/facepaint/green,
						)

/obj/effect/essentials_set/basic_engineer
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/tech,
						/obj/item/clothing/glasses/welding,
						/obj/item/clothing/under/marine/engineer,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/clothing/gloves/marine/insulated,
						)

/obj/effect/essentials_set/basic_engineermodular
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/jaeger,
						/obj/item/clothing/suit/modular,
						/obj/item/clothing/head/helmet/marine/tech,
						/obj/item/clothing/glasses/welding,
						/obj/item/clothing/shoes/marine,
						/obj/item/attachable/bayonetknife,
						/obj/item/storage/box/MRE,
						/obj/item/armor_module/attachable/better_shoulder_lamp,
						/obj/item/clothing/gloves/marine/insulated,
						/obj/item/facepaint/green,
						)

/obj/effect/essentials_set/medic
	spawned_gear_list = list(
						/obj/item/bodybag/cryobag,
						/obj/item/defibrillator,
						/obj/item/healthanalyzer,
						/obj/item/roller/medevac,
						/obj/item/medevac_beacon,
						/obj/item/roller,
						/obj/item/reagent_containers/hypospray/advanced/oxycodone,
						)

/obj/effect/essentials_set/engi
	spawned_gear_list = list(
						/obj/item/explosive/plastique,
						/obj/item/stack/sandbags_empty = 25,
						/obj/item/stack/sheet/metal/small_stack,
						/obj/item/cell/high,
						/obj/item/tool/shovel/etool,
						/obj/item/lightreplacer,
						/obj/item/circuitboard/general,
						)

/obj/effect/essentials_set/leader
	spawned_gear_list = list(
						/obj/item/explosive/plastique,
						/obj/item/squad_beacon,
						/obj/item/squad_beacon,
						/obj/item/squad_beacon/bomb,
						/obj/item/whistle,
						/obj/item/radio,
						/obj/item/motiondetector,
						/obj/item/binoculars/tactical,
						)

/obj/effect/essentials_set/commander
	spawned_gear_list = list(
						/obj/item/squad_beacon,
						/obj/item/squad_beacon/bomb,
						/obj/item/healthanalyzer,
						/obj/item/roller/medevac,
						/obj/item/medevac_beacon,
						/obj/item/whistle,
						/obj/item/radio,
						/obj/item/motiondetector,
						)

/obj/effect/essentials_set/synth
	spawned_gear_list = list(
						/obj/item/stack/sheet/plasteel/medium_stack,
						/obj/item/stack/sheet/metal/large_stack,
						/obj/item/lightreplacer,
						/obj/item/healthanalyzer,
						/obj/item/defibrillator,
						/obj/item/medevac_beacon,
						/obj/item/roller/medevac,
						/obj/item/bodybag/cryobag,
						/obj/item/reagent_containers/hypospray/advanced/oxycodone
						)

/obj/effect/essentials_set/modular/infantry
	desc = "A set of light Infantry pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
						/obj/item/clothing/head/modular/marine,
						/obj/item/armor_module/armor/chest/marine,
						/obj/item/armor_module/armor/arms/marine,
						/obj/item/armor_module/armor/legs/marine,
						)

/obj/effect/essentials_set/modular/skirmisher
	desc = "A set of medium Skirmisher pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
						/obj/item/clothing/head/modular/marine/skirmisher,
						/obj/item/armor_module/armor/chest/marine/skirmisher,
						/obj/item/armor_module/armor/arms/marine/skirmisher,
						/obj/item/armor_module/armor/legs/marine/skirmisher,
						)

/obj/effect/essentials_set/modular/assault
	desc = "A set of heavy Assault pattern Jaeger armor, including an exoskeleton, helmet, and armor plates."
	spawned_gear_list = list(
						/obj/item/clothing/head/modular/marine/assault,
						/obj/item/armor_module/armor/chest/marine/assault,
						/obj/item/armor_module/armor/arms/marine/assault,
						/obj/item/armor_module/armor/legs/marine/assault,
						)


// UNSC sets
/obj/effect/essentials_set/halo/basic
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/unscmarine,
						/obj/item/clothing/shoes/marine/unscmarine,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/suit/modular/unscmarine,
						/obj/item/clothing/gloves/marine/unscmarine,
						/obj/item/storage/box/MRE)

/obj/effect/essentials_set/halo/basic/medic
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/unscmarine,
						/obj/item/clothing/shoes/marine/unscmarine,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/suit/modular/unscmarine,
						/obj/item/clothing/gloves/marine/unscmarine,
						/obj/item/storage/box/MRE,
						/obj/item/bodybag/cryobag,
						/obj/item/defibrillator,
						/obj/item/healthanalyzer,
						/obj/item/roller,
						/obj/item/reagent_containers/hypospray/advanced/oxycodone,
						/obj/item/clothing/glasses/hud/health)

/obj/effect/essentials_set/halo/basic/engineer
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/unscmarine,
						/obj/item/clothing/shoes/marine/unscmarine,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/suit/modular/unscmarine,
						/obj/item/clothing/gloves/marine/unscmarine,
						/obj/item/storage/box/MRE,
						/obj/item/clothing/glasses/welding,
						/obj/item/explosive/plastique,
						/obj/item/stack/sandbags_empty = 25,
						/obj/item/stack/sheet/metal/small_stack,
						/obj/item/tool/shovel/etool)


/obj/effect/essentials_set/modular/haloMarine/armorPieces
	spawned_gear_list = list(
						/obj/item/armor_module/armor/chest/unsc,
						/obj/item/armor_module/armor/arms/unsc,
						/obj/item/armor_module/armor/legs/unsc,
						/obj/item/clothing/head/modular/marine/unscmarine)

//ODST Sets

/obj/effect/essentials_set/halo/odst
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/odst,
						/obj/item/clothing/shoes/marine/odst,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/gloves/marine/insulated/odst,
						/obj/item/storage/box/MRE)

/obj/effect/essentials_set/halo/odstRifleman
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst,
						/obj/item/clothing/suit/storage/marine/odst)

/obj/effect/essentials_set/halo/odstMedic
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst/medic,
						/obj/item/clothing/suit/storage/marine/odst/medic)

/obj/effect/essentials_set/halo/odstEngi
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst/engi,
						/obj/item/clothing/suit/storage/marine/odst/engi)

/obj/effect/essentials_set/halo/odstCQC
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst/cqc,
						/obj/item/clothing/suit/storage/marine/odst/cqc)

/obj/effect/essentials_set/halo/odstSniper
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst/sniper,
						/obj/item/clothing/suit/storage/marine/odst/sniper)

/obj/effect/essentials_set/halo/odstSL
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/odst/sl,
						/obj/item/clothing/suit/storage/marine/odst/sl)

// URF sets

/obj/effect/essentials_set/halo/innie
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/red,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/shoes/marine/urf/black,
						/obj/item/clothing/suit/modular/innie,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/head/helmet/marine/urf/black)

/obj/effect/essentials_set/modular/haloinnie/armorPieces
	spawned_gear_list = list(
						/obj/item/armor_module/armor/chest/innie,
						/obj/item/armor_module/armor/chest/innie/two,
						/obj/item/armor_module/armor/arms/innie,
						/obj/item/armor_module/armor/legs/innie)

/obj/effect/essentials_set/modular/haloinnie/armorPieces/heavy
	spawned_gear_list = list(
						/obj/item/armor_module/armor/chest/innie,
						/obj/item/armor_module/armor/chest/innie/two,
						/obj/item/armor_module/armor/arms/innie/heavy,
						/obj/item/armor_module/armor/legs/innie/heavy)

/obj/effect/essentials_set/halo/innie/engineer
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/red,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/shoes/marine/urf/black,
						/obj/item/clothing/suit/modular/innie,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/glasses/welding,
						/obj/item/clothing/head/helmet/marine/urf/black/engie,
						/obj/item/explosive/plastique,
						/obj/item/stack/sandbags_empty = 25,
						/obj/item/stack/sheet/metal/small_stack,
						/obj/item/tool/shovel/etool)

/obj/effect/essentials_set/halo/innie/sl
	spawned_gear_list = list(
						/obj/item/clothing/suit/storage/marine/urf/blue/traditional,
						/obj/item/clothing/shoes/marine/urf/blue/traditional,
						/obj/item/clothing/gloves/marine/urf/traditional,
						/obj/item/clothing/mask/bandanna/traditional,
						/obj/item/clothing/under/marine/urf/traditional,
						/obj/item/clothing/head/helmet/marine/urf/blue/traditional)

/obj/effect/essentials_set/halo/innie/sl/blue
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/red,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/shoes/marine/urf/black,
						/obj/item/clothing/suit/modular/innie,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/head/helmet/marine/urf/black/sl)

/obj/effect/essentials_set/halo/innie/sl/reno
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/reno,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/shoes/marine/urf/blue/reno,
						/obj/item/clothing/suit/storage/marine/urf/blue/reno,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/head/reno,
						/obj/item/clothing/glasses/eyepatch,
						/obj/item/weapon/gun/revolver/coltnavy,
						/obj/item/ammo_magazine/coltammo,
						/obj/item/storage/belt/gun/revolver/cowboy_holster)

/obj/effect/essentials_set/halo/innie/medic
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/red,
						/obj/item/armor_module/armor/chest/innie,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/shoes/marine/urf/black,
						/obj/item/clothing/suit/modular/innie,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/head/helmet/marine/urf/black/medic,
						/obj/item/bodybag/cryobag,
						/obj/item/defibrillator,
						/obj/item/healthanalyzer,
						/obj/item/roller,
						/obj/item/reagent_containers/hypospray/advanced/oxycodone,
						/obj/item/clothing/glasses/hud/health)

/obj/effect/essentials_set/halo/innie/medic/two
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urf/red/two,
						/obj/item/attachable/bayonetknife,
						/obj/item/armor_module/armor/chest/innie/two,
						/obj/item/clothing/shoes/marine/urf/black,
						/obj/item/clothing/suit/modular/innie/two,
						/obj/item/clothing/gloves/marine/urf/black,
						/obj/item/clothing/head/helmet/marine/urf/black/medic,
						/obj/item/bodybag/cryobag,
						/obj/item/defibrillator,
						/obj/item/healthanalyzer,
						/obj/item/roller,
						/obj/item/reagent_containers/hypospray/advanced/oxycodone,
						/obj/item/clothing/glasses/hud/health)

//URFC Sets

/obj/effect/essentials_set/halo/urfc
	spawned_gear_list = list(
						/obj/item/clothing/under/marine/urfc,
						/obj/item/clothing/shoes/marine/urfc,
						/obj/item/attachable/bayonetknife,
						/obj/item/clothing/gloves/marine/insulated/urfc,
						/obj/item/storage/box/MRE)

/obj/effect/essentials_set/halo/urfcRifleman
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc,
						/obj/item/clothing/suit/storage/marine/urfc)

/obj/effect/essentials_set/halo/urfcMedic
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/medic,
						/obj/item/clothing/suit/storage/marine/urfc/medic)

/obj/effect/essentials_set/halo/urfcEngi
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/engineer,
						/obj/item/clothing/suit/storage/marine/urfc/engineer)

/obj/effect/essentials_set/halo/urfcCQB
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/cqb,
						/obj/item/clothing/suit/storage/marine/urfc/cqb)

/obj/effect/essentials_set/halo/urfcSniper
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/sniper,
						/obj/item/clothing/suit/storage/marine/urfc/sniper)

/obj/effect/essentials_set/halo/urfcSL
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/sl,
						/obj/item/clothing/suit/storage/marine/urfc/sl)

/obj/effect/essentials_set/halo/urfcCommander
	spawned_gear_list = list(
						/obj/item/clothing/head/helmet/marine/urfc/commander,
						/obj/item/clothing/suit/storage/marine/urfc/commander)

#undef MARINE_CAN_BUY_UNIFORM
#undef MARINE_CAN_BUY_SHOES
#undef MARINE_CAN_BUY_HELMET
#undef MARINE_CAN_BUY_ARMOR
#undef MARINE_CAN_BUY_GLOVES
#undef MARINE_CAN_BUY_EAR
#undef MARINE_CAN_BUY_BACKPACK
#undef MARINE_CAN_BUY_R_POUCH
#undef MARINE_CAN_BUY_L_POUCH
#undef MARINE_CAN_BUY_BELT
#undef MARINE_CAN_BUY_GLASSES
#undef MARINE_CAN_BUY_MASK
#undef MARINE_CAN_BUY_ESSENTIALS

#undef MARINE_CAN_BUY_ALL
#undef MARINE_TOTAL_BUY_POINTS
#undef SQUAD_LOCK
#undef JOB_LOCK
