#define IDLE 0
#define CAST 1
#define WAIT 2
#define HOOK 3
#define REEL 4
#define PULL 5

/obj/item/rod_component

/obj/item/rod_component/reel

/obj/item/rod_component/hook

/obj/item/rod_component/hook/tackle

/obj/item/rod_component/line

/obj/item/rod_component/sinker

/obj/item/rod_component/bobber
	name = "bobber"

	icon = 'singulostation/icons/obj/fishing.dmi'
	icon_state = "hook"

/obj/item/rod_component/bait

/obj/item/fishing_rod
	name = "fishing rod"

	icon = 'icons/obj/food/soupsalad.dmi'
	icon_state = "stew"

	var/luck = 7
	var/strength = 100

	// time for cast bar to go up and back down
	// should be even!
	var/cast_speed = 2 SECONDS

	var/fishing_state = IDLE
	var/datum/fishing_catch/hooked
	var/atom/fishing_at
	var/mob/caster

	var/datum/fishingline/fishingline

	var/progress = 0

	// this is for the two_handed component
	var/is_wielded

//	var/obj/item/rod_component/reel/reel
//	var/obj/item/rod_component/hook/hook
//	var/obj/item/rod_component/line/line
//	var/obj/item/rod_component/sinker/sinker
	var/obj/item/rod_component/bobber/bob
//	var/obj/item/rod_component/bait/bait

// I don't want this to be global
// It would be a constant if DM supported constant lists
// It's an associative list rather than a regular list for clarity
	var/static/list/datum/fishing_loot/fishing_loot_table_list = list(
		"space" = new /datum/fishing_loot/space(),
		"lava"  = new /datum/fishing_loot/lava(),
		"water" = new /datum/fishing_loot/water(),
		"none"  = new /datum/fishing_loot/none(),
	)

/obj/item/fishing_rod/Destroy()
	fishing_state = IDLE

	. = ..()

/obj/item/fishing_rod/ComponentInitialize()
	. = ..()

	AddComponent(/datum/component/two_handed, unwield_on_swap = TRUE, auto_wield = TRUE, ignore_attack_self = TRUE, force_wielded = force, force_unwielded = force, block_power_wielded = block_power, block_power_unwielded = block_power)

/obj/item/fishing_rod/proc/wield()
	is_wielded = TRUE

/obj/item/fishing_rod/proc/unwield()
	is_wielded = FALSE

/obj/item/fishing_rod/afterattack(atom/target, mob/user, flag, click_parameters)
	. = ..()
	if(.)
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

			qdel(bob)
			bob = null

			user.visible_message(
				"<span class='notice'>You reel the line in.</span>", \
				null ,\
				"<span class='notice'>[user] reels their fishing line in.</span>", \
				DEFAULT_MESSAGE_RANGE
			)

		if(HOOK) // Success HOOK -> REEL
			fishing_state = REEL

			user.visible_message(
				"<span class='warning'>You hooked the something!</span>", \
				null ,\
				"<span class='notice'>[user] hooked something!</span>", \
				DEFAULT_MESSAGE_RANGE
			)

		if(REEL)
			progress -= 10
			if(progress < 0)
				progress = 0

			user.visible_message(
				"<span class='warning'>You pull on your fishing rod, but you did it too early!</span>", \
				null ,\
				"<span class='notice'>[user] pulls on their fishing rod.</span>", \
				DEFAULT_MESSAGE_RANGE
			)

		if(PULL)
			progress += 50
			if(progress >= 100) // Success PULL -> IDLE
				fishing_state = IDLE

				var/AE = new hooked.caught_type(fishing_at)

				user.visible_message(
					"<span class='notice'>You reel in \the [AE].</span>", \
					null ,\
					"<span class='notice'>[user] reels in \the [AE].</span>", \
					DEFAULT_MESSAGE_RANGE
				)

			else // Success, but not done yet PULL -> REEL
				fishing_state = REEL

				user.visible_message(
					"<span class='notice'>You pull on your fishing rod.</span>", \
					null ,\
					"<span class='notice'>[user] pulls on their fishing rod.</span>", \
					DEFAULT_MESSAGE_RANGE
				)



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
		"<span class='notice'>You cast your fishing line.</span>", \
		null ,\
		"<span class='notice'>[caster] casts their fishing line.</span>", \
		DEFAULT_MESSAGE_RANGE
	)

	bob = new /obj/item/rod_component/bobber(caster.loc)
	bob.throw_at(fishing_at, 4, 1, caster, FALSE)

	fishingline = new /datum/fishingline( \
		caster, bob, time=6000, beam_icon='singulostation/icons/effects/fishingline.dmi', \
		beam_icon_state="line", btype=/obj/effect/fishingline \
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
						"<span class='warning'>You feel something on the line!</span>", \
						null ,\
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>", \
						DEFAULT_MESSAGE_RANGE
					)
					hooked = pickweight(tile_loot.pick_rarity(luck, minigame_score))
			if(HOOK)
				if(prob(hooked.resistance)) // Fail HOOK -> WAIT
					fishing_state = WAIT

					caster.visible_message(
						"<span class='warning'>It escaped!</span>", \
						null ,\
						"<span class='notice'>[caster]'s line loses all tension.</span>", \
						DEFAULT_MESSAGE_RANGE
					)
				else if(prob(hooked.tug_chance))
					caster.visible_message(
						"<span class='warning'>You feel something pull on the line!</span>", \
						null ,\
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>", \
						DEFAULT_MESSAGE_RANGE
					)
			if(REEL)
				if(prob(60))
					fishing_state = PULL
					caster.visible_message(
						"<span class='warning'>You feel something on the line!</span>", \
						null ,\
						"<span class='notice'>[caster]'s line gains a bit of tension.</span>", \
						DEFAULT_MESSAGE_RANGE
					)
			if(PULL)
				if(prob(60))
					fishing_state = REEL
					progress -= 20
					caster.visible_message(
						"<span class='warning'>The line loses some tension!</span>", \
						null ,\
						"<span class='notice'>[caster]'s line loses a bit of tension.</span>", \
						DEFAULT_MESSAGE_RANGE
					)
	qdel(fishingline)
	fishingline = null
	qdel(bob)
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
