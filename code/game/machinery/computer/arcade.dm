/obj/machinery/computer/arcade
	name = "arcade machine"
	desc = "Does not support Pin ball."
	icon = 'icons/obj/computer.dmi'
	icon_state = "arcade"
	circuit = "/obj/item/weapon/circuitboard/arcade"
	var/enemy_name = "Space Villian"
	var/temp = "Winners Don't Use Spacedrugs" //Temporary message, for attack messages, etc
	var/player_hp = 30 //Player health/attack points
	var/player_mp = 10
	var/enemy_hp = 45 //Enemy health/attack points
	var/enemy_mp = 20
	var/gameover = 0
	var/blocked = 0 //Player cannot attack/heal while set
	var/list/prizes = list(	/obj/item/weapon/storage/box/snappops			= 2,
							/obj/item/toy/blink								= 2,
							/obj/item/clothing/under/syndicate/tacticool	= 2,
							/obj/item/toy/sword								= 2,
							/obj/item/toy/gun								= 2,
							/obj/item/toy/crossbow							= 2,
							/obj/item/clothing/suit/syndicatefake			= 2,
							/obj/item/weapon/storage/fancy/crayons			= 2,
							/obj/item/toy/spinningtoy						= 2,
							/obj/item/toy/prize/ripley						= 1,
							/obj/item/toy/prize/fireripley					= 1,
							/obj/item/toy/prize/deathripley					= 1,
							/obj/item/toy/prize/gygax						= 1,
							/obj/item/toy/prize/durand						= 1,
							/obj/item/toy/prize/honk						= 1,
							/obj/item/toy/prize/marauder					= 1,
							/obj/item/toy/prize/seraph						= 1,
							/obj/item/toy/prize/mauler						= 1,
							/obj/item/toy/prize/odysseus					= 1,
							/obj/item/toy/prize/phazon						= 1
							)
	var/datum/browser/ajax/browser

/obj/machinery/computer/arcade
	var/turtle = 0

/obj/machinery/computer/arcade/New()
	..()
	var/name_action
	var/name_part1
	var/name_part2

	name_action = pick("Defeat ", "Annihilate ", "Save ", "Strike ", "Stop ", "Destroy ", "Robust ", "Romance ", "Pwn ", "Own ")

	name_part1 = pick("the Automatic ", "Farmer ", "Lord ", "Professor ", "the Cuban ", "the Evil ", "the Dread King ", "the Space ", "Lord ", "the Great ", "Duke ", "General ")
	name_part2 = pick("Melonoid", "Murdertron", "Sorcerer", "Ruin", "Jeff", "Ectoplasm", "Crushulon", "Uhangoid", "Vhakoid", "Peteoid", "slime", "Griefer", "ERPer", "Lizard Man", "Unicorn")

	src.enemy_name = replacetext((name_part1 + name_part2), "the ", "")
	src.name = (name_action + name_part1 + name_part2)


/obj/machinery/computer/arcade/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/arcade/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/arcade/attack_hand(mob/user as mob)
	if(..() || user.machine == src)
		return

	user.set_machine(src)

	if(!browser)
		browser = new("arcade", "Space Villian 3000", nref=src)
		browser.add_stylesheet("arcade", 'html/browser/arcade.css')

	var/dat = "<div class='screen'>"
	dat += "<div class='enemybar' id='enemy'><b>[browser.create_label("e_name", enemy_name)]</b><br>Health: [browser.create_label("e_hp", enemy_hp)]</div>"
	dat += "<div class='status' id='temp'>[temp]</div>"
	dat += "<div class='selfbar' id='player'><b>Hero</b><br>Health: [browser.create_label("p_hp", player_hp)]<br>Magic: [browser.create_label("p_mp", player_mp)]</div>"

	dat += "<div class='actions'>"

	if (src.gameover)
		dat += browser.create_button("newgame", "New Game", "recharge")
	else
		dat += browser.create_button("attack", "Attack", "attack")
		dat += browser.create_button("heal", "Heal", "heal")
		dat += browser.create_button("recharge", "Recharge", "recharge")

	dat += "</div></div>"

	browser.open(user, dat)
	return

