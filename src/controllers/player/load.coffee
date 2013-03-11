# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.load extends LYT.player.command

  constructor: (el, @src) ->
    super el
    if @src is @status().src
      @resolve()
    else
      run = =>
        @_run =>
          @loadAttemptCount = 0
          @el.jPlayer 'setMedia', {mp3: @src}
          @el.jPlayer 'load'
          # Ensure that this command resolves as soon as readyState is non-zero
          startHandler = =>
            status = @status()
            if status.src is @src and status.readyState > 0
              @resolve status
          startInterval = setInterval startHandler, 200
          timeoutHandler = =>
            if @state() is 'pending'
              log.message 'load timeout - retry'
              @el.jPlayer 'setMedia', {mp3: @src}
              @el.jPlayer 'load'
          timeout = setTimeout timeoutHandler, 2000
          @always =>
            log.message 'load finished'
            clearInterval startInterval
      if not @hasPlayed()
        silentplay = new LYT.player.command.silentplay @el
        silentplay.always run
      else
        run()

  hasPlayed: (boolean) ->
    if boolean?
      @el.data 'LYT-hasPlayed', boolean
    else
      @el.data 'LYT-hasPlayed'

  handles: ->
    metadataHandler = (event) =>
      # Bugs in IOS 5 and IOS 6 forces us to keep trying to load the media
      # file until we get a valid duration.
      # At this point we get the following sporadic errors
      # IOS 5: duration is not a number.
      # IOS 6: duration is set to zero on non-zero length audio streams
      # Caveat emptor: for this reason, the player will wrongly assume that
      # there is an error if the player is ever asked to play a zero length
      # audio stream.
      log.message 'Player command: load: loadedmetadata'
      if @status().src is @src
        if event.jPlayer.status.duration is 0 or isNaN event.jPlayer.status.duration
          if ++@loadAttemptCount <= 5 # FIXME: configurable defaults
            @el.jPlayer 'setMedia', {mp3: @src}
          # else give up - we pretend that we have got the duration
        else
          @notify event.jPlayer.status
      # else: nothing to do because this event is from the wrong file

    loadedmetadata: metadataHandler
    progress: metadataHandler
    
    canplaythrough: (event) => @resolve event.jPlayer.status
