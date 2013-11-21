var image_root = '../img/';

function ChangeView(obj) {
	// Change image.
	var view = document.getElementById("view");
	var filename = obj.href.substring(obj.href.lastIndexOf('#') + 1);
	view.firstElementChild.src = image_root + filename;
	// Update selector.
	var items = document.getElementById('frame-select').getElementsByTagName('li');
	for (i=0; i<items.length; i++) {
		items[i].className = "";
	}
	obj.parentNode.className = "active";
}

function StepFrame(dir) {
	var list = document.getElementById("frame-select");
	var active = list.getElementsByClassName('active')[0];
	var next = active.nextSibling.nextSibling;
	var prev = active.previousSibling.previousSibling;
	switch(dir) {
		case 'back':
			if (!prev)
				prev = list.lastChild;
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