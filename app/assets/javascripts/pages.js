function onVelocityChange(layer) {
    var value = $('#speed_range').val();
    $('#speed').text(value);
    $.post('velocity', {velocity: value, layer: layer});
}

function onAccelerationChange(layer) {
    var value = $('#acceleration_range').val();
    $('#acceleration').text(value);
    $.post('acceleration', {acceleration: value, layer: layer});
}

function onRun() {
    $('#run').toggle();
    $('#stop').toggle();
    $.post('run', {});
}

function onStop() {
    $('#run').toggle();
    $('#stop').toggle();
    $.post('stop', {});
}