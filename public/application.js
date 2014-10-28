$(document).ready(function() {

  player_hit();
  player_stay();
  dealer_hit();
  dealer_stay();
});

function player_hit() {
    $(document).on('click','#player_hit input', function() {
      $.ajax({
        type: 'POST', 
        url: '/player/hit'
      }).done(function(msg) {
        $('#game').replaceWith(msg)
      });
      return false;
  });
}

function player_stay() {
    $(document).on('click','#player_stay input', function() {
    $.ajax({
      type: 'POST', 
      url: '/player/stay'
    }).done(function(msg) {
      $('#game').replaceWith(msg)
    });
    return false;
  });
}

function dealer_hit() {
    $(document).on('click','#dealer_hit input', function() {
    $.ajax({
      type: 'POST', 
      url: '/dealer/hit'
    }).done(function(msg) {
      $('#game').replaceWith(msg)
    });
    return false;
  });
}

function dealer_stay() {
    $(document).on('click','#dealer_stay input', function() {
    $.ajax({
      type: 'GET', 
      url: '/result'
    }).done(function(msg) {
      $('#game').replaceWith(msg)
    });
    return false;
  });
}