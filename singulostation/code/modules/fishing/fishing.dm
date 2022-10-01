#define IDLE 0
#define CAST 1
#define WAIT 2
#define HOOK 3
#define REEL 4
#define PULL 5

#define ROD_NONE	0
#define ROD_REEL	(1 >> 0)
#define ROD_HOOK	(1 >> 1)
#define ROD_LINE	(1 >> 2)
#define ROD_SINKER	(1 >> 3)
#define ROD_BOBBER	(1 >> 4)
#define ROD_BAIT	(1 >> 5)
#define ROD_ALL		(ROD_REEL|ROD_HOOK|ROD_LINE|ROD_SINKER|ROD_BOBBER|ROD_BAIT)

#define ROD_TACKLE	(ROD_HOOK|ROD_BAIT)

/obj/item/rod_component
	name = "rod component"

	icon = 'icons/obj/food/soupsalad.dmi'
//	icon = 'singulostation/icons/obj/fishing.dmi'
	icon_state = "stew"

	var/rod_slot = ROD_NONE

/obj/item/rod_component/reel
	name = "reel"

	rod_slot = ROD_REEL

/obj/item/rod_component/hook
	name = "fish hook"

	rod_slot = ROD_HOOK

/obj/item/rod_component/tackle
	name = "tackle"

	rod_slot = ROD_TACKLE

/obj/item/rod_component/line
	name = "fishing line"

	rod_slot = ROD_LINE

/obj/item/rod_component/sinker
	name = "sinker"

	rod_slot = ROD_SINKER

/obj/item/rod_component/bobber
	name = "bobber"

	icon = 'singulostation/icons/obj/fishing.dmi'
	name = "bobber"

	icon_state = "hook"

	rod_slot = ROD_BOBBER

/obj/item/rod_component/bait
	name = "bait"

	rod_slot = ROD_BAIT

/obj/item/fishing_rod
	name = "fishing rod"

	icon = 'icons/obj/food/soupsalad.dmi'
	icon_state = "stew"

	var/luck = 7
	var/strength = 100

	// time for cast bar to go up and back down
	// should be even! // I changed things, I do not remember if it still needs to be even
	var/cast_speed = 2 SECONDS

	var/fishing_state = IDLE
	var/datum/fishing_catch/hooked
	var/atom/fishing_at
	var/mob/caster

	var/datum/fishingline/fishingline

	var/progress = 0

	// this is for the two_handed component
	var/is_wielded

	var/filled_slots = ROD_NONE

// Read only or I will bludgeon you
	var/list/obj/item/rod_component/rod_components = list(
		ROD_REEL = null,
		ROD_HOOK = null,
		ROD_LINE = null,
		ROD_SINKER = null,
		ROD_BOBBER = null,
		ROD_BAIT = null,
	)
	var/obj/item/rod_component/bobber/bob

// I don't want this to be global
// It would be a constant if DM supported constant lists
// It's an associative list rather than a regular list for clarity
	var/static/list/datum/fishing_loot/fishing_loot_table_list = list(
		"space" = new /datum/fishing_loot/space(),
		"lava" = new /datum/fishing_loot/lava(),
		"water" = new /datum/fishing_loot/water(),
		"none" = new /datum/fishing_loot/none(),
	)

/obj/item/fishing_rod/Destroy()
	fishing_state = IDLE

	. = ..()

/obj/item/fishing_rod/ComponentInitialize()
	. = ..()

	AddComponent(/datum/component/two_handed, unwield_on_swap = TRUE, auto_wield = TRUE, ignore_attack_self = TRUE, force_wielded = force, force_unwielded = force, block_power_wielded = block_power, block_power_unwielded = block_power)

