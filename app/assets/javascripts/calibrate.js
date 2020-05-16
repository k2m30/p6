let updateState = () => {
    fetch('/state').then(r => r.json()).then(r => {
        //{"left_deg":2933,"right_deg":3333,"running":false,"left_mm":30.0,"right_mm":40.0,"x":26.4,"y":24.6,"current_trajectory":0}
        $('#left-deg').text(r.left_deg);
        $('#right-deg').text(r.right_deg);
        $('#left-mm').text(r.left_mm);
        $('#right-mm').text(r.right_mm);
        $('#x').text(r.x);
        $('#y').text(r.y);
        $('#running').text(r.running);

        if (r.running) {
            document.querySelectorAll('a.btn').forEach(e => e.classList.add('disabled'));
            document.querySelectorAll('input').forEach(e => e.setAttribute('disabled', ''));
        } else {
            document.querySelectorAll('a.btn').forEach(e => e.classList.remove('disabled'));
            document.querySelectorAll('input').forEach(e => e.removeAttribute('disabled'));
        }
    });
};

let manualControl = (motor, direction, distance) => {
    fetch(`/manual?motor=${motor}&direction=${direction}&distance=${distance}`, {
        method: 'POST'
    });
};

setInterval(updateState, 1000);

$(() => {
    $("#down-left").click(() => {
        manualControl('left', 'down', $("#value-left")[0].value)
    });
    $("#up-left").click(() => {
        manualControl('left', 'up', $("#value-left")[0].value)
    });
    $("#down-right").click(() => {
        manualControl('right', 'down', $("#value-right")[0].value)
    });
    $("#up-right").click(() => {
        manualControl('right', 'up', $("#value-right")[0].value)
    });
});