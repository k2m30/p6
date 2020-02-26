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
    $('#start-from-block').hide();
    $.post('run', {});
    poll(300);
}

function poll(interval) {
    setTimeout(function () {
        $.ajax({
            url: "/state",
            type: "GET",
            success: function (data) {
                console.log(data);
                update_current_point(data);
                update_svg(data.current_trajectory);
                if (data.running) {
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

function update_current_point(data) {
    var p = $('#current')[0];

    p.setAttribute("cx", data.x);
    p.setAttribute("cy", data.y);
    $("#x")[0].textContent = data.x.toFixed(0);
    $("#y")[0].textContent = data.y.toFixed(0);
    $("#current_trajectory")[0].textContent = data.current_trajectory;
    $("#start-from")[0].textContent = data.current_trajectory;
}

function onStop() {
    $('#run').show();
    $('#stop').hide();
    $('#start-from-block').show();
    $.post('stop', {});
}

function update_svg(data) {
    // console.log(data);
    var trajectory = parseInt(data);
    console.log(trajectory);

    if (trajectory > 0) {
        $('#path_' + (trajectory - 1).toString())[0].classList.add('invisible');
        $('#move_to_' + (trajectory - 1).toString())[0].classList.add('invisible');
    }

    $('#path_' + trajectory)[0].classList.remove('invisible');
    $('#move_to_' + trajectory)[0].classList.remove('invisible');

}

function update_start_point(data) {
    first_point = $('path#path_' + data)[0].attributes['d'].value.split(/ [LC]/)[0];
    cx = first_point.split(',')[0].split('M')[1];
    cy = first_point.split(',')[1];
    circle = $('circle')[1];
    circle.setAttribute('cx', cx);
    circle.setAttribute('cy', cy);
}

function update_trajectory(url) {
    $.post(url, {}, function (data) {
        console.log(data);
        $('#start-from').text(data);
        update_svg(data);
        update_start_point(data);
    })
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
        $('#path_' + i)[0].classList.add('invisible');
        $('#move_to_' + i)[0].classList.add('invisible');
    }
    update_start_point(start_from);
    poll(1000);
});
