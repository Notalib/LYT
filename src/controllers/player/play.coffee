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

    @$audio = @el.find('audio')
    @audio = @$audio[0]
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
    canplay: (event) =>
      log.message "Command play: Received canplay event #{@audio.playbackRate} != #{@playbackRate} == #{@audio.playbackRate = @playbackRate}"
      @audio.playbackRate = @playbackRate

    canplaythrough: (event) =>
      log.message "Command play: Received canplaythrough event"

      # If we've applied the "slow" strategy, we cancel it out and start
      # playing if necessary
      if @timer
        clearTimeout @timer
        @firstplay = false
        @el.jPlayer('play') if @audio.paused

    playing: (event) =>
      if @firstplay
        log.message "Command play: playing: return due to firstPlay"
        return
      log.message "Command play: Now playing audio"
      if not @$audio.data( 'hasPlayed' ) or @browser.IE9 or @browser.IE10
        log.message "Command play: playing: hasPlayed: #{@$audio.data( 'hasPlayed' )} or IE9: #{@browser.IE9} or IE10: #{@browser.IE10}"
        @audio.playbackRate = 1
        @$audio.data 'hasPlayed', true

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
        ## msn: This is ugly.
        # Sometimes IE will play an audio-file at playbackRate == 1, but have playbackRate
        # set to another value.
        #
        # Unfortunately if you set the playbackRate to the same value nothing happens.
        # Therfor if playbackRate is the same value subtract 0.0001 from the wanted value and
        # update the value again in the next timeupdate-event. Alternating between the two values.
        if @audio.playbackRate is @playbackRate
          ## Don't do this on Safari on OSX, it mutes for a second or two after we alter the playbackRate
          # TODO: Find a better way to do this, so we don't have to rely on browser sniffing
          unless @browser.Safari or @browser.IE11
            @audio.playbackRate = @playbackRate - 0.0001
        else
          if Math.abs( @playbackRate - @audio.playbackRate ) > 0.1
            log.message "onTimeupdate: playbackRate changed from #{@audio.playbackRate} to #{@playbackRate}"
          @audio.playbackRate = @playbackRate

  setPlaybackRate: (playbackRate = 1) =>
    @playbackRate = playbackRate

    if not Modernizr.playbackrate and Modernizr.playbackratelive
      # Workaround for IOS6 that doesn't alter the perceived playback rate
      # before starting and stopping the audio (issue #480)
      if @playing
        log.message "Command play: Stop -> set playbackRate -> resume"
        @audio.pause()
        @audio.playbackRate = @playbackRate
        @audio.play()
        return

    if @browser.IE11
      log.message "This is IE11, set @audio.playbackRate = 1 and @audio.defaultPlaybackRate = #{@playbackRate}"
      # Force change on IE11 is doesn't, this makes it register change even if paused.
      try
        @audio.playbackRate = 1
        @audio.defaultPlaybackRate = @playbackRate
      catch exp
        log.error "@browser.IE11: ", exp
    else
      log.message "This isn't IE11, set @audio.playbackRate = @audio.defaultPlaybackRate = #{@playbackRate}"
      @audio.defaultPlaybackRate = @audio.playbackRate = @playbackRate

  browser: do ->
    userAgent = navigator.userAgent

    IE9: userAgent.match /MSIE 9\.0/i
    IE10: userAgent.match /MSIE 10\.0/i
    IE11: userAgent.match( /Trident\/7\.0/i ) and userAgent.match( /rv:11\.0/i )
    Safari: userAgent.match( /Safari/i ) and userAgent.match( /Macintosh/i ) and not userAgent.match( /iPhone|iPad|Chrome/i )

