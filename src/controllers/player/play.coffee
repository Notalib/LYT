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
      unless audio.src.indexOf('silence.mp3') is -1
        log.message "play: progressHandler: silentplay", stack
        return

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
      if not @$audio.data( 'hasPlayed' ) or @browser.IE
        # In some browser like IE, setting playbackRate while paused doesn't work, playback will be at
        # speed 1 even though the playbackRate attribute is set to the correct value.
        # This forces these browsers to update the value in the timeupdate event.
        log.message "Command play: playing: hasPlayed: #{@$audio.data( 'hasPlayed' )} or IE: #{@browser.IE}"
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
      if isNaN( @audio.currentTime )
        log.messsage "Command play: timeupdate currentTime: #{@audio.currentTime} isNaN"
      else
        ## msn: This is ugly.
        # Sometimes IE will play an audio-file at playbackRate == 1, but have playbackRate
        # set to another value.
        #
        # Unfortunately if you set the playbackRate to the same value nothing happens.
        # Therfor if playbackRate is the same value subtract 0.0001 from the wanted value and
        # update the value again in the next timeupdate-event. Alternating between the two values.

        if @audio.playbackRate is @playbackRate
          ## Don't do this on Safari on OSX, IE11, Edge, since it pauses
          # the sound a for a second after playbackRate is altered
          #
          # TODO: Find a better way to do this, so we don't have to rely on browser sniffing
          # TODO: We'll want to do this as a whitelist instead of a blacklist!
          unless @browser.Safari or @browser.IOS9ORBIGGER or @browser.IE11 or @browser.Edge
            @audio.playbackRate = @playbackRate - 0.0001
        else
          if Math.abs( @playbackRate - @audio.playbackRate ) > 0.1
            log.message "Command play: timeupdate: playbackRate changed from #{@audio.playbackRate} to #{@playbackRate}"
          @audio.playbackRate = @playbackRate

  setPlaybackRate: (playbackRate = 1) =>
    @playbackRate = playbackRate

    if not Modernizr.playbackrate and Modernizr.playbackratelive
      # Workaround for IOS6+ that doesn't alter the perceived playback rate
      # before starting and stopping the audio (issue #480)
      if @playing
        log.message "Command play: Stop -> set playbackRate -> resume"
        @audio.pause()
        @audio.playbackRate = @playbackRate
        @audio.play()
        return

    if @browser.IE11
      log.message "This is IE11, set @audio.playbackRate = 1 and @audio.defaultPlaybackRate = #{@playbackRate}"
      # Force update value in IE11. We can't use the workaround in timeuptime for IE11 because on Win8 IE11
      # paused for about a second, therefor set the value to 1 because this forces IE to update the value even
      # if it's the same.
      try
        @audio.playbackRate = 1
        @audio.defaultPlaybackRate = @playbackRate
      catch exp
        log.error "@browser.IE11: ", exp
    else
      log.message "This isn't IE11, set @audio.playbackRate = @audio.defaultPlaybackRate = #{@playbackRate}"
      @audio.defaultPlaybackRate = @audio.playbackRate = @playbackRate

  browser: do ->
    ## We've had to use browser sniffing due to issues with playbackRate
    # on certain browsers and "browsers", this is ugly I know but we
    # need to do this for now.
    userAgent = navigator.userAgent

    Edge   = !!(userAgent.match /Edge/i)
    IE9    = !!(userAgent.match /MSIE 9\.0/i)
    IE10   = !!(userAgent.match /MSIE 10\.0/i)
    IE11   = !!(userAgent.match( /Trident\/7\.0/i ) and userAgent.match( /rv:11\.0/i ))
    IE     = !!(IE9 or IE10 or IE11)
    Safari = !!(userAgent.match( /Safari/i ) and userAgent.match( /Macintosh/i ) and not userAgent.match( /iPhone|iPad|iPod|Chrome/i ))
    IOS9   = !!(userAgent.match( /iPhone|iPad|iPod/ ) and userAgent.match( /OS 9/ ))
    IOS10  = !!(userAgent.match( /iPhone|iPad|iPod/ ) and userAgent.match( /OS 10/ ))

    IOS9ORBIGGER =
      if !!(userAgent.match( /iPhone|iPad|iPod/ ))
        (parseInt userAgent.match( /OS (\d+)/ )?[1], 10) >= 9
      else
        false

    Edge:   Edge
    IE:     IE
    IE9:    IE9
    IE10:   IE10
    IE11:   IE11
    Safari: Safari
    IOS9:   IOS9
    IOS10:   IOS10

