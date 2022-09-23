#define FISHING_IDLE 0
#define FISHING_CAST 1
#define FISHING_WAIT 2
#define FISHING_HOOK 3
#define FISHING_REEL 4

/obj/item/rod_component

/obj/item/rod_component/reel

/obj/item/rod_component/hook

/obj/item/rod_component/line

/obj/item/rod_component/hook/tackle

/obj/item/rod_component/sinker

/obj/item/rod_component/bait

/obj/item/fishing_rod
	icon = 'icons/obj/food/soupsalad.dmi'
	icon_state = "stew"

	var/luck = 7
	var/strength = 100

	// time for cast bar to go up and back down
	// should be even!
	var/cast_speed = 2 SECONDS
	var/fishing_state = FISHING_IDLE

	var/datum/fishing_catch/hooked
	var/turf/open/fishing_at
	var/mob/caster
	var/datum/progressbar/bar
	var/timerid

	// this is for the two_handed component
	var/is_wielded

	var/item/rod_component/reel/reel
	var/item/rod_component/hook/hook
	var/item/rod_component/line/line
	var/item/rod_component/sinker/sinker
	var/item/rod_component/bait/bait

	var/static/list/loot_tables = list(
		/turf/open/space/basic = new /datum/fishing_loot(),
		/turf/open/lava = new /datum/fishing_loot(),
		/turf/open/water = new /datum/fishing_loot()
	)

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
		if(FISHING_IDLE)
			if(!isopenturf(target))
				return
			if(!loot_tables[target.type])
				return
			//Need to make this check for a line of open space, rather than view
			if(!(target in view(user.client? user.client.view : world.view, user)))
				return
			caster = user
			fishing_at = target
			cast_minigame() // Times 2, because the bar goes up and back down
			return

		if(FISHING_CAST)
			timerid = addtimer(CALLBACK(src, .proc/bite, bar.last_progress), 4 SECONDS, TIMER_STOPPABLE)

			fishing_state = FISHING_WAIT

			qdel(bar)
			bar = null

			return

		if(FISHING_WAIT)
			fishing_state = FISHING_IDLE
			caster = null
			fishing_at = null
			user.visible_message(
				"<span class='notice'>You reel the line in.</span>", \
				null ,\
				"<span class='notice'>[user] reels their fishing line in.</span>", \
				DEFAULT_MESSAGE_RANGE
			)
			return

		if(FISHING_HOOK)
			fishing_state = FISHING_REEL
			user.visible_message(
				"<span class='warning'>You hooked the something!</span>", \
				null ,\
				"<span class='notice'>[user] hooked something!</span>", \
				DEFAULT_MESSAGE_RANGE
			)
			return

		if(FISHING_REEL)
			var/AE = new hooked.caught_type(fishing_at)

			user.visible_message(
				"<span class='notice'>You reel in \the [AE].</span>", \
				null ,\
				"<span class='notice'>[user] reels in \the [AE].</span>", \
				DEFAULT_MESSAGE_RANGE
			)

			caster = null
			fishing_at = null
			hooked = null
			return

/obj/item/fishing_rod/proc/cast_minigame()
	caster.visible_message(
		"<span class='notice'>You cast your fishing line.</span>", \
		null ,\
		"<span class='notice'>[caster] casts their fishing line.</span>", \
		DEFAULT_MESSAGE_RANGE
	)

	bar = new /datum/progressbar(caster, cast_speed, caster)
	var/start = world.time;
	var/end = world.time + (cast_speed * 2)

	fishing_state = FISHING_CAST

	while(world.time < end && fishing_state == FISHING_CAST) // TODO: Handle movement
		stoplag(1)
		bar?.update((cast_speed) - abs(world.time - start - (cast_speed)))
		// The null check is because it's possible for it to be deleted in the middle of the loop from inside the afterattack proc

	if(fishing_state == FISHING_CAST)
		fishing_state = FISHING_IDLE
		qdel(bar)
		bar = null

/obj/item/fishing_rod/proc/bite(minigame_score)
	fishing_state = FISHING_HOOK

	caster.visible_message(
		"<span class='warning'>You feel something on the line!</span>", \
		null ,\
		"<span class='notice'>[caster]'s line gains a bit of tension.</span>", \
		DEFAULT_MESSAGE_RANGE
	)
	hooked = pickweight(loot_tables[fishing_at.type].pick_rarity(luck, minigame_score))
	timerid = 0
	return

/obj/item/fishing_rod/proc/struggle()
	return

/obj/item/fishing_rod/attack_self(mob/user)
	return ..()

/*
NEED:
	Sprites
	UI
*/

#undef FISHING_IDLE
#undef FISHING_CAST
#undef FISHING_WAIT
#undef FISHING_HOOK
#undef FISHING_REEL
