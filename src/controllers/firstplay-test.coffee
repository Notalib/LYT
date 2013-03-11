# Requires `/controllers/player`  

handler = ->
  el = LYT.player.el
  load = new LYT.player.command.load el, 'audio/music.mp3'
  load.done ->
    console.log 'load done'
    play = new LYT.player.command.play el
    $('.firstPlay-test').css 'color', 'red'

$(document).on 'ready', ->
  $('.firstPlay-test').on 'click', ->
    $this = $(this)
    LYT.player.whenReady ->
      setTimeout handler, $this.attr 'data-delay'

