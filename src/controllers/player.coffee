# Requires `/common`  
# Requires `/support/lyt/loader`  

# -------------------

# This module handles playback of current media and timing of transcript updates  
# TODO: provide a visual cue on the next and previous section buttons if there are no next or previous section.

LYT.player = 
  SILENTMEDIA: "http://m.nota.nu/sound/dixie.mp3" # FIXME: dixie chicks as we test, replace with silent mp3 when moving to production
  PROGRESSION_MODES:
    MP3:  'mp3'
    TEXT: 'text'
  
  ready: false 
  el: null
  
  time: ""
  book: null #reference to an instance of book class
  playlist: -> @book?.playlist
  nextButton: null
  previousButton: null
  
  playing: null
  nextOffset: null

  autoProgression: true 
  progressionMode: null
  timeupdateLock: false
  
  fakeEndScheduled: false
  firstPlay: true
  
  # TODO See if the IOS metadata bug has been fixed here:
  # https://github.com/happyworm/jPlayer/commit/2889b5efd84c4920d904e7ab368aa8db95929a95
  # https://github.com/happyworm/jPlayer/commit/de22c88d4984210dd1bf4736f998d693c097cba6
  _iBug: false
  
  playAttemptCount: 0
  gotDuration: null
  playBackRate: 1 #Default playBackRate for audio element....
  
  lastBookmark: (new Date).getTime()
  
  segment: -> @playlist().currentSegment
  
  section: -> @playlist().currentSection()
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    @progressionMode = @PROGRESSION_MODES.MP3
    @currentAudio = ''
         
    jplayer = @el.jPlayer
      ready: =>
        log.message "Player: event ready: paused: #{@getStatus().paused}"
        @ready = true
        @timeupdateLock = false
        log.message 'Player: initialization complete'
        #@el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
        #todo: add a silent state where we do not play on can play   
        
        $.jPlayer.timeFormat.showHour = true
        
        $('.jp-pause').click => @playing = false
        $('.jp-play').click  => @playing = true
        
        @nextButton.click =>
          log.message "Player: next: #{@segment().next?.url()}"
          @nextSegment @playing
            
        @previousButton.click =>
          log.message "Player: previous: #{@segment().previous?.url()}"
          @previousSegment @playing
      
      timeupdate: (event) =>
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
          return
         
        # This method is idempotent - will not do anything if last update was
        # recent enough.
        @updateLastMark()

        # Move one segment forward if no current segment or no longer in the
        # interval of the current segment
        if not @segment() or status.src != @segment().audio or @segment().end < @time
          log.message "Player: timeupdate: queue for offset #{@time}"
          @timeupdateLock = true
          next = @playlist().segmentByAudioOffset status.src, @time
          @_next = next
          next.fail (error) -> log.errorGroup "Player: timeupdate event: Unable to load next segment: #{error}.", next
          next.done (next) =>
            if next
              log.message "Player: timeupdate: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
              @updateHtml next
            else
              log.message "Player: timeupdate: (#{status.currentTime}s): no current segment"
          next.always => @timeupdateLock = false

      loadstart: (event) =>
        log.message "Player: loadstart: playAttemptCount: #{@playAttemptCount}, paused: #{@getStatus().paused}"
        @setPlayBackRate()
        @timeupdateLock = false
        LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and not @firstPlay
        return if $.jPlayer.platform.android or $.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod
        return unless jQuery.browser.webkit
        @updateHtml @segment()
      
      ended: (event) =>
        log.message 'Player: event ended'
        @timeupdateLock = false
        if @playing and not LYT.config.player.useFakeEnd
          log.message 'Player: event ended: moving to next segment'
          @nextSegment true
      
      play: (event) =>
        log.message "Player: event play, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        # Help JAWS users, move focus back
        LYT.render.setPlayerButtonFocus 'pause'
        # We should be checking for readyState < 4, but IOS is optimistic and allows readyState == 3
        # when it fires the canplaythrough event, which - in turn - will press play
        # We could solve this issue by setting up a timer that is watching the readyState, but such
        # a timer needs to be cleared on most kinds of interaction with the player.
        if @getStatus().readyState < 3
          log.message "Player: event play: calling pause since not enough content has been buffered"
          LYT.loader.set('Loading sound', 'metadata')
          # Use the old value of nextOffset (if any) in case the player
          # is on IOS, since the meta data bug on this platform causes the
          # player to report the wrong currentTime. 
          unless @nextOffset?
            if @nextOffset = @getStatus().currentTime
              log.warn "Player: event play: using the players time to determine nextOffset, nextOffset #{@nextOffset}"
            else if segment = @segment()
              @nextOffset = segment.start
              log.warn "Player: event play: using current segment to determine nextOffset, nextOffset #{@nextOffset}"
            else
              log.error 'Player: event play: unable to determine next offset. Rewinding.'
              @nextOffset = 0
          # Issue pause to stop the player from playing until we have buffered
          # enough. Also, provide @nextOffset to ensure that we buffer the
          # right part of the audio.
          @el.jPlayer 'pause', @nextOffset

      pause: (event) =>
        log.message "Player: event pause"
        status = event.jPlayer.status
        LYT.render.setPlayerButtonFocus 'play'

        return if status.ended # Drop pause event emitted when media ends

        return unless @isIOS()
        if @_iBug
          log.warn 'we are ibug'
          #@el.jPlayer('load')
          
        else if status.duration > 0 and jQuery.jPlayer.convertTime(status.duration) is not 'NaN' and jQuery.jPlayer.convertTime(status.duration) is not '00:00' and (status.currentTime is 0 or status.currentTime is status.duration)  
          log.warn 'set ibug'
          @_iBug = true

      seeked: (event) =>
        @time = event.jPlayer.status.currentTime
        log.message "Player: event seeked to offset #{@time}, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        @timeupdateLock = false
        LYT.loader.close 'metadata'
        return if @seekedLoadSegmentLock
        log.message "Player: event seeked: get segment at offset #{@time}"
        segment = @playlist().segmentByAudioOffset event.jPlayer.status.src, @time
        segment.fail -> log.error 'Player: event seeked: unable to get segment at offset '
        segment.done (segment) =>
          @updateHtml segment
          if @getStatus().paused and @playing and @getStatus().readyState > 2
            log.message 'Player: event seeked: starting the player again'
            @el.jPlayer 'play'

      loadedmetadata: (event) =>
        log.message "Player: loadedmetadata: playAttemptCount: #{@playAttemptCount}, firstPlay: #{@firstPlay}, paused: #{@getStatus().paused}"
        LYT.loader.set('Loading sound', 'metadata') if @playAttemptCount == 0 and @firstPlay
        if isNaN event.jPlayer.status.duration
          #alert event.jPlayer.status.duration
          if @getStatus().src == @currentAudio
            @gotDuration = false
            if @playAttemptCount <= LYT.config.player.playAttemptLimit
              @el.jPlayer "setMedia", {mp3: @currentAudio}
              @el.jPlayer "pause", @nextOffset
              @playAttemptCount = @playAttemptCount + 1 
              log.message "Player: loadedmetadata, play attempts: #{@playAttemptCount}"
            else
              # Give up: we pretend that we have got the duration
              @gotDuration = true
              @playAttemptCount = 0
        else
         @gotDuration = true
         @playAttemptCount = 0
         #LYT.loader.close('metadata')
      
      canplay: (event) =>
        log.message "Player: event canplay: paused: #{@getStatus().paused}"
        @el.jPlayer "pause", @nextOffset
        if @gotDuration
          # Reset gotDuration so it is cleared for the next file
          @gotDuration = false

      canplaythrough: (event) =>
        log.message "Player: event canplaythrough: nextOffset: #{@nextOffset}, paused: #{@getStatus().paused}, readyState: #{@getStatus().readyState}"
        if @nextOffset?
          action = if @playing then 'play' else 'pause'
          log.message "Player: event canplaythrough: #{action}, offset #{@nextOffset}"
          @el.jPlayer action, @nextOffset
          @nextOffset = null
          log.message "Player: event canplaythrough: currentTime: #{@getStatus().currentTime}"
        @firstPlay = false
        # We are ready to play now, so remove the loading message, if any
        LYT.loader.close('metadata')
      
      progress: (event) =>
        log.message 'Player: event progress'
        status = @getStatus()
        if @playing and status.paused and status.readyState > 2
          log.message 'Player: event progress: resuming play since enough audio has been buffered'
          @el.jPlayer 'play'
      
      error: (event) =>
        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message "Player: event error: jPlayer: url error: #{event.jPlayer.error.message}, #{event.jPlayer.error.hint}, #{event.jPlayer.status.src}"
            parameters =
              mode:                'bool'
              prompt:              LYT.i18n('An error has occurred')
              subTitle:            LYT.i18n('unable to retrieve sound file.')
              animate:             false
              useDialogForceFalse: true
              allowReopen:         true
              useModal:            true
              buttons:             {}
            parameters.buttons[LYT.i18n('Try again')] =
              click: -> window.location.reload()
              theme: 'c'
            parameters.buttons[LYT.i18n('Cancel')] =
              click: -> $.mobile.changePage "#bookshelf"
              theme: 'c'
            LYT.render.showDialog($.mobile.activePage,parameters)

            #reopen the dialog...
            #TODO: this is usually because something is wrong with the session or the internet connection, 
            # tell people to try and login again, check their internet connection or try again later
          when $.jPlayer.error.NO_SOLUTION
            log.message 'Player: event error: jPlayer: no solution error, you need to install flash or update your browser.'
            #TODO: send people to a link where they can download flash or update their browser
      
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
      @el.jPlayer('pause', offset)
    else
      @nextOffset = null
      @el.jPlayer('pause')
  
  # This is a public method - stops playback
  stop: ->
    log.message 'Player: stop'
    if @ready?
      @el.jPlayer('stop')
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
      log.message "Player: setPlayBackRate: #{@playBackRate}"
    else
      log.message "Player: setPlayBackRate: unable to set playback rate"
  
  isPlayBackRateSupported: ->
    if @el.data('jPlayer').htmlElement.audio?.playbackRate?
      return false if $.jPlayer.platform[platform] for platform in ['iphone', 'ipad', 'ipod', 'android']
      return false if /Windows Phone/i.test(navigator.userAgent)
      return true
    else
      return false
  
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
    
    #LYT.loader.register "Loading book", @book
    
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
          promise.fail =>
            if url.match /__LYT_auto_/
              log.message "Player: failed to load #{url} containing auto generated book marks - rewinding to start"
            else
              log.error "Player: failed to load url #{url} - rewinding to start"
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
        else if offset < segment.start
          log.warn "Player: playSegmentOffset: got offset out of bounds: segment start is #{segment.start}"
          offset = segment.start
      else
        offset = segment.start
      
      # If play is set to true or false, set playing accordingly
      @playing = play if play?
      
      # See if we need to initiate loading of a new audio file or if it is
      # possible to just move the play head.
      if @currentAudio != segment.audio
        log.message "Player: playSegmentOffset: setMedia #{segment.audio}, setting nextOffset to #{offset}"
        @el.jPlayer "setMedia", {mp3: segment.audio}
        @el.jPlayer "load"
        @currentAudio = segment.audio
        @nextOffset   = offset
      else
        if @playing
          log.message "Player: playSegmentOffset: play from offset #{offset}"
          @el.jPlayer 'play', offset
        else
          log.message "Player: playSegmentOffset: pause at offset #{offset}"
          @el.jPlayer 'pause', offset

      $("#player-chapter-title h2").text segment.section.title
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

  previousSegment: ->
    return null unless @playlist()?.hasPreviousSegment()
    @setMetadataLoader @segment().previous
    @seekedLoadSegmentLock = true
    segment = @playlist().previousSegment()
    @playSegment segment
    segment.always => @seekedLoadSegmentLock = false
  
  updateLastMark: (force = false) ->
    return unless LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin
    return unless segment = @segment()
    segment.done (segment) =>
      # We use wall clock time here because book time can be streched if
      # the user has chosen a different play back speed.
      now = (new Date).getTime()
      interval = LYT.config.player?.lastmarkUpdateInterval or 20000
      return unless force or not @lastBookmark or now - @lastBookmark > interval
      return if @nextOffset?
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