/obj/item/fishing_rod/attackby(obj/item/attacked_by, mob/user, params)
	if(params2list(params)["alt"])
		for(var/obj/item/rod_component/rc in rod_components)
			remove_rod_component(rc)
		return

	if(istype(attacked_by, /obj/item/rod_component))
		var/obj/item/rod_component/toadd = attacked_by
		if(add_rod_component(toadd))
			user.visible_message(
				"<span class='notice'>You put \the [toadd] onto \the [src].</span>",
				null,
				"<span class='notice'>[user] puts \the [toadd] on \their [src].</span>",
				DEFAULT_MESSAGE_RANGE
			)
//		else
//			todo: tell the user they can't do that
		return

	return ..()

/obj/item/fishing_rod/proc/wield()
	is_wielded = TRUE

/obj/item/fishing_rod/proc/unwield()
	is_wielded = FALSE

/obj/item/fishing_rod/afterattack(atom/target, mob/user, flag, click_parameters)
	. = ..()
	if(.)
		return

	if(filled_slots != ROD_ALL)
// TODO: tell the caster they can't do that
		return

	switch(fishing_state)
		if(IDLE) // Start: IDLE -> CAST

			caster = user
			fishing_at = target

			cast_minigame() // <-- fishing_state changed in this function

		if(CAST) // Success: CAST -> WAIT
			fishing_state = WAIT

		if(WAIT) // Quit Early: WAIT -> IDLE
			fishing_state = IDLE

			bob.moveToNullspace()
			bob = null

			user.visible_message(
				"<span class='notice'>You reel the line in.</span>",
				null,
				"<span class='notice'>[user] reels their fishing line in.</span>",
				DEFAULT_MESSAGE_RANGE
			)

		if(HOOK) // Success HOOK -> REEL
			fishing_state = REEL

			user.visible_message(
				"<span class='warning'>You hooked the something!</span>",
				null,
				"<span class='notice'>[user] hooked something!</span>",
				DEFAULT_MESSAGE_RANGE
			)

		if(REEL)
			progress -= 10
			if(progress < 0)
				progress = 0

			user.visible_message(
				"<span class='warning'>You pull on your fishing rod, but you did it too early!</span>",
				null,
				"<span class='notice'>[user] pulls on their fishing rod.</span>",
				DEFAULT_MESSAGE_RANGE
			)

		if(PULL)
			progress += 50
			if(progress >= 100) // Success PULL -> IDLE
				fishing_state = IDLE

				var/AE = new hooked.caught_type(fishing_at)

				user.visible_message(
					"<span class='notice'>You reel in \the [AE].</span>",
					null,
					"<span class='notice'>[user] reels in \the [AE].</span>",
					DEFAULT_MESSAGE_RANGE
				)

			else // Success, but not done yet PULL -> REEL
				fishing_state = REEL

				user.visible_message(
					"<span class='notice'>You pull on your fishing rod.</span>",
					null,
					"<span class='notice'>[user] pulls on their fishing rod.</span>",
					DEFAULT_MESSAGE_RANGE
				)

/obj/item/fishing_rod/proc/add_rod_component(obj/item/rod_component/toadd)
	if(filled_slots & toadd.rod_slot)
		return FALSE


	// This is to have a rod_component that can take up multiple slots
	for(var/i = 1; i <= ROD_BAIT; i >>= 1)
		if(i & toadd.rod_slot)
			rod_components[i] = toadd

	toadd.moveToNullspace()

	filled_slots |= toadd.rod_slot
	return TRUE

/obj/item/fishing_rod/proc/remove_rod_component(mob/user, obj/item/rod_component/toremove)
	if(!toremove)
		return

	for(var/i = 1; i <= ROD_BAIT; i >>= 1)
		if(i & toremove.rod_slot)
			rod_components[i] = null

	toremove.forceMove(user)

	filled_slots &= ~toremove.rod_slot

