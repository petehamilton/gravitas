function inspect( obj ) {
  if (typeof obj === "undefined") {
      return "undefined";
  }
  var _props = [];

    for ( var i in obj ) {
        _props.push( i + " : " + obj[i] );
    }
    return " {" + _props.join( ",<br>" ) + "} ";
}

var dlog = function(t, o) {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  setTimeout((__bind(function() {
    return $('#dev_log').empty();
  }, this)), 4000);
  return $('#dev_log').append($('<p>').text(t + " " + JSON.stringify(o)));
};

function touchStart(e) {
  var targetEvent =  e.targetTouches.item(0);

  p = $('#paper').position();
  px = p.left;
  py = p.top;

  var x = targetEvent.clientX - px;
  var y = targetEvent.clientY - py;

  window.touchstart(x, y);

  e.preventDefault();
  return false;
}

function touchEnd(e) {
  window.touchend();

  e.preventDefault();
  return false;
}

function touchMove(e) {
  var targetEvent =  e.targetTouches.item(0);

  p = $('#paper').position();
  px = p.left;
  py = p.top;

  var x = targetEvent.clientX - px;
  var y = targetEvent.clientY - py;

  window.touchmove(x, y);

  e.preventDefault();
  return false;
}
