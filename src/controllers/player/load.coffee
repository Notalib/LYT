# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.load extends LYT.player.command

  constructor: (el, @src) ->
    super el
    if @src is @status().src
      @resolve()
    else
      @_run =>
        @loadAttemptCount = 0
        @el.jPlayer 'setMedia', {mp3: @src}
        @el.jPlayer 'load'

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
      if @status().src is @src
        if event.jPlayer.status.duration is 0 or isNaN event.jPlayer.status.duration
          if ++@loadAttemptCount <= 5 # FIXME: configurable defaults
            @el.jPlayer 'setMedia', {mp3: @src}
          # else give up - we pretend that we have got the duration
        else
          @notify event.jPlayer.status
      # else: nothing to do because this event is from the wrong file

   canplaythrough: (event) =>
     @resolve event.jPlayer.status