/obj/item/fishing_rod/proc/cast_minigame()
	fishing_state = CAST

	var/user_loc = caster.loc
	var/datum/progressbar/bar = new /datum/progressbar(caster, cast_speed, caster)
	var/start = world.time
	var/end = world.time + (cast_speed * 2)

	while(world.time < end && fishing_state == CAST && user_loc == caster.loc) // TODO: Handle movement
		stoplag(1)
		bar.update(cast_speed - abs(world.time - start - cast_speed))

	var/minigame_score = bar.last_progress
	qdel(bar)

	// fishing_state should be CAST if it reaches here // Fail CAST -> IDLE
	if(fishing_state != WAIT)
		fishing_state = IDLE
		return

	caster.visible_message(
		"<span class='notice'>You cast your fishing line.</span>",
		null,
		"<span class='notice'>[caster] casts their fishing line.</span>",
		DEFAULT_MESSAGE_RANGE
	)

	bob = rod_components[ROD_BOBBER]
	bob.forceMove(caster)
	bob.throw_at(fishing_at, 4, 1, caster, FALSE)

	fishingline = new /datum/fishingline(
		caster, bob, time=6000, beam_icon='singulostation/icons/effects/fishingline.dmi',
		beam_icon_state="line", btype=/obj/effect/fishingline
	)

	INVOKE_ASYNC(fishingline, /datum/fishingline.proc/Start)
	progress = 0

	var/fish_next
	var/datum/fishing_loot/tile_loot
	while(fishing_state > CAST)
		fish_next = world.time + 4 SECONDS

		do
			stoplag(1)
			if(user_loc != caster.loc)
				fishing_state = IDLE
		while(fishing_state > CAST && world.time < fish_next)

		fishing_at = get_turf(bob)
		tile_loot = fishing_loot_table(fishing_at)

		switch(fishing_state)
			if(WAIT)
				//This will eventually be the probablility of catching anything per cycle (on non-fishable tiles 0%)
				if(prob(tile_loot.richness))  // Success WAIT -> HOOK
					fishing_state = HOOK
					caster.visible_message(
						"<span class='warning'>You feel something on the line!</span>",
						null,
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>",
						DEFAULT_MESSAGE_RANGE
					)
					hooked = pickweight(tile_loot.pick_rarity(luck, minigame_score))
			if(HOOK)
				if(prob(hooked.resistance)) // Fail HOOK -> WAIT
					fishing_state = WAIT

					caster.visible_message(
						"<span class='warning'>It escaped!</span>",
						null,
						"<span class='notice'>[caster]'s line loses all tension.</span>",
						DEFAULT_MESSAGE_RANGE
					)
				else if(prob(hooked.tug_chance))
					caster.visible_message(
						"<span class='warning'>You feel something pull on the line!</span>",
						null,
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>",
						DEFAULT_MESSAGE_RANGE
					)
			if(REEL)
				if(prob(60))
					fishing_state = PULL
					caster.visible_message(
						"<span class='warning'>You feel something on the line!</span>",
						null,
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>",
						DEFAULT_MESSAGE_RANGE
					)
			if(PULL)
				if(prob(60))
					fishing_state = REEL
					progress -= 20
					caster.visible_message(
						"<span class='warning'>The line loses some tension!</span>",
						null,
						"<span class='notice'>[caster]'s line loses a bit of tension.</span>",
						DEFAULT_MESSAGE_RANGE
					)
	qdel(fishingline)
	fishingline = null
	bob.moveToNullspace()
	bob = null

/obj/item/fishing_rod/attack_self(mob/user)
	return ..()

// Doing this for a default value and subtypes
/obj/item/fishing_rod/proc/list/datum/fishing_loot/fishing_loot_table(var/turf/fishing_at)
	if(istype(fishing_at, /turf/open/space))
		return fishing_loot_table_list["space"]
	if(istype(fishing_at, /turf/open/lava))
		return fishing_loot_table_list["lava"]
	if(istype(fishing_at, /turf/open/water))
		return fishing_loot_table_list["water"]

	return fishing_loot_table_list["none"]

#undef IDLE
#undef CAST
#undef WAIT
#undef HOOK
#undef REEL
#undef PULL

/*
NEED:
	Sprites
	UI
*/
