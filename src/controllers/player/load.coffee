# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Load provided audio file                                                    #
# ########################################################################### #

class LYT.player.command.load extends LYT.player.command

  constructor: (el, @src) ->
    super el
    if @src is @status().src
      @resolve()
    else
      @_run =>
        @loadAttemptCount = 0
        @load()

  load: ->
    if ++@loadAttemptCount <= 5 # FIXME: configurable defaults
      @el.jPlayer 'setMedia', {mp3: @src}
      @el.jPlayer 'load'
    else
      # Give up - we pretend that we have got the duration
      @resolve()

  handles: ->
    loadedmetadata: (event) =>
      # Bugs in IOS 5 and IOS 6 forces us to keep trying to load the media
      # file until we get a valid duration.
      # At this point we get the following sporadic errors
      # IOS 5: duration is not a number.
      # IOS 6: duration is set to zero on non-zero length audio streams
      # Caveat emptor: for this reason, the player will wrongly assume that
      # there is an error if the player is ever asked to play a zero length
      # audio stream.
      status = event.jPlayer.status
      log.message "Player command: load: loadedmetadata: duration #{status.duration}"
      if status.src is @src
        if status.duration is 0 or isNaN status.duration
          @load()
        else
          @resolve status
      else
        @reject() # This load command has been superseded by another