/obj/machinery/computer/arcade/proc/set_enemy_name(value)
	enemy_name = value
	if(browser)
		browser.set_inner_content("e_name", value)

/obj/machinery/computer/arcade/proc/set_player_hp(value)
	player_hp = value
	if(browser)
		browser.set_inner_content("p_hp", value)

/obj/machinery/computer/arcade/proc/hurt_player(amt)
	set_player_hp(player_hp - amt)
	flash_player()

/obj/machinery/computer/arcade/proc/set_player_mp(value)
	player_mp = value
	if(browser)
		browser.set_inner_content("p_mp", value)

/obj/machinery/computer/arcade/proc/set_enemy_hp(value)
	enemy_hp = value
	if(browser)
		browser.set_inner_content("e_hp", value)

/obj/machinery/computer/arcade/proc/hurt_enemy(amt)
	set_enemy_hp(enemy_hp - amt)
	flash_enemy()

/obj/machinery/computer/arcade/proc/set_enemy_mp(value)
	enemy_mp = value

/obj/machinery/computer/arcade/proc/set_temp(value)
	temp = value
	if(browser)
		browser.set_inner_content("temp", value)

/obj/machinery/computer/arcade/proc/flash_player()
	if(!browser)
		return
	spawn(0)
		for(var/i = 1 to 2)
			browser.set_class("player", "selfbar flash")
			sleep(2)
			browser.set_class("player", "selfbar")
			sleep(2)

/obj/machinery/computer/arcade/proc/flash_enemy()
	if(!browser)
		return
	spawn(0)
		for(var/i = 1 to 2)
			browser.set_class("enemy", "enemybar flash")
			sleep(2)
			browser.set_class("enemy", "enemybar")
			sleep(2)

/obj/machinery/computer/arcade/Topic(href, href_list)
	if(..())
		return

	if (!src.blocked && !src.gameover)
		if (href_list["attack"])
			src.blocked = 1
			var/attackamt = rand(2,6)
			set_temp("You attack for [attackamt] damage!")
			if(turtle > 0)
				turtle--
			hurt_enemy(attackamt)

			sleep(10)
			src.arcade_action()

		else if (href_list["heal"])
			src.blocked = 1
			var/pointamt = rand(1,3)
			var/healamt = rand(6,8)
			set_temp("You use [pointamt] magic to heal for [healamt] damage!")
			turtle++

			sleep(10)
			set_player_mp(player_mp - pointamt)
			set_player_hp(player_hp + healamt)
			src.blocked = 1
			src.arcade_action()

		else if (href_list["recharge"])
			src.blocked = 1
			var/chargeamt = rand(4,7)
			set_temp("You regain [chargeamt] points")
			set_player_mp(player_mp + chargeamt)
			if(turtle > 0)
				turtle--

			sleep(10)
			src.arcade_action()

	if (href_list["close"])
		usr.unset_machine()
		usr << browse(null, "window=arcade")

	else if (href_list["newgame"]) //Reset everything
		temp = "New Round"
		set_player_hp(30)
		set_player_mp(10)
		set_enemy_hp(45)
		set_enemy_mp(20)
		gameover = 0
		turtle = 0

		if(emagged)
			src.New()
			emagged = 0

	src.add_fingerprint(usr)
	return

