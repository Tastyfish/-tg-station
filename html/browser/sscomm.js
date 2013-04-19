// these are the functions to dynamically change browser elements within byond

function ssSetClass(id, cname) {
	document.getElementById(id).className = cname;
}

function ssSetContent(id, content) {
	document.getElementById(id).innerHTML = content;
}

function ssSetWidth(id, w) {
	document.getElementById(id).style.width = w;
}

function ssSetHeight(id, h) {
	document.getElementById(id).style.height = h;
}

function ssSetVisible(id, v) {
	document.getElementById(id).visible = v ? "visible" : "hidden";
}