# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Plays current audio file from current position to the end                   #
# ########################################################################### #

# This command will start playback of the current file at the current position
# and will only resolve once the end of file has been reached.
#
# Calling cancel() will pause playback and cause the command to reject.

class LYT.player.command.play extends LYT.player.command

  constructor: (el) ->
    super el
    @_run => @el.jPlayer 'play'

    @pollTimer = setInterval =>
      audio = @el.data('jPlayer').htmlElement.audio
      @notify currentTime: audio.currentTime, src: audio.src
    , 1000/60

    @audio = @el.find('audio')[0]
    @_run =>
      if @audio.readyState is 4
        # If we've got the canplaythrough event, we just play
        @el.jPlayer 'play'
      else
        # Otherwise we apply a different strategy, by waiting a couple of
        # seconds, but still ensuring responsivenes
        @firstplay = true
        @el.jPlayer 'play'
        @timer = setTimeout(
          =>
            @el.jPlayer 'pause'
            @timer = setTimeout(
              =>
                @firstplay = false
                @el.jPlayer 'play'
              3000
            )
          200
        )

  cancel: ->
    super()
    @pollTimer = clearInterval @pollTimer
    @el.jPlayer 'pause'
    @_stop()

  _stop: (event) ->
    clearInterval @pollTimer if @pollTimer
    method = if @cancelled then @reject else @resolve
    method.apply this, event?.jPlayer.status

  handles: ->
    canplaythrough: (event) =>
      log.message "Command play: Received canplaythrough event"

      # If we've applied the "slow" strategy, we cancel it out and start
      # playing if necessary
      if @timer
        clearTimeout @timer
        @firstplay = false
        @el.jPlayer('play') if @audio.paused

    playing: (event) =>
      @audio.playbackRate = 1

      return if @firstplay
      log.message "Command play: Now playing audio"
      @playing = true
      @notify event.jPlayer.status

    ended: (event) => @_stop event

    pause: (event) =>
      log.message "Command play: paused due to buffering"

    # Learned from our tests http://jsbin.com/yuhakiga
    # The most consistent way to get playbackRate to work in most browser
    # is updating it on every timeupdate-event
    timeupdate: (event) =>
      if not isNaN( @audio.currentTime )
        log.message "onTimeupdate: playbackRate changed from #{@audio.playbackRate} to #{@playbackRate}" if @audio.playbackRate isnt @playbackRate
        @audio.playbackRate = @playbackRate

  setPlaybackRate: (playbackRate = 1) =>
    @playbackRate = playbackRate

    @audio.playbackRate = @playbackRate
