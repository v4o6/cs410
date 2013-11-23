var image_root = '../img/';
var interval = null;
var delay = 800;
var FrameStates = new Array();
var Frames = new Array();

function ChangeView(obj) {
	var view = document.getElementById("view");
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
		table.innerHTML += '<tr><td class="detail">Status</td><td>' + FrameStates[index-1][i].status + '</td></tr>';
		table.innerHTML += '<tr><td class="detail">Method</td><td>' + FrameStates[index-1][i].method + '</td></tr>';
		table.innerHTML += '<tr><td class="detail">Caller</td><td>' + FrameStates[index-1][i].caller + '</td></tr>';
		table.innerHTML += '<tr><td class="detail">Enter/Exit</td><td>' + FrameStates[index-1][i].enterExit + '</td></tr>';
		table.innerHTML += '<tr><td class="detail">Start Routine</td><td>' + FrameStates[index-1][i].fnName + '</td></tr>';
		table.innerHTML += '<tr><td class="detail last">Arguments</td><td>' + FrameStates[index-1][i].args + '</td></tr>';
	}

	obj.parentNode.className = "active";
	document.getElementById('title').innerHTML = FrameStates[index-1][0].method;
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

	//alert(active.offsetLeft + ' ' + active.offsetTop);
	document.getElementById('frame-select').scrollTop += 20;
}

function Timer(cmd) {
	
	callback = function() {
		StepFrame('next');
	};
	switch(cmd) {
		case 'start':
			if (!interval) {
				interval = window.setInterval(callback, delay);
				document.getElementById('play').className = 'btn active';
				document.getElementById('stop').className = 'btn';
			}
			break;
		case 'stop':
			if (interval) {
				window.clearInterval(interval);
				interval = null;
				document.getElementById('play').className = 'btn';
				document.getElementById('stop').className = 'btn active';
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

function LoadState(index, id, type, status, fnName, caller, enterExit, method, args) {
	if (typeof FrameStates[index] == 'undefined')
		FrameStates[index] = new Array();
	FrameStates[index].push({index:index, id:id, type:type, status:status, method:method, caller:caller, enterExit:enterExit, fnName:fnName, args:args});
}

function LoadStateView(index, filename) {
	if (typeof Frames[index] == "undefined")
		Frames.push(filename);
}
