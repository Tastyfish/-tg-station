/datum/browser/ajax
	var/const/br = "<br>"
	var/list/mob/users

/datum/browser/ajax/New(nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null)
	..(null, nwindow_id, ntitle, nwidth, nheight, nref)

	users = new()
	add_script("sscomm", 'html/browser/sscomm.js') // this is the dynamic element modification script common to all ajax-y UIs

/datum/browser/ajax/open(mob/user, ncontent)
	for(var/U in users)
		if(U == user)
			return 0

	set_content(ncontent)

	src.user = user // work-around to work with normal browser datum
	..()

	users += user
	return 1

/datum/browser/ajax/close(mob/user)
	user << browse(null, "window=[window_id]")
	users -= user

///////////////////////////////////////
// Various messages to send to client
///////////////////////////////////////

// send JS a message
/datum/browser/ajax/proc/send_message(fn, params)
	for(var/user in users)
		user << output(params, "[window_id].browser:[fn]")

// Set a DOM object's css class
// id is that of the html object
/datum/browser/ajax/proc/set_class(id, class)
	send_message("ssSetClass", list2params(list(id, class)))

// Set a DOM object's inner content
// id is that of the html object
/datum/browser/ajax/proc/set_inner_content(id, content)
	send_message("ssSetContent", list2params(list(id, content)))

/datum/browser/ajax/proc/set_width(id, w)
	send_message("ssSetWidth", list2params(list(id, w)))

/datum/browser/ajax/proc/set_height(id, h)
	send_message("ssSetHeight", list2params(list(id, h)))

/datum/browser/ajax/proc/set_visible(id, v)
	send_message("ssSetVisible", list2params(list(id, v)))

// Widget-specifc

// value is 1 or 0
/datum/browser/ajax/proc/select_checkbox(id, value)
	set_class(id, value ? "linkOn" : "linkOff")

// list id of selected item, then all of the other items
/datum/browser/ajax/proc/select_radiobox(selected, ...)
	set_class(selected, "linkOn")
	for(var/id in args - selected)
		set_class(id, "")

/datum/browser/ajax/proc/set_progress(id, value, max)
	set_width(id, num2text(value / max * 100)+"%")

///////////////////////////////////////
// HTML chunk factories!
///////////////////////////////////////

/datum/browser/ajax/proc/create_label(id, content, class = "")
	return "<span id='[id]'[class ? " class='[class]'" : ""]>[content]</span>"

/datum/browser/ajax/proc/create_button(id, label, class="", link=null)
	if(!link)
		link = "[id]=1"
	return "<a id='[id]' href='?src=\ref[ref];[link]'[class ? " class='[class]'" : ""]>[label]</a>"

/datum/browser/ajax/proc/create_checkbox(id, label, checked)
	return "<a id='[id]' href='?src=\ref[ref];[id]=1' class='[checked ? "linkOn" : ""]'>[label]</a>"

// list of radio boxes
/datum/browser/ajax/proc/create_radiobox(list/items, selected)
	var/dat = ""

	for(var/id in items)
		var/label = items[id]
		dat += create_checkbox(id, label, selected == id)

	return dat

// as in - - - 1200 KPA + + +
/datum/browser/ajax/proc/create_spinner(id, value, unit, list/steps)
	var/dat = ""

	for(var/i = steps.len, i >= 1, i--)
		dat += " <a href='?src=\ref[ref];[id]=-[steps[i]]'>-</a>"

	dat += "<span id='[id]'>[value]</span> [unit]"

	for(var/S in steps)
		dat += " <a href='?src=\ref[ref];[id]=[S]'>+</a>"

	return dat

// notifies object in realtime of changes
// THIS IS ONLY A SILLY THING TO SHOW OFF SKILZ
// because undoubtedly, this is horribly inefficient
/datum/browser/ajax/proc/create_livetext(id, value)
	var/dat = ""

	dat += "<textarea id='[id]' rows=3 cols=20 "
	dat += "onkeyup=\"javascript:window.location.href='?src=\ref[ref];[id]='+document.getElementById('[id]').innerHTML;\""
	dat += ">[value]</textarea>"

	return dat

// fillClass indicates extra subclass of progressFill, ie good, average, bad
/datum/browser/ajax/proc/create_progress(id, value, max = 100, fillClass = "")
	return "<div class='progressBar'><div id='[id]' style='width: [value / max * 100]%;' class='progressFill [fillClass]'></div></div>"

