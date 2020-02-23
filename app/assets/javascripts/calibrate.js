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

setInterval(updateState, 1000);