/obj/machinery/computer/arcade/proc/arcade_action()
	if ((src.enemy_mp <= 0) || (src.enemy_hp <= 0))
		if(!gameover)
			src.gameover = 1
			set_temp("[src.enemy_name] has fallen! Rejoice!")

			if(emagged)
				feedback_inc("arcade_win_emagged")
				new /obj/effect/spawner/newbomb/timer/syndicate(src.loc)
				new /obj/item/clothing/head/collectable/petehat(src.loc)
				message_admins("[key_name_admin(usr)] has outbombed Cuban Pete and been awarded a bomb.")
				log_game("[key_name_admin(usr)] has outbombed Cuban Pete and been awarded a bomb.")
				src.New()
				emagged = 0
			else if(!contents.len)
				feedback_inc("arcade_win_normal")
				var/prizeselect = pickweight(prizes)
				new prizeselect(src.loc)

				if(istype(prizeselect, /obj/item/toy/gun)) //Ammo comes with the gun
					new /obj/item/toy/ammo/gun(src.loc)

				else if(istype(prizeselect, /obj/item/clothing/suit/syndicatefake)) //Helmet is part of the suit
					new	/obj/item/clothing/head/syndicatefake(src.loc)

			else
				feedback_inc("arcade_win_normal")
				var/atom/movable/prize = pick(contents)
				prize.loc = src.loc

	else if (emagged && (turtle >= 4))
		var/boomamt = rand(5,10)
		set_temp("[src.enemy_name] throws a bomb, exploding you for [boomamt] damage!")
		hurt_player(boomamt)

	else if ((src.enemy_mp <= 5) && (prob(70)))
		var/stealamt = rand(2,3)
		set_temp("[src.enemy_name] steals [stealamt] of your power!")
		set_player_mp(player_mp - stealamt)

		if (src.player_mp <= 0)
			src.gameover = 1
			sleep(10)
			set_temp("You have been drained! GAME OVER")
			if(emagged)
				feedback_inc("arcade_loss_mana_emagged")
				usr.gib()
			else
				feedback_inc("arcade_loss_mana_normal")

	else if ((src.enemy_hp <= 10) && (src.enemy_mp > 4))
		set_temp("[src.enemy_name] heals for 4 health!")
		set_enemy_hp(enemy_hp + 4)
		set_enemy_mp(enemy_mp - 4)

	else
		var/attackamt = rand(3,6)
		set_temp("[src.enemy_name] attacks for [attackamt] damage!")
		hurt_player(attackamt)

	if ((src.player_mp <= 0) || (src.player_hp <= 0))
		src.gameover = 1
		set_temp("You have been crushed! GAME OVER")
		if(emagged)
			feedback_inc("arcade_loss_hp_emagged")
			usr.gib()
		else
			feedback_inc("arcade_loss_hp_normal")

	src.blocked = 0
	return


/obj/machinery/computer/arcade/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/weapon/card/emag) && !emagged)
		set_temp("If you die in the game, you die for real!")
		set_player_hp(30)
		set_player_mp(10)
		set_enemy_hp(45)
		set_enemy_mp(20)
		gameover = 0
		blocked = 0

		emagged = 1

		set_enemy_name("Cuban Pete")
		name = "Outbomb Cuban Pete"

	else if(istype(I, /obj/item/weapon/screwdriver))
		playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20))
			var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
			var/obj/item/weapon/circuitboard/arcade/M = new /obj/item/weapon/circuitboard/arcade( A )
			for (var/obj/C in src)
				C.loc = src.loc
			A.circuit = M
			A.anchored = 1

			if (src.stat & BROKEN)
				user << "\blue The broken glass falls out."
				new /obj/item/weapon/shard( src.loc )
				A.state = 3
				A.icon_state = "3"
			else
				user << "\blue You disconnect the monitor."
				A.state = 4
				A.icon_state = "4"

			del(src)
/obj/machinery/computer/arcade/emp_act(severity)
	if(stat & (NOPOWER|BROKEN))
		..(severity)
		return
	var/empprize = null
	var/num_of_prizes = 0
	switch(severity)
		if(1)
			num_of_prizes = rand(1,4)
		if(2)
			num_of_prizes = rand(0,2)
	for(num_of_prizes; num_of_prizes > 0; num_of_prizes--)
		empprize = pickweight(prizes)
		new empprize(src.loc)

	..(severity)

/obj/machinery/computer/arcade/on_unset(mob/user)
	browser.close(user)