function paint(velocity) { // mm/sec

    var delay = 0;
    var paths = document.querySelectorAll('#svg path');
    var transition = null;
    var time;
    var l;
    for (var i = 0; i < paths.length; i++) {
        l = paths[i].getTotalLength();
        paths[i].style.transition = paths[i].style.WebkitTransition = 'none';
        paths[i].style.strokeDasharray = l + ' ' + l;
        paths[i].style.strokeDashoffset = l;
        paths[i].style.markerStart = 'none';
        paths[i].style.markerEnd = 'none';
        if (paths[i].className.baseVal == "move_to") {
            time = l / velocity / 10;
        } else {
            time = l / velocity;
        }
        transition = 'stroke-dashoffset ' + time + 's ease-in-out ' + delay + 's';
        delay += time;
        paths[i].getBoundingClientRect();
        paths[i].style.transition = paths[i].style.WebkitTransition = transition;
        paths[i].style.strokeDashoffset = '0';
    }
};
