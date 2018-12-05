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

function update_svg(data) {
    // console.log(data);
    var trajectory = parseInt(data);


    if (trajectory > 0) {
        $('#spath_' + (trajectory - 1).toString())[0].classList.add('invisible');
        $('#move_to_' + (trajectory - 1).toString())[0].classList.add('invisible');
    }

    $('#spath_' + trajectory)[0].classList.remove('invisible');
    $('#move_to_' + trajectory)[0].classList.remove('invisible');

}

function update_start_point(data) {
    first_point = $('path#spath_' + data)[0].attributes['d'].value.split(' L')[0];
    cx = first_point.split(',')[0].split('M')[1];
    cy = first_point.split(',')[1];
    circle = $('circle')[1];
    circle.setAttribute('cx', cx);
    circle.setAttribute('cy', cy);
}

function update_trajectory(url) {
    var trajectories_count = $('path.s').length;
    var start_from = parseInt($('#start-from')[0].text);
    // console.log(start_from);
    if (start_from < trajectories_count) {
        $.post(url, {}, function (data) {
            $('#start-from').text(data);
            update_svg(data);
            update_start_point(data);
        })
    }
}

$(function () {
    var canvas_size_x = parseInt($('#canvas_size_x')[0].textContent);
    var initial_x = parseInt($('#initial_x')[0].textContent);
    var initial_y = parseInt($('#initial_y')[0].textContent);
    var svg_x = parseInt($('svg')[0].attributes[7].value.split(', ')[2]);
    if (canvas_size_x <= initial_x || canvas_size_x <= initial_y || svg_x <= initial_y || svg_x <= initial_x || canvas_size_x * 1.2 > initial_x + initial_y || svg_x * 1.2 > initial_x + initial_y) {
        $('#svg_size').text(svg_x);
        $('#alert').show();
    }
    var start_from = parseInt($('#start-from')[0].text);

    for (var i = 0; i < start_from; i++) {
        $('#spath_' + i)[0].classList.add('invisible');
        $('#move_to_' + i)[0].classList.add('invisible');
    }
    update_start_point(start_from);
});
