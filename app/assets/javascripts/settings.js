function validate(evt) {
    var theEvent = evt || window.event;

    // Handle paste
    if (theEvent.type === 'paste') {
        key = event.clipboardData.getData('text/plain');
    } else {
        // Handle key press
        var key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode(key);
    }
    var regex = /\d|\.|-/;
    if( !regex.test(key) ) {
        theEvent.returnValue = false;
        if(theEvent.preventDefault) theEvent.preventDefault();
    } else {
    }
    var id = theEvent.srcElement.id;
    console.log(theEvent.srcElement.id);
    var value = $('#' + theEvent.srcElement.id).val();
    update(id, value)

}

function leave(evt){
    var theEvent = evt || window.event;
    var id = theEvent.srcElement.id;
    var value = $('#' + theEvent.srcElement.id).val();
    update(id, value)
}

function update(key, value) {
    console.log(key);
    console.log(value);
    $.post('update_config', {key: key, value: value});
}
