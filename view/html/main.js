var image_root = '../img/';
var interval = null;
var delay = 1600;
var FrameStates = new Array();
var Frames = new Array();

function ChangeView(obj,index) {
	var view = document.getElementById("view");
	if (!index)
		var index = obj.href.substring(obj.href.lastIndexOf('#') + 1);
	// Change image.
	filename = Frames[index];
	view.firstElementChild.src = image_root + filename;
	// Update selector.
	var items = document.getElementById('frame-select').getElementsByTagName('li');
	for (i=0; i<items.length; i++) {
		items[i].className = "";
	}	
	// Update details.
	var details = document.getElementById('details');
	var table = details.getElementsByTagName('table')[0];
	table.innerHTML = "";
	for (i=0; i<FrameStates[index-1].length; i++) {
		table.innerHTML += '<tr class="section"><th colspan="2">' + FrameStates[index-1][i].id + '</th></tr>';
		table.innerHTML += '<tr><td class="detail">Type</td><td>' + FrameStates[index-1][i].type + '</td></tr>';
		table.innerHTML += '<tr><td class="detail last">Status</td><td class="last">' + FrameStates[index-1][i].status + '</td></tr>';
	}

	obj.parentNode.className = "active";
}

function StepFrame(dir) {
	var list = document.getElementById("frame-select-list");
	var active = list.getElementsByClassName('active')[0];
	var id = active.firstChild.href.substring(active.firstChild.href.lastIndexOf('#') + 1);
	var next = active.nextSibling;
	var prev = active.previousSibling;
	if (next)
		next = next.nextSibling;
	if (prev)
		prev = prev.previousSibling;
	switch(dir) {
		case 'back':
			if (!prev)
				prev = list.lastChild.previousSibling;
			prev.className = "active";
			var filename = prev.firstChild.src;
			active.className = "";
			ChangeView(prev.firstChild);
			break;					
		case 'next':
			if (!next)
				next = list.firstChild;
			next.className = "active";
			var filename = active.nextSibling.src;
			active.className = "";
			ChangeView(next.firstChild);
			break;
	}
}

function Timer(cmd) {
	
	callback = function() {
		StepFrame('next');
	};
	switch(cmd) {
		case 'start':
			if (!interval) {
				interval = window.setInterval(callback, delay);
			}
			break;
		case 'stop':
			if (interval) {
				window.clearInterval(interval);
				interval = null;
			}
			break;
	}
}

function TimerDelay(obj) {
	e = window.event;
    var keyCode = e.keyCode || e.which;
    if (keyCode != '13')
      return;

	if (0 < obj.value)
		delay = obj.value;
	else
		obj.value = delay;
}

function LoadState(index, id, type, status) {
	if (typeof FrameStates[index] == 'undefined')
		FrameStates[index] = new Array();
	FrameStates[index].push({index:index, id:id, type:type, status:status});
}

function LoadStateView(index, filename) {
	if (typeof Frames[index] == "undefined")
		Frames.push(filename);
}