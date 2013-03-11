# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.silentplay extends LYT.player.command

  constructor: (el) ->
    super el
    @_run =>
      @el.jPlayer 'setMedia', {mp3: 'audio/silence.mp3'}
      @el.jPlayer 'load'
      @el.jPlayer 'play'
      $(document).one 'click', => @el.jPlayer 'play'

  handles: ->
    metadataHandler = (event) =>
      log.message 'Player command: silentplay: metadatahandler'
      if event.jPlayer.status.duration > 0
        @el.jPlayer 'pause'
        @resolve event.jPlayer.status

    timeupdate: metadataHandler
    loadedmetadata: metadataHandler
    progress: metadataHandler
    pause: (event) => @resolve event.jPlayer.status
