# Requires `/common`  
# Requires `/support/lyt/loader`  
# Requires `/models/member/settings`
# -------------------

# This module handles playback of current media and timing of transcript updates  
# TODO: provide a visual cue on the next and previous section buttons if there are no next or previous section.

LYT.player = 
  ready: false 
  el: null
  
  time: ""
  book: null #reference to an instance of book class
  playlist: -> @book?.playlist
  nextButton: null
  previousButton: null
  
  playing: null
  nextOffset: null
  currentOffset: null
  
  timeupdateLock: false
  
  fakeEndScheduled: false
  firstPlay: true
  
  refreshTimer: null
  
  # TODO See if the IOS metadata bug has been fixed here:
  # https://github.com/happyworm/jPlayer/commit/2889b5efd84c4920d904e7ab368aa8db95929a95
  # https://github.com/happyworm/jPlayer/commit/de22c88d4984210dd1bf4736f998d693c097cba6
  
  playAttemptCount: 0
  playBackRate: 1
  
  lastBookmark: (new Date).getTime()
  
  segment: -> @playlist().currentSegment
  
  section: -> @playlist().currentSection()
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    @currentAudio = ''
    @playBackRate = LYT.settings.get('playBackRate') if LYT.settings.get('playBackRate')?

    # This handler replaces the old progress handler which unfortunately
    # never got called as often as necessary
    startHandler = =>
      status = @getStatus()
      if @playing and status.paused and @currentAudio? and @segment? and @currentAudio is @segment.audio and status.readyState > 2
        log.message 'Player: synthetic event progress: resuming play since enough audio has been buffered'
        @el.jPlayer 'play'
      
    setInterval startHandler, 200
         
    jplayer = @el.jPlayer
      ready: =>
        LYT.instrumentation.record 'ready', @getStatus()
        log.message "Player: event ready: paused: #{@getStatus().paused}"
        @ready = true
        @timeupdateLock = false
        log.message 'Player: initialization complete'
        
        $.jPlayer.timeFormat.showHour = true
        
        # Pause button is only shown when playing
        $('.lyt-pause').click =>
          @playing?.cancel()

        $('.lyt-play').click => 
          @playing = true
          @play()
