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
    $('#run').hide();
    $('#stop').show();
    $.post('run', {});
    poll(1000);
}

function poll(interval) {
    setTimeout(function () {
        $.ajax({
            url: "/running",
            type: "GET",
            success: function (data) {
                console.log(data);
                if (data) {
                    poll(interval);
                } else {
                    onStop();
                }
            },
            dataType: "json",
            timeout: 2000
        })
    }, interval);
}

function onStop() {
    $('#run').show();
    $('#stop').hide();
    $.post('stop', {});
}