let updateState = () => {
    fetch('/state').then(r => r.json()).then(r => {
        $('#left').text(r.left);
        $('#right').text(r.right);
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