#          .always ->
#            $('.lyt-pause').hide()
#            $('.lyt-play').show()
        
        @nextButton.click =>
          log.message "Player: next: #{@segment().next?.url()}"
          @nextSegment()
            
        @previousButton.click =>
          log.message "Player: previous: #{@segment().previous?.url()}"
          @previousSegment()

        Mousetrap.bind 'alt+ctrl+space', =>
          if @playing 
            $('.jp-pause').click()
          else 
            $('.jp-play').click()
          return false

        Mousetrap.bind 'alt+right', ->
          $('a.next-section').click()
          return false
        
        Mousetrap.bind 'alt+left', ->
          $('a.previous-section').click()
          return false
      
        # FIXME: add handling of section jumps
        Mousetrap.bind 'alt+ctrl+n', ->
          log.message "next section"
          return false

        Mousetrap.bind 'alt+ctrl+o', ->
          log.message "previous section"
          return false

      _timeupdate: (event) =>
        LYT.instrumentation.record 'timeupdate', event.jPlayer.status
        status = event.jPlayer.status
        # Drop timeupdate event fired while the player is paused 
        return if status.paused
        @time = status.currentTime
        
        # Schedule fake ending of file if necessary
        @fakeEnd status if LYT.config.player.useFakeEnd

        # FIXME: Pause due unloaded segments should be improved with a visual
        #        notification.
        # FIXME: Handling of resume when the segment has been loaded can be
        #        mixed with user interactions, causing an undesired resume
        #        after the user has clicked pause.

        # Don't do anything else if we're already moving to a new segment
        if @timeupdateLock
          log.message 'Player: timeupdate: timeudateLock set.'
          if @_next and @_next.state() isnt 'resolved'
            log.message "Player: timeupdate: Next segment: #{@_next.state()}. Pause until resolved."
            LYT.loader.register 'Loading book', @_next
            @pause()
            @_next.done => @el.jPlayer 'play'
            @_next.fail -> log.error 'Player: timeupdate event: unable to load next segment after pause.'
          return
         
        # This method is idempotent - will not do anything if last update was
        # recent enough.
        @updateLastMark()

        # Move one segment forward if no current segment or no longer in the
        # interval of the current segment and within two seconds past end of
        # current segment (otherwise we are seeking ahead).
        segment = @segment()
        if segment? and status.src == segment.audio and segment.start < @time + 0.1 < segment.end + 2
          if segment.end < @time
            # This block uses the current segment for synchronization.
            log.message "Player: timeupdate: queue for offset #{@time}"
            @timeupdateLock = true
            log.message "Player: timeupdate: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}], no segment at #{@time}, skipping to next segment."
            promise = @playlist().nextSegment segment
            @_next = promise
            promise.done (next) =>
              if next?
                if next.audio is @currentAudio and next.start - 0.1 < @time < next.end + 0.1
                  @playlist.currentSegment = next
                  @updateHtml next
                  @timeupdateLock = false
                else
                  @seekedLoadSegmentLock = true
                  # This stops playback and should ensure that we won't skip more
                  # than one segment ahead if another timeupdate event is fired,
                  # since all timeupdate events with status paused are dropped.
                  log.message 'Player: timeupdate: pause while switching audio file'
                  @el.jPlayer 'pause'
                  promise = @playSegment next, true
                  promise.done =>
                    @seekedLoadSegmentLock = false
                    @updateHtml next
                  promise.always => @timeupdateLock = false
              else
                log.error 'Player: timeupdate: no next segment'
            # else: nothing to do: segment and audio are in sync as they should
        else
          # This block uses the current offset in the audio stream for
          # synchronization - a strategy that fails if there is no segment for
          # the current offset.
          log.message "Player: timeupdate: segment and sound out of sync. Fetching segment for #{status.src}, offset #{@time}"
          if segment
            log.group "Player: timeupdate: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]: ", segment
          else
            log.message 'Player: timeupdate: no current segment set.'
          promise = @playlist().segmentByAudioOffset status.src, @time
          @_next = promise
          promise.fail (error) ->
            # TODO: The user may have navigated to a place in the audio stream
            #       that isn't included in the book. Handle this gracefully by
            #       searching for the next segment in the audio file.
            log.error "Player: timeupdate event: Unable to load next segment: #{error}."
          promise.done (next) =>
            if next
              log.message "Player: timeupdate: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
              @updateHtml next
            else
              log.error "Player: timeupdate event: Unable to load any segment for #{status.src}, offset #{@time}."

      _loadstart: (event) =>
        LYT.instrumentation.record 'loadstart', event.jPlayer.status
        log.message "Player: loadstart: playAttemptCount: #{@playAttemptCount}, paused: #{@getStatus().paused}"
        @timeupdateLock = false
        LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and not @firstPlay
        return if $.jPlayer.platform.android or $.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod
        return unless jQuery.browser.webkit
        @updateHtml @segment()
      
      _ended: (event) =>
        LYT.instrumentation.record 'ended', event.jPlayer.status
        log.message 'Player: event ended'
        # XXX: Merging issue-275: the following line was deleted:
        # @timeupdateLock = false
        if @playing and not LYT.config.player.useFakeEnd
          log.message 'Player: event ended: moving to next segment'
          @nextSegment(true).always => @timeupdateLock = false
        else
          @timeupdateLock = false
      
      _play: (event) =>
        LYT.instrumentation.record 'play', event.jPlayer.status
        status = event.jPlayer.status
        log.message "Player: event play, nextOffset: #{@nextOffset}, currentTime: #{status.currentTime}"
        if @nextOffset?
          # IOS will some times omit seeking (both the actual seek and the
          # following seeked event are missing) and just start playing from
          # the start of the stream. We detect this here and do another seek
          # if it is the case.
          # This will cause a loop if the play event arrives later than 0.5
          # seconds after playback has started.
          if -0.01 < status.currentTime - @nextOffset < 0.5
            # This event handler consumes @nextOffset
            @nextOffset = null
          else
            log.warn "Player: event play: retry seek, nextOffset: #{@nextOffset}, currentTime: #{status.currentTime}"
            # Stop playback to ensure that another play event is emitted
            # to check that the player doesn't skip the next seek as well.
            @el.jPlayer 'pause'
            # Not using a delay here seems to create infinite play/pause loops
            # because the player doesn't get time for the seek.
            # (This is probably a hint wrt a better way of working around this
            # bug in IOS.)
            setTimeout(
              => @el.jPlayer 'play', @nextOffset
              500
            )
            return
        LYT.render.setPlayerButtonFocus 'pause'
        
      _pause: (event) =>
        LYT.instrumentation.record 'pause', event.jPlayer.status
        log.message "Player: event pause"
        LYT.render.setPlayerButtonFocus 'play'

      _seeked: (event) =>
        # FIXME: issue #459 HACK remove spinner no matter what
        LYT.loader.close 'metadata'
        LYT.instrumentation.record 'seeked', event.jPlayer.status
        @time = event.jPlayer.status.currentTime
        log.message "Player: event seeked to offset #{@time}, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        @timeupdateLock = false
        if @playIntentOffset?
          # The user didn't click the seek bar
          # We may be getting this seek event from a play call to jPlayer 'play'
          @playIntentOffset = null
          LYT.loader.close 'metadata'
          log.message 'Player: event seeked: cleared playIntentOffset'
        return if @seekedLoadSegmentLock
        log.message "Player: event seeked: get segment in #{event.jPlayer.status.src} at offset #{@time}"
        # TODO: Remove this kind of rendering. We should be able to handle it
        #       using playCommands since they are more reliable.
        @timeupdateLock = true
        segment = @playlist().segmentByAudioOffset event.jPlayer.status.src, @time
        segment.fail -> log.warn "Player: event seeked: unable to get segment at #{event.jPlayer.status.src}, #{event.jPlayer.status.currentTime}"
        segment.done (segment) =>
          @updateHtml segment if segment?
          # Start playing again if we were playing and jPlayer paused for some reason
          if @getStatus().paused and @playing and @getStatus().readyState > 2
            log.message 'Player: event seeked: starting the player again'
            @el.jPlayer 'play'
        segment.always => @timeupdateLock = false
          
      _loadedmetadata: (event) =>
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
              @el.jPlayer 'setMedia', {mp3: @currentAudio}
              @playAttemptCount = @playAttemptCount + 1
              log.message "Player: loadedmetadata, play attempts: #{@playAttemptCount}"
              return
            # else: give up - we pretend that we have got the duration
          @playAttemptCount = 0
        # else: nothing to do because we are playing the wrong file
      
      _canplay: (event) =>
        LYT.instrumentation.record 'canplay', event.jPlayer.status
        log.message "Player: event canplay: paused: #{@getStatus().paused}"

      _canplaythrough: (event) =>
        LYT.instrumentation.record 'canplaythrough', event.jPlayer.status
        log.message "Player: event canplaythrough: nextOffset: #{@nextOffset}, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        if @nextOffset?
          # XXX: Comment from issue-275:
          # We aren't using @pause here, since it will make the player emit a seek event
          # which will in turn clear the metadata loader.
          action = if @playing then 'play' else 'pause'
          log.message "Player: event canplaythrough: #{action}, offset #{@nextOffset}"
          @el.jPlayer action, @nextOffset
          @currentOffset = @nextOffset
          @setPlayBackRate()
          log.message "Player: event canplaythrough: currentTime: #{@getStatus().currentTime}"
        @firstPlay = false
        # We are ready to play now, so remove the loading message, if any
        LYT.loader.close('metadata')
      
      error: (event) =>
        LYT.instrumentation.record 'error', event.jPlayer.status
        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message "Player: event error: jPlayer: url error: #{event.jPlayer.error.message}, #{event.jPlayer.error.hint}, #{event.jPlayer.status.src}"
            parameters =
              mode:                'bool'
              prompt:              LYT.i18n('Unable to retrieve sound file')
              subTitle:            LYT.i18n('')
              animate:             false
              useDialogForceFalse: true
              allowReopen:         true
              useModal:            true
              buttons:             {}
            parameters.buttons[LYT.i18n('Try again')] =
              click: -> window.location.reload()
              theme: 'c'
            parameters.buttons[LYT.i18n('Cancel')] =
              click: -> $.mobile.changePage LYT.config.defaultPage.hash
              theme: 'c'
            LYT.render.showDialog($.mobile.activePage, parameters)

            #reopen the dialog...
            #TODO: this is usually because something is wrong with the session or the internet connection, 
            # tell people to try and login again, check their internet connection or try again later
          when $.jPlayer.error.NO_SOLUTION
            log.message 'Player: event error: jPlayer: no solution error, you need to install flash or update your browser.'
            parameters =
              mode:                'bool'
              prompt:              LYT.i18n('Platform not supported')
              subTitle:            LYT.i18n('')
              animate:             false
              useDialogForceFalse: true
              allowReopen:         true
              useModal:            true
              buttons:             {}
            parameters.buttons[LYT.i18n('OK')] =
              click: ->
                $(document).one 'pagechange', -> $.mobile.silentScroll $('#supported-platforms').offset().top
                $.mobile.changePage '#support'
              theme: 'c'
            LYT.render.showDialog($.mobile.activePage, parameters)
      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'


  fakeEnd: (status) ->
    return unless status.duration > 0 and status.currentTime > 1
    timeleft = status.duration - status.currentTime
    if timeleft < 1 and timeleft > 0
      #log.message @fakeEndScheduled
      if @fakeEndScheduled is false
        @fakeEndScheduled = true
        log.warn "Player: segment is #{timeleft} seconds from ending but we can't handle endings - schedule a fake end just before"      
        
        setTimeout (
          => 
            @nextSegment true
            @fakeEndScheduled = false
            @timeUpdateLock   = false),
          (timeleft*1000)-50 

  # Private method to pause (optionally at an offset)  
  pause: (offset) ->
    # Pause playback
    log.message "Player: pause: pause at offset #{offset}"

    if offset?
      @nextOffset = offset
      @el.jPlayer 'pause', offset
    else
      @nextOffset = null
      @el.jPlayer 'pause'
  
  # This is a public method - stops playback
  stop: ->
    log.message 'Player: stop'
    if @ready?
      @el.jPlayer 'stop'
      @playing = false
  
  getStatus: ->
    # Be cautious only read from status
    @el.data('jPlayer').status

  # TODO: Remove our own playBackRate attribute and use the one on the jPlayer
  #       If it isn't available, there is no reason to try using it.
  setPlayBackRate: (playBackRate) ->
    if playBackRate?
      @playBackRate = playBackRate
      
    setRate = =>
      @el.data('jPlayer').htmlElement.audio.playbackRate = @playBackRate
      @el.data('jPlayer').htmlElement.audio.defaultPlaybackRate = @playBackRate

    unsetRate = =>
      @el.data('jPlayer').htmlElement.audio.playbackRate = null
      @el.data('jPlayer').htmlElement.audio.defaultPlaybackRate = null

    setRate()

    # Added for IOS6: iphone will not change the playBackRate unless you pause
    # the playback, after setting the playbackRate. And then we can obtain the new
    # playbackRate and continue
    # TODO: This makes safari desktop version fail...so find a solution...browser sniffing?
    
    @el.jPlayer 'pause'
    setRate()
    
    # Return before starting the player unless we are supposed so
    # This is definately a hack that should go away if we move everyting to
    # player-controllers, because setting playback rate should be done as an
    # integral part of starting playback.
    return unless @playing
    
    @el.jPlayer 'play'

    # Added for Safari desktop version - will not work unless rate is unset
    # and set again
    unsetRate()
    setRate()

    log.message "Player: setPlayBackRate: #{@playBackRate}"
  
  isIOS: ->
    if /iPad/i.test(navigator.userAgent) or /iPhone/i.test(navigator.userAgent) or /iPod/i.test(navigator.userAgent)
      return true
    else
      return false
  
  refreshContent: ->
    # Using timeout to ensure that we don't call updateHtml too often
    refreshHandler = =>
      if @playlist() and segment = @segment()
        updateHtml segment
    clearTimeout @refreshTimer if @refreshTimer
    @refreshTimer = setTimeout 500, refreshHandler
      
  updateHtml: (segment) ->
    # Update player rendering for current time of section
    if not segment?
      log.error "Player: updateHtml called with no segment"
      return

    if segment.state() isnt 'resolved'
      log.error "Player: updateHtml called with unresolved segment"
      return

    log.message "Player: updateHtml: rendering segment #{segment.url()}, start #{segment.start}, end #{segment.end}"
    LYT.render.textContent segment
    segment.preloadNext()
    
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback
  
  # url: url pointing to section or segment
  load: (book, url = null, smilOffset, play) ->
    #return if book.id is @book?.id
    log.message "Player: Loading book #{book}, segment #{url}, smilOffset: #{smilOffset}, play #{play}"

    ready = jQuery.Deferred()
    @whenReady -> ready.resolve()
    
    result = ready.then -> LYT.Book.load book

    result = result.then (book) =>
      jQuery("#book-duration").text book.totalTime
      # Setting @book should be done after seeking has completed, but the
      # dependency on the books playlist prohibits this.
      @book = book
      if not url and book.lastmark?
        url = book.lastmark.URI
        smilOffset = book.lastmark.timeOffset
        log.message "Player: resuming from lastmark #{url}, smilOffset #{smilOffset}"

      segmentPromise = null
      if url
        segmentPromise = @playlist().segmentByURL url
        segmentPromise = segment.then(
            (segment) =>
              offset = segment.audioOffset(smilOffset) if smilOffset
              @seekSegmentOffset segment, offset
            (error) =>
              if url.match /__LYT_auto_/
                log.message "Player: failed to load #{url} containing auto generated book marks - rewinding to start"
              else
                log.error "Player: failed to load url #{url}: #{error} - rewinding to start"
              @playlist().rewind()
          )
      else
        segmentPromise = @playlist().rewind()
        segmentPromise = segmentPromise.then (segment) => @seekSegmentOffset segment, 0
      
      segmentPromise.fail ->
        deferred.reject 'failed to find segment'
        log.error "Player: failed to find segment"

      if play
        segmentPromise = segmentPromise.then => @play()

      segmentPromise.then -> book
    
    result.fail (error) ->
      log.error "Player: failed to load book, reason #{error}"
      deferred.reject error

    result.promise()

  play: ->
    log.message "Player: play"
    
    progressHandler = (status) =>
      $('.lyt-play').hide()
      $('.lyt-pause').show()
  
      time = status.currentTime
      
      # Schedule fake ending of file if necessary
      @fakeEnd status if LYT.config.player.useFakeEnd
  
      return
  
      # FIXME: Pause due unloaded segments should be improved with a visual
      #        notification.
      # FIXME: Handling of resume when the segment has been loaded can be
      #        mixed with user interactions, causing an undesired resume
      #        after the user has clicked pause.
  
      # Don't do anything else if we're already moving to a new segment
      if @timeupdateLock
        log.message 'Player: timeupdate: timeudateLock set.'
        if @_next and @_next.state() isnt 'resolved'
          log.message "Player: timeupdate: Next segment: #{@_next.state()}. Pause until resolved."
          LYT.loader.register 'Loading book', @_next
          command.cancel()
          @_next.done => new LYT.player.command.play @el
          @_next.fail -> log.error 'Player: timeupdate event: unable to load next segment after pause.'
        return
       
      # This method is idempotent - will not do anything if last update was
      # recent enough.
      @updateLastMark()
  
      # Move one segment forward if no current segment or no longer in the
      # interval of the current segment and within two seconds past end of
      # current segment (otherwise we are seeking ahead).
      segment = @segment()
      if segment? and status.src == segment.audio and segment.start < time + 0.1 < segment.end + 2
        if segment.end < time
          # This block uses the current segment for synchronization.
          log.message "Player: timeupdate: queue for offset #{time}"
          @timeupdateLock = true
          log.message "Player: timeupdate: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}], no segment at #{time}, skipping to next segment."
          promise = @playlist().nextSegment segment
          @_next = promise
          promise.done (next) =>
            if next?
              if next.audio is @currentAudio and next.start - 0.1 < time < next.end + 0.1
                @playlist.currentSegment = next
                @updateHtml next
                @timeupdateLock = false
              else
                @seekedLoadSegmentLock = true
                # This stops playback and should ensure that we won't skip more
                # than one segment ahead if another timeupdate event is fired,
                # since all timeupdate events with status paused are dropped.
                log.message 'Player: timeupdate: pause while switching audio file'
                @el.jPlayer 'pause'
                promise = @playSegment next, true
                promise.done =>
                  @seekedLoadSegmentLock = false
                  @updateHtml next
                promise.always => @timeupdateLock = false
            else
              log.error 'Player: timeupdate: no next segment'
          # else: nothing to do: segment and audio are in sync as they should
      else
        # This block uses the current offset in the audio stream for
        # synchronization - a strategy that fails if there is no segment for
        # the current offset.
        log.message "Player: timeupdate: segment and sound out of sync. Fetching segment for #{status.src}, offset #{time}"
        if segment
          log.group "Player: timeupdate: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]: ", segment
        else
          log.message 'Player: timeupdate: no current segment set.'
        promise = @playlist().segmentByAudioOffset status.src, time
        @_next = promise
        promise.fail (error) ->
          # TODO: The user may have navigated to a place in the audio stream
          #       that isn't included in the book. Handle this gracefully by
          #       searching for the next segment in the audio file.
          log.error "Player: timeupdate event: Unable to load next segment: #{error}."
        promise.done (next) =>
          if next
            log.message "Player: timeupdate: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
            @updateHtml next
          else
            log.error "Player: timeupdate event: Unable to load any segment for #{status.src}, offset #{time}."
    command = new LYT.player.command.play @el
    command.progress progressHandler
    command.done -> log.warn 'Play completed!'
    command

  seekSegmentOffset: (segment, offset) ->
    log.message "Player: seekSegmentOffset: play #{segment.url?()}, offset #{offset}"

    segment or= @segment()

    # See if we need to initiate loading of a new audio file
    result = segment.then =>
      if @currentAudio != segment.audio
        log.message "Player: seekSegmentOffset: load #{segment.audio}"
        new LYT.player.command.load @el, segment.audio
      else
        jQuery.Deferred().resolve()

    # Now move the play head
    result = result.then =>
      # Ensure that offset has a useful value
      if offset?
        if offset > segment.end
          log.warn "Player: seekSegmentOffset: got offset out of bounds: segment end is #{segment.end}"
          offset = segment.end - 1
          offset = segment.start if offset < segment.start
        else if offset < segment.start
          log.warn "Player: seekSegmentOffset: got offset out of bounds: segment start is #{segment.start}"
          offset = segment.start
      else
        offset = segment.start
      new LYT.player.command.seek @el, offset

    # Once the seek has completed, render the segment
    result.done => @updateHtml segment

    result

  playSegment: (segment, play) -> @playSegmentOffset segment, null, play
  
  # Will display the provided segment, load (if necessary) and play the
  # associated audio file starting att offset. If offset isn't provided, start
  # at the beginning of the segment. It is an error to provide an offset not 
  # within the bounds of segment.start and segment.end. In this case, the
  # offset is capped to segment.start or segment.end - 1 (one second before
  # the segment ends).
  playSegmentOffset: (segment, offset) ->
    # If play is set to true or false, set playing accordingly
    @playing = true
    @seekSegmentOffset(segment, offset).then => @play()

  dumpStatus: -> log.message field + ': ' + LYT.player.getStatus()[field] for field in ['currentTime', 'duration', 'ended', 'networkState', 'paused', 'readyState', 'src', 'srcSet', 'waitForLoad', 'waitForPlay']

  playSection: (section, offset = 0, play) ->
    section = @playlist().rewind() unless section?
    LYT.loader.register "Loading book", section
    
    section.done (section) =>
      log.message "Player: Playlist current section #{@section().id}"
      # Get the media obj
      @playlist().segmentBySectionOffset section, offset
      @playSegmentOffset @segment(), offset, play
      
    section.fail ->
      log.error "Player: Failed to load section #{section}"

  # If it seems that loading the provided segment will take time
  # display the loading message and pause the player.
  # Not providing a segment is allowed and will cause the loading
  # message to appear and the player to pause.
  setMetadataLoader: (segment) ->
    if not segment or (segment.state() isnt 'resolved' or segment.audio isnt @currentAudio)
      # Using a delay and the standard fade duration on LYT.loader.set is the
      # most desirable, but Safari on IOS blocks right after it starts loading
      # the sound, which means that the message appears very late.
      # This is why we use fadeDuration 0 below.
      LYT.loader.set 'Loading sound', 'metadata', true, 0
      @el.jPlayer 'pause'

  # Skip to next segment
  # Returns segment promise
  nextSegment: ->
    return null unless @playlist()?
    if @playlist().hasNextSegment() is false
      LYT.render.bookEnd()
      delete @book.lastmark
      @book.saveBookmarks()
      return null
    @setMetadataLoader @segment().next
    @seekedLoadSegmentLock = true
    segment = @playlist().nextSegment()
    log.message "Player: nextSegment: #{segment.state()}"
    segment.done (segment) -> log.message "Player: nextSegment: #{segment.url()}, #{segment.start}"
    @playSegment segment
    segment.always => @seekedLoadSegmentLock = false
    segment

  # Skip to next segment
  # Returns segment promise
  previousSegment: ->
    return null unless @playlist()?.hasPreviousSegment()
    @setMetadataLoader @segment().previous
    @seekedLoadSegmentLock = true
    segment = @playlist().previousSegment()
    @playSegment segment
    segment.always => @seekedLoadSegmentLock = false
    segment
  
  updateLastMark: (force = false, segment) ->
    return unless LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin
    return unless (segment or= @segment())
    segment.done (segment) =>
      # We use wall clock time here because book time can be streched if
      # the user has chosen a different play back speed.
      now = (new Date).getTime()
      interval = LYT.config.player?.lastmarkUpdateInterval or 10000
      return if not (force or @lastBookmark and now - @lastBookmark > interval)
      # Round off to nearest 5 seconds
      # TODO: Use segment start if close to it
      @book.setLastmark segment, Math.floor(@getStatus().currentTime / 5) * 5
      @lastBookmark = now
  
  getCurrentlyPlaying: ->
    return null unless @book? and @segment()?.state() is "resolved"
    book:    @book.id
    section: @section()?.url
    segment: @segment()?.id
    offset:  @time
