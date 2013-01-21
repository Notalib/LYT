# Requires `/controllers/player`
# -------------------

class LYT.player.seek

  constructor: (player, @url, @offset) ->
    log.message 'Player: command seek: intializing'
    super player
    @url = url
    @offset = offset
    @seekAttemptCount = 0
    load.done (book) => log.message "Player: command seek: seeking to #{@url}, #{offset} done"
    load.fail (book) => log.message "Player: command seek: seeking to #{@url}, #{offset} failed"

  handles:
    loadstart: (event) =>
      LYT.instrumentation.record 'loadstart', event.jPlayer.status
      log.message "Player: command seek: loadstart: seekAttemptCount: #{@seekAttemptCount}"
#      LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0
      
    pause: (event) =>
      LYT.instrumentation.record 'pause', event.jPlayer.status
      log.message "Player: command seek: event pause"
#      LYT.render.setPlayerButtonFocus 'play'
#      LYT.loader.close

    seeked: (event) =>
#      # FIXME: issue #459 HACK remove spinner no matter what
#      LYT.loader.close 'metadata'
      LYT.instrumentation.record 'seeked', event.jPlayer.status
      if -0.1 < @offset - event.jPlayer.status.currentTime < 0.1
        this.resolve()
      else
        if ++@seekAttemptCount < 3
          @player.el.jPlayer.pause @offset
        else
          this.reject 'Player: command seek: failed to seek after reaching attempt limit'
        
    loadedmetadata: (event) =>
      LYT.instrumentation.record 'loadedmetadata', event.jPlayer.status
      log.message "Player: loadedmetadata: playAttemptCount: #{@playAttemptCount}, firstPlay: #{@firstPlay}, paused: #{@getStatus().paused}"
      LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and @firstPlay
      # Bugs in IOS 5 and IOS 6 forces us to keep trying to load the media
      # file until we get a valid duration.
      # At this point we get the following sporadic errors
      # IOS 5: duration is not a number.
      # IOS 6: duration is set to zero on non-zero length audio streams
      # Caveat emptor: for this reason, the player will wrongly assume that
      # there is an error if the player is ever asked to play a zero length
      # audio stream.
      if @getStatus().src == @currentAudio
        if event.jPlayer.status.duration == 0 or isNaN event.jPlayer.status.duration
          if @playAttemptCount <= LYT.config.player.playAttemptLimit
            @player.el.jPlayer 'setMedia', {mp3: @currentAudio}
            @playAttemptCount = @playAttemptCount + 1
            log.message "Player: loadedmetadata, play attempts: #{@playAttemptCount}"
            return
          # else: give up - we pretend that we have got the duration
        @playAttemptCount = 0
      # else: nothing to do because we are playing the wrong file
    
    canplay: (event) =>
      LYT.instrumentation.record 'canplay', event.jPlayer.status
      log.message "Player: event canplay: paused: #{@getStatus().paused}"

    canplaythrough: (event) =>
      LYT.instrumentation.record 'canplaythrough', event.jPlayer.status
      log.message "Player: event canplaythrough: nextOffset: #{@nextOffset}, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
      if @nextOffset?
        # XXX: Comment from issue-275:
        # We aren't using @pause here, since it will make the player emit a seek event
        # which will in turn clear the metadata loader.
        action = if @playing then 'play' else 'pause'
        log.message "Player: event canplaythrough: #{action}, offset #{@nextOffset}"
        @player.el.jPlayer action, @nextOffset
        @currentOffset = @nextOffset
        @setPlayBackRate()
        log.message "Player: event canplaythrough: currentTime: #{@getStatus().currentTime}"
      @firstPlay = false
      # We are ready to play now, so remove the loading message, if any
      LYT.loader.close('metadata')
    
    ____

  run: ->
    log.message "Player: command seek: seeking to segment #{url}, offset: #{offset}"
    
#    if not url and book.lastmark?
#      url    = book.lastmark.URI
#      offset = LYT.utils.parseOffset book.lastmark?.timeOffset
#      log.message "Player: resuming from lastmark #{url}, offset #{offset}"
#

    promise = @book.playlist.segmentByURL url
    promise.fail (error) =>
      if url.match /__LYT_auto_/
        this.reject "Failed to seek to #{url} containing auto generated book marks - rewinding to start"
        log.message "Player: command seek: failed to seek to #{url} containing auto generated book marks - rewinding to start"
      else
        this reject "Failed to seek to url #{url}: #{error} - rewinding to start"
        log.error "Player: command seek: failed to seekt to url #{url}: #{error} - rewinding to start"

# Rewinding to start
#      offset = 0
#      promise = @playlist().rewind()
#      promise.done doneHandler
#      promise.fail failHandler

#    if not url
#      promise = @playlist().rewind()
#      promise.done doneHandler
#      promise.fail failHandler

    promise.done (segment) =>

      throw 'Player: playSegmentOffset called with no segment' unless segment?
  
      # Ensure that offset has a useful value
      if offset?
        if offset > segment.end
          log.warn "Player: command seek: got offset out of bounds: segment end is #{segment.end}"
          offset = segment.end - 1
          offset = segment.start if offset < segment.start
        else if offset < segment.start
          log.warn "Player: command seek: got offset out of bounds: segment start is #{segment.start}"
          offset = segment.start
      else
        offset = segment.start

      # Fixing odd buffer bug in Chrome 24 where offset == 0 causes it to stop buffering
      offset = 0.000001 if offset == 0
      
      # See if we need to initiate loading of a new audio file or if it is
      # possible to just move the play head.
      if @player.getStatus().src != segment.audio
        @player.el.jPlayer 'setMedia', {mp3: segment.audio}
        @player.el.jPlayer 'load'
      else
        @player.el.jPlayer 'pause', offset

