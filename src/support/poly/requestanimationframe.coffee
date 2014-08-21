window.requestAnimationFrame = 
  window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  (cb) -> 
    setTimeout cb, 1000 / 60

