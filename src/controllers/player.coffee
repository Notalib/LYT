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
  
  # TODO See if the IOS metadata bug has been fixed here:
  # https://github.com/happyworm/jPlayer/commit/2889b5efd84c4920d904e7ab368aa8db95929a95
  # https://github.com/happyworm/jPlayer/commit/de22c88d4984210dd1bf4736f998d693c097cba6
  
  playAttemptCount: 0
  playBackRate: LYT.settings.get('playBackRate') or 1
  
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
        
        $('.jp-pause').click => @playing = false

        $('.jp-play').click =>  @playing = true
        
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

      timeupdate: (event) =>
        LYT.instrumentation.record 'timeupdate', event.jPlayer.status
        status = event.jPlayer.status
        @time = status.currentTime
        
        # Schedule fake ending of file if necessary
        @fakeEnd status if LYT.config.player.useFakeEnd

        # FIXME: Pause due unloaded segments should be improved with a visual
        #        notification.
        # FIXME: Handling of resume when the segment has been loaded can be
        #        mixed with user interactions, causing an undesired resume
        #        after the user has clicked pause.

        # Don't do anything else if we're already moving to a new segment
        if @timeupdateLock and @_next and @_next.state() isnt 'resolved'
          log.message "Player: timeupdate: timeupdateLock set. Next segment: #{@_next.state()}. Pause until resolved."
          LYT.loader.register 'Loading book', @_next
          @pause()
          @_next.done => @el.jPlayer 'play'
          @_next.fail   -> log.error 'Player: timeupdate event: unable to load next segment after pause.'
          return
         
        # This method is idempotent - will not do anything if last update was
        # recent enough.
        @updateLastMark()

        # Move one segment forward if no current segment or no longer in the
        # interval of the current segment
        segment = @segment()
        if not segment or status.src != segment.audio or segment.end < @time
          log.message "Player: timeupdate: queue for offset #{@time}"
          @timeupdateLock = true
          promise = @playlist().segmentByAudioOffset status.src, @time
          @_next = promise
          promise.fail (error) -> log.errorGroup "Player: timeupdate event: Unable to load next segment: #{error}.", next
          promise.done (next) =>
            if next
              log.message "Player: timeupdate: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
              @updateHtml next
            else
              log.message "Player: timeupdate: current segment: [#{segment.start}, #{segment.end}], no segment at #{@time}, skipping to next segment."
              promise = @playlist().nextSegment segment
              promise.done (next) =>
                if next?
                  if next.start > @time or next.end < @time
                    @seekedLoadSegmentLock = true
                    @playSegment next, true
                    # TODO: This is most likely to not do as we expect, since next
                    # has already resolved
                    next.done => @seekedLoadSegmentLock = false
                  else
                    @playlist.currentSegment = next
                    @updateHtml next
                else
                  log.error 'Player: timeupdate: no next segment'
          promise.always => @timeupdateLock = false

      loadstart: (event) =>
        LYT.instrumentation.record 'loadstart', event.jPlayer.status
        log.message "Player: loadstart: playAttemptCount: #{@playAttemptCount}, paused: #{@getStatus().paused}"
        @timeupdateLock = false
        LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and not @firstPlay
        return if $.jPlayer.platform.android or $.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod
        return unless jQuery.browser.webkit
        @updateHtml @segment()
      
      ended: (event) =>
        LYT.instrumentation.record 'ended', event.jPlayer.status
        log.message 'Player: event ended'
        # XXX: Merging issue-275: the following line was deleted:
        # @timeupdateLock = false
        if @playing and not LYT.config.player.useFakeEnd
          log.message 'Player: event ended: moving to next segment'
          @nextSegment(true).always => @timeupdateLock = false
        else
          @timeupdateLock = false

      playing: (event) =>
        status = LYT.player.getStatus()
        if (status.readyState > 2) and status.duration? and (status.currentTime < @currentOffset) and (0 <= @currentOffset <= status.duration)
          action = if @playing then 'play' else 'pause'
          @el.jPlayer action, @currentOffset
      
      play: (event) =>
        LYT.instrumentation.record 'play', event.jPlayer.status
        log.message "Player: event play, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        # Help JAWS users, move focus back
        LYT.render.setPlayerButtonFocus 'pause'
        
      pause: (event) =>
        LYT.instrumentation.record 'pause', event.jPlayer.status
        log.message "Player: event pause"
        status = event.jPlayer.status
        LYT.render.setPlayerButtonFocus 'play'

      seeked: (event) =>
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
        log.message "Player: event seeked: get segment at offset #{@time}"
        segment = @playlist().segmentByAudioOffset event.jPlayer.status.src, @time
        segment.fail -> log.warn "Player: event seeked: unable to get segment at #{event.jPlayer.status.src}, #{event.jPlayer.status.currentTime}"
        segment.done (segment) =>
          @updateHtml segment if segment?
          #if we were playing and the system pause the sound for some reason  -  start play again
          if @getStatus().paused and @playing and @getStatus().readyState > 2
            log.message 'Player: event seeked: starting the player again'
            @el.jPlayer 'play'
          
      loadedmetadata: (event) =>
        LYT.instrumentation.record 'loadedmetadata', event.jPlayer.status
        log.message "Player: loadedmetadata: playAttemptCount: #{@playAttemptCount}, firstPlay: #{@firstPlay}, paused: #{@getStatus().paused}"
        LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and @firstPlay
        if isNaN(event.jPlayer.status.duration) or event.jPlayer.status.duration == 0
          if @getStatus().src == @currentAudio
            if @playAttemptCount <= LYT.config.player.playAttemptLimit
              @el.jPlayer 'setMedia', {mp3: @currentAudio}
              @playAttemptCount = @playAttemptCount + 1
              log.message "Player: loadedmetadata, play attempts: #{@playAttemptCount}"
            else
              # Give up: we pretend that we have got the duration
              @playAttemptCount = 0
        else
          @playAttemptCount = 0
      
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
          @el.jPlayer action, @nextOffset
          @currentOffset = @nextOffset
          @nextOffset = null
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
    if @el.data('jPlayer').htmlElement.audio?.playbackRate?
      @el.data('jPlayer').htmlElement.audio.playbackRate = @playBackRate

    if @el.data('jPlayer').htmlElement.audio?.defaultPlaybackRate?
      @el.data('jPlayer').htmlElement.audio.defaultPlaybackRate  = @playBackRate
      #Added for IOS6 - iphone will not change the playBackRate unless you pause
      #the playback, after setting the playbackRate. And then we can obtain the new
      #playbackRate and continue
      # TODO: This makes safari desktop version fail...so find a solution...browser sniffing?
      if not @getStatus().paused
        @el.jPlayer 'pause'
        @el.jPlayer 'play'

      log.message "Player: setPlayBackRate: #{@playBackRate}"
    else
      log.message "Player: setPlayBackRate: unable to set playback rate"
  
  isPlayBackRateSupported: ->
    promise = Modernizr.playback.isPlayBackRateSupported()
    promise.pipe (result) ->
      return result  
  isIOS: () ->
    if /iPad/i.test(navigator.userAgent) or /iPhone/i.test(navigator.userAgent) or /iPod/i.test(navigator.userAgent)
      return true
    else
      return false
  
  refreshContent: ->
    if @playlist() and segment = @segment()
      @updateHtml segment
      
  updateHtml: (segment) ->
    # Update player rendering for current time of section
    if not segment?
      log.error "Player: updateHtml called with no segment"
      return

    if segment.state() isnt 'resolved'
      log.error "Player: updateHtml called with unresolved segment"
      return

    log.group "Player: updateHtml: rendering segment #{segment.url()}, start #{segment.start}, end #{segment.end}", segment
    @renderTranscript segment
    segment.preloadNext()
  
  # TODO: Factor out this method and replace it by calls to updateHtml
  renderTranscript: (segment) ->
    if segment?
      segment.done (segment) -> LYT.render.textContent segment
    else
      # If there's no media, show nothing
      LYT.render.textContent null
  
  
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback
  
  # url: url pointing to section or segment
  load: (book, url = null, offset = 0, play) ->
    #return if book.id is @book?.id
    deferred = jQuery.Deferred()
    load = LYT.Book.load book
    
    log.message "Player: Loading book #{book}, segment #{url}, offset: #{offset}, play #{play}"
    load.done (book) =>
      @book = book
      jQuery("#book-duration").text @book.totalTime
      @whenReady =>
        if not url and book.lastmark?
          url    = book.lastmark.URI
          offset = LYT.utils.parseOffset book.lastmark?.timeOffset
          log.message "Player: resuming from lastmark #{url}, offset #{offset}"

        failHandler = () =>
          deferred.reject 'failed to find segment'
          log.error "Player: failed to find segment"

        doneHandler = (segment) =>
          deferred.resolve @book
          @playSegmentOffset segment, offset, play
          log.message "Player: found segment #{segment.url()} - playing"

        if url
          promise = @playlist().segmentByURL url
          promise.done doneHandler
          promise.fail (error) =>
            if url.match /__LYT_auto_/
              log.message "Player: failed to load #{url} containing auto generated book marks - rewinding to start"
            else
              log.error "Player: failed to load url #{url}: #{error} - rewinding to start"
            offset = 0
            promise = @playlist().rewind()
            promise.done doneHandler
            promise.fail failHandler
        else
          promise = @playlist().rewind()
          promise.done doneHandler
          promise.fail failHandler
    
    load.fail (error) ->
      log.error "Player: failed to load book, reason #{error}"
      deferred.reject error

    deferred.promise()

  playSegment: (segment, play) -> @playSegmentOffset segment, null, play
  
  # Will display the provided segment, load (if necessary) and play the
  # associated audio file starting att offset. If offset isn't provided, start
  # at the beginning of the segment. It is an error to provide an offset not 
  # within the bounds of segment.start and segment.end. In this case, the
  # offset is capped to segment.start or segment.end - 1 (one second before
  # the segment ends).
  playSegmentOffset: (segment, offset, play) ->
    throw 'Player: playSegmentOffset called with no segment' unless segment?
    segment.done (segment) =>
      log.message "Player: playSegmentOffset: play #{segment.url()}, offset #{offset}, play: #{play}"

      # Ensure that offset has a useful value
      if offset?
        if offset > segment.end
          log.warn "Player: playSegmentOffset: got offset out of bounds: segment end is #{segment.end}"
          offset = segment.end - 1
          offset = segment.start if offset < segment.start
        else if offset < segment.start
          log.warn "Player: playSegmentOffset: got offset out of bounds: segment start is #{segment.start}"
          offset = segment.start
      else
        offset = segment.start

      # Fixing odd buffer bug in Chrome 24 where offset == 0 causes it to stop buffering
      offset = 0.000001 if offset == 0
      
      # If play is set to true or false, set playing accordingly
      @playing = play if play?

      # See if we need to initiate loading of a new audio file or if it is
      # possible to just move the play head.
      if @currentAudio != segment.audio
        log.message "Player: playSegmentOffset: setMedia #{segment.audio}, setting nextOffset to #{offset}"
        @currentAudio = segment.audio
        @nextOffset   = offset
        @el.jPlayer 'setMedia', {mp3: segment.audio}
        @el.jPlayer 'load'
      else
        if @playing
          log.message "Player: playSegmentOffset: play from offset #{offset}"
          @el.jPlayer 'play', offset
        else
          log.message "Player: playSegmentOffset: pause at offset #{offset}"
          @el.jPlayer 'pause', offset

      @updateHtml segment

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
