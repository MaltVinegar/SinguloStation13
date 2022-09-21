#define FISHING_IDLE 0
//#define FISHING_CAST 1
#define FISHING_TROL 2
#define FISHING_REEL 3

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
	var/strength = 40

	// time for cast bar to go up and back down
	// should be even!
	var/cast_speed = 2 SECONDS
	var/fishing_state = FISHING_IDLE
	var/turf/fishing_at
	var/datum/fishing_catch/hooked

	// this is for the two_handed component
	var/is_wielded

	var/item/rod_component/reel/reel
	var/item/rod_component/hook/hook
	var/item/rod_component/line/line
	var/item/rod_component/sinker/sinker
	var/item/rod_component/bait/bait

	var/static/datum/fishing_loot/loot = new /datum/fishing_loot()


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

	if(fishing_state == FISHING_REEL)
		hooked = pickweight(loot.pick_rarity(luck))
		new hooked.caught_type (fishing_at)
		fishing_at = null
		hooked = null
		fishing_state = FISHING_IDLE
		return

	//Need to make this check for a line of open space, rather than view
	if(!isopenturf(target))
		return

	if(!(target in view(user.client? user.client.view : world.view, user)))
		return

	if(fishing_state == FISHING_IDLE)
		fishing_at = target
		user.visible_message(
			"<span class='notice'>You cast your fishing line.</span>", \
			null ,\
			"<span class='notice'>[user] casts their fishing line.</span>", \
			DEFAULT_MESSAGE_RANGE
		)
		cast_minigame(user) // Times 2, because the bar goes up and back down

/obj/item/fishing_rod/proc/cast_minigame(mob/user)
	var/datum/progressbar/bar = new /datum/progressbar(user, cast_speed, user)
	var/start = world.time;
	var/end = world.time + (cast_speed * 2)
	while(world.time < end) // TODO: Handle movement
		stoplag(1)
		bar.update((cast_speed) - abs(world.time - start - (cast_speed)))
	qdel(bar)
	fishing_state = FISHING_TROL

	while(fishing_state == FISHING_TROL)
		stoplag(1)
		sleep(3 SECONDS)
		if(prob(strength))
			user.visible_message(
				"<span class='warning'>Something bit!</span>", \
				null ,\
				"<span class='notice'>[user]'s line gains tension.</span>", \
				COMBAT_MESSAGE_RANGE
			)
			fishing_state = FISHING_REEL

/obj/item/fishing_rod/attack_self(mob/user)
	return ..()

/*
NEED:
	Sprites
	UI
*/

#undef FISHING_IDLE
#undef FISHING_CAST
#undef FISHING_TROL
#undef FISHING_REEL
