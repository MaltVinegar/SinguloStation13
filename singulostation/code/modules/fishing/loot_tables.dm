/datum/fishing_catch
	var/caught_type
	var/resistance = 100
	var/tug_chance = 100

/datum/fishing_catch/carp
	caught_type = /mob/living/simple_animal/hostile/carp
	resistance = 60
	tug_chance = 90

/datum/fishing_catch/junk
	caught_type = /obj/item/trash/plate
	resistance = 0
	tug_chance = 20

/datum/fishing_loot
	var/richness

	var/list/datum/fishing_catch/legendary = list()
	var/list/datum/fishing_catch/epic = list()
	var/list/datum/fishing_catch/rare = list()
	var/list/datum/fishing_catch/common = list()
	var/list/datum/fishing_catch/junk = list()

/datum/fishing_loot/proc/pick_rarity(luck, power)
	return common

/datum/fishing_loot/space
	richness = 100

	common = list(
		new /datum/fishing_catch/carp() = 50,
		new /datum/fishing_catch/junk() = 25
	)

/datum/fishing_loot/lava
	richness = 0

/datum/fishing_loot/water
	richness = 0

/datum/fishing_loot/none
	richness = 0

//The global list which contains the loot tables is in 'fishing.dm'
