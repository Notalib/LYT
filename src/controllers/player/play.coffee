# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.play extends LYT.player.command

  constructor: (el, @playbackRate) ->
    super el
    waitForPause = if @status().paused
      jQuery.Deferred().resolve()
    else
      @el.jPlayer 'pause'
      new LYT.player.command.wait @el, (deferred, eventName, status) => deferred.resolve() if status.paused
    waitForPause.done =>
      # IOS6 will not change the playbackRate unless you pause playback, after
      # setting the playbackRate. And then we can obtain the new playbackRate and continue
      # FIXME: This makes safari desktop version fail
      @setPlaybackRate @playbackRate
      # We attach event event handlers here because the player is ready to start playing
      @_run =>
        @el.jPlayer 'play'
        # Added for Safari desktop version - will not work unless rate is unset
        # and set again
        @setPlaybackRate null
        @setPlaybackRate @playbackRate

  cancel: ->
    super()
    @el.jPlayer 'pause'

  _stop: (event) ->
    method = if @canceled then @reject else @resolve
    method.apply this, event.jPlayer.status

  handles: ->
    playing: (event) =>
      @playing = true
      @notify event.jPlayer.status

    timeupdate: (event) =>
      if @playing and event.jPlayer.status.paused
        @_stop event
      else
        @notify event.jPlayer.status

    ended: (event) => @_stop event

    pause: (event) => @_stop event

  setPlaybackRate: (rate) ->
    audio = @el.data('jPlayer').htmlElement.audio
    audio.playbackRate = rate
    audio.defaultplaybackRate = rate
