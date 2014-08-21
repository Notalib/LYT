# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Play a silent audio file                                                    #
# ########################################################################### #

# This command is used to bypass firstplay issues on IOS.
# It will start playing a silent audio file and stop as soon as playback has
# started. Using this command to play on first user interaction will clear the
# browsers firstplay flag.

class LYT.player.command.silentplay extends LYT.player.command

  constructor: (el) ->
    super el
    @_run =>
      @el.jPlayer 'setMedia', {mp3: 'audio/silence.mp3'}
      @el.jPlayer 'play'

  handles: ->
    metadataHandler = (event) =>
      log.message 'Player command: silentplay: metadatahandler'
      if event.jPlayer.status.duration > 0
        @el.jPlayer 'pause'

    timeupdate: metadataHandler
    loadedmetadata: metadataHandler
    progress: metadataHandler
    pause: (event) => @resolve event.jPlayer.status
