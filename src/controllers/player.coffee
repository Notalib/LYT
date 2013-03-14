# Requires `/common`  
# Requires `/support/lyt/loader`  
# Requires `/models/member/settings`
# -------------------

# This module handles playback of current media and timing of transcript updates  
# TODO: provide a visual cue on the next and previous section buttons if there are no next or previous section.

LYT.player = 
  ready: false 
  el: null
  
  book: null #reference to an instance of book class
  nextButton: null
  previousButton: null
  playing: null
  refreshTimer: null
  firstPlay: true
  
  # TODO See if the IOS metadata bug has been fixed here:
  # https://github.com/happyworm/jPlayer/commit/2889b5efd84c4920d904e7ab368aa8db95929a95
  # https://github.com/happyworm/jPlayer/commit/de22c88d4984210dd1bf4736f998d693c097cba6
  
  playBackRate: 1
  
  lastBookmark: (new Date).getTime()

  playlist: -> @book?.playlist
  
  segment: -> @playlist().currentSegment
  
  section: -> @playlist().currentSection()
  
  setupAudioInstrumentation: ->
    audio = LYT.player.el.find('audio')[0]
    # Using proxy function to generate closure with original value
    proxy = (audio, name, value) ->
      audio[name] = ->
        LYT.instrumentation.record "audioCommand:#{name}"
        value.apply audio, arguments
    for name, value of audio
      proxy audio, name, value if typeof value is 'function'

    jPlayer = @el.jPlayer         
    @el.jPlayer = (command) =>
      LYT.instrumentation.record "command:#{command}" if typeof command is 'string'
      jPlayer.apply @el, arguments
  
  init: ->
    log.message 'Player: starting initialization'
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    @playBackRate = LYT.settings.get('playBackRate') if LYT.settings.get('playBackRate')?

    @el.jPlayer
      ready: =>
        @setupAudioInstrumentation()
        LYT.instrumentation.record 'ready', @getStatus()
        log.message "Player: event ready: paused: #{@getStatus().paused}"
        @ready = true
        log.message 'Player: initialization complete'
        
        $.jPlayer.timeFormat.showHour = true
        
        $('.lyt-pause').click => @stop()

        $('.lyt-play').click =>
          if @playClickHook
            @playClickHook().done => @play()
          else
            @play()
        
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

      progress: (event) =>
        LYT.instrumentation.record 'progress', event.jPlayer.status

      suspend: (event) =>
        LYT.instrumentation.record 'suspend', event.jPlayer.status

      abort: (event) =>
        LYT.instrumentation.record 'abort', event.jPlayer.status

      emptied: (event) =>
        LYT.instrumentation.record 'emptied', event.jPlayer.status

      stalled: (event) =>
        LYT.instrumentation.record 'stalled', event.jPlayer.status

      suspend: (event) =>
        LYT.instrumentation.record 'suspend', event.jPlayer.status

      ratechange: (event) =>
        LYT.instrumentation.record 'ratechange', event.jPlayer.status

      playing: (event) =>
        LYT.instrumentation.record 'playing', event.jPlayer.status

      waiting: (event) =>
        LYT.instrumentation.record 'waiting', event.jPlayer.status

      seeking: (event) =>
        LYT.instrumentation.record 'seeking', event.jPlayer.status

      loadstart: (event) =>
        LYT.instrumentation.record 'loadstart', event.jPlayer.status
      
      ended: (event) =>
        LYT.instrumentation.record 'ended', event.jPlayer.status

      timeupdate: (event) =>
        LYT.instrumentation.record 'timeupdate', event.jPlayer.status
      
      play: (event) =>
        LYT.instrumentation.record 'play', event.jPlayer.status
        
      pause: (event) =>
        LYT.instrumentation.record 'pause', event.jPlayer.status

      seeked: (event) =>
        LYT.instrumentation.record 'seeked', event.jPlayer.status
          
      loadedmetadata: (event) =>
        LYT.instrumentation.record 'loadedmetadata', event.jPlayer.status
      
      canplay: (event) =>
        LYT.instrumentation.record 'canplay', event.jPlayer.status

      canplaythrough: (event) =>
        LYT.instrumentation.record 'canplaythrough', event.jPlayer.status
      # TODO: [play-controllers]: see if we need to set playback rate here (shouldn't
      #       be necessary.
      
      error: (event) =>
        LYT.instrumentation.record 'error', event.jPlayer.status

        # Defaults for prompt following in error handlers below
        parameters =
          mode:                'bool'
          animate:             false
          useDialogForceFalse: true
          allowReopen:         true
          useModal:            true
          buttons:             {}

        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message "Player: event error: jPlayer: url error: #{event.jPlayer.error.message}, #{event.jPlayer.error.hint}, #{event.jPlayer.status.src}"
            parameters.prompt = LYT.i18n('Unable to retrieve sound file')
            parameters.subTitle = ''
            parameters.buttons[LYT.i18n('Try again')] =
              click: -> window.location.reload()
              theme: 'c'
            parameters.buttons[LYT.i18n('Cancel')] =
              click: -> $.mobile.changePage LYT.config.defaultPage.hash
              theme: 'c'
            LYT.render.showDialog($.mobile.activePage, parameters)

            # reopen the dialog...
            # TODO: this is usually because something is wrong with the session or the internet connection, 
            # tell people to try and login again, check their internet connection or try again later
          when $.jPlayer.error.NO_SOLUTION
            log.message 'Player: event error: jPlayer: no solution error, you need to install flash or update your browser.'
            parameters.prompt = LYT.i18n('Platform not supported')
            parameters.subTitle = ''
            parameters.buttons[LYT.i18n('OK')] =
              click: ->
                $(document).one 'pagechange', -> $.mobile.silentScroll $('#supported-platforms').offset().top
                $.mobile.changePage '#support'
              theme: 'c'
            LYT.render.showDialog($.mobile.activePage, parameters)
      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'

  # Be cautious only read from the returned status object
  getStatus: -> @el.data('jPlayer').status

  # TODO: Remove our own playBackRate attribute and use the one on the jPlayer
  #       If it isn't available, there is no reason to try using it.
  setPlayBackRate: (playBackRate) ->
    if playBackRate?
      @playBackRate = playBackRate
      
    # TODO: [play-controllers] integrate the setting playback rate this with
    #       the play() method by adding a playback rate to the play command
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
  
  refreshContent: ->
    # Using timeout to ensure that we don't call updateHtml too often
    refreshHandler = => @updateHtml segment if @playlist() and segment = @segment()
    clearTimeout @refreshTimer if @refreshTimer
    @refreshTimer = setTimeout refreshHandler, 500
      
 # Update player content with provided segment
  updateHtml: (segment) ->
    if not segment?
      log.error "Player: updateHtml called with no segment"
      return

    if segment.state() isnt 'resolved'
      log.error "Player: updateHtml called with unresolved segment"
      return

    log.message "Player: updateHtml: rendering segment #{segment.url()}, start #{segment.start}, end #{segment.end}"
    LYT.render.textContent segment
    segment.preloadNext()
  
  # Register callback to call when jPlayer is ready
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback

  # Load a book and seek to position provided by:  
  # url:        url pointing to par or seq element in SMIL file.
  # smilOffset: SMIL offset relative to url.
  # play:       flag indicating if the book should start playing after loading
  #             has finished.
  load: (book, url = null, smilOffset, play) ->
    log.message "Player: Load: book #{book}, segment #{url}, smilOffset: #{smilOffset}, play #{play}"

    # Wait for jPlayer to get ready
    ready = jQuery.Deferred()
    @whenReady -> ready.resolve()
  
    # Get the right book  
    result = ready.then =>
      if book is @book?.id
        jQuery.Deferred().resolve @book
      else
        # Load the book since we haven't loaded it already
        LYT.Book.load book

    result.done (book) =>
      # Setting @book should be done after seeking has completed, but the
      # dependency on the books playlist and firstplay issue prohibits this.
      @book = book
      jQuery("#book-duration").text book.totalTime

    result = result.then (book) =>
      if @firstPlay and not Modernizr.autoplayback
        # The play click handler will call @playClickHook which enables the
        # player to start seeking.
        @playClickHook = =>
          @playClickHook = null
          @playCommand = new LYT.player.command.deferred @el, @seekSmilOffsetOrLastmark url, smilOffset
          return @playCommand
        return jQuery.Deferred().resolve book
      else
        log.message 'Player: chaining seeked because we are not in firstPlay mode'
        return @seekSmilOffsetOrLastmark url, smilOffset

    result.done => @firstPlay = false

    result.done (book) ->
      log.message "Player: book #{book.id} loaded"

    result.fail (error) ->
      log.error "Player: failed to load book, reason #{error}"
      deferred.reject error

    LYT.loader.register 'Loading sound', result.promise()

    result.promise()

  # This is a public method - stops playback
  # The stop command returns the last play command or null in case there
  # isn't any.
  stop: ->
    log.message 'Player: stop'
    # TODO: [play-controllers] make this work again:
    # LYT.render.setPlayerButtonFocus 'play'

    @playing = false
    if command = @playCommand
      command.done => @playCommand = null if @playCommand is command
      command.cancel()
    
    return command

  # Starts playback
  play: ->
    # TODO: [play-controllers] make this work again:
    # LYT.render.setPlayerButtonFocus 'pause'

    command = null
    getPlayCommand = =>
      command = new LYT.player.command.play @el
      stopHandler = ->
        log.message 'Got stop event'
        command.cancel()
      command.progress progressHandler
      command.done -> log.group 'Play completed. ', command.status()
      command.always ->
        $('.lyt-pause').hide()
        $('.lyt-play').show()

    nextSegment = null
    progressHandler = (status) =>
      
      $('.lyt-play').hide()
      $('.lyt-pause').show()
  
      time = status.currentTime
      
      # FIXME: Pause due unloaded segments should be improved with a visual
      #        notification.
      # FIXME: Handling of resume when the segment has been loaded can be
      #        mixed with user interactions, causing an undesired resume
      #        after the user has clicked pause.
  
      # Don't do anything else if we're already moving to a new segment
      if nextSegment?.state() is 'pending'
        log.message 'Player: play: progress: nextSegment set and pending.'
        log.message "Player: play: progress: Next segment: #{nextSegment.state()}. Pause until resolved."
        return
      
      # This method is idempotent - will not do anything if last update was
      # recent enough.
      @updateLastMark()
  
      # Move one segment forward if no current segment or no longer in the
      # interval of the current segment and within two seconds past end of
      # current segment (otherwise we are seeking ahead).
      segment = @segment()
      if segment? and status.src == segment.audio and segment.start < time + 0.1 < segment.end + 2
        if time < segment.end
          # Segment and audio are in sync
          @lastplayed =
            book:    segment.section.nccDocument.book.id
            section: segment.section.url
            segment: segment.id
            offset:  time
            updated: new Date()
        else
          # Segment and audio are not in sync, move to next segment
          # This block uses the current segment for synchronization.
          log.message "Player: play: progress: queue for offset #{time}"
          log.message "Player: play: progress: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}], no segment at #{time}, skipping to next segment."
          nextSegment = @playlist().nextSegment segment
          timeoutHandler = =>
            LYT.loader.register 'Loading book', nextSegment
            command.cancel()
            nextSegment.done => getPlayCommand()
            nextSegment.fail -> log.error 'Player: play: progress: unable to load next segment after pause.'
          timer = setTimeout timeoutHandler, 1000
          nextSegment.done (next) =>
            clearTimeout timer
            if next?
              if next.audio is status.src and next.start - 0.1 < time < next.end + 0.1
                # Audio has progressed to next segment, so just update
                @playlist.currentSegment = next
                @updateHtml next
              else
                # The segment next requires a seek and maybe loading a
                # different audio stream.
                log.message 'Player: play: progress: switching audio file: playSegment #{next.url()}'
                # This stops playback and should ensure that we won't skip more
                # than one segment ahead if this progressHandler is called
                # again. Once playback has stopped, play the segment next.
                command.always => @playSegment next
                command.cancel()
            else
              command.cancel()
              LYT.render.bookEnd()
              log.message 'Player: play: book has ended'
      else
        # This block uses the current offset in the audio stream for
        # synchronization - a strategy that fails if there is no segment for
        # the current offset.
        log.group "Player: play: progress: segment and sound out of sync. Fetching segment for #{status.src}, offset #{time}", status
        if segment
          log.group "Player: play: progress: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]: ", segment
        else
          log.message 'Player: play: progress: no current segment set.'
        nextSegment = @playlist().segmentByAudioOffset status.src, time
        nextSegment.fail (error) ->
          # TODO: The user may have navigated to a place in the audio stream
          #       that isn't included in the book. Handle this gracefully by
          #       searching for the next segment in the audio file.
          log.error "Player: play: progress: Unable to load next segment: #{error}."
        nextSegment.done (next) =>
          if next
            log.message "Player: play: progress: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
            @updateHtml next
          else
            log.error "Player: play: progress: Unable to load any segment for #{status.src}, offset #{time}."

    @playing = true
    previous = jQuery.Deferred()
    if oldCommand = @playCommand
      # We need to cancel the previous play command before doing anything else
      # The command may either resolve or reject depending on which event hits
      # first: our cancel call or end of audio stream.
      oldCommand.always -> previous.resolve()
      oldCommand.cancel()
    else
      previous.resolve()
    result = previous.then => @playCommand = getPlayCommand()
    result

  seekSmilOffsetOrLastmark: (url, smilOffset) ->
    log.message "Player: seekSmilOffsetOrLastmark: #{url}, #{smilOffset}"
    promise = jQuery.Deferred().resolve()
    # Now seek to the right point in the book
    if not url and @book.lastmark?
      url = @book.lastmark.URI
      smilOffset = @book.lastmark.timeOffset
      log.message "Player: resuming from lastmark #{url}, smilOffset #{smilOffset}"

    # TODO: [play-controllers] Test all various cases of this structure and
    #       see if it can be simplified.
    # TODO: [play-controllers] Make sure to call updateHtml once book-player
    #       is displayed.
    if url
      promise = promise.then => @playlist().segmentByURL url
      promise = promise.then(
        (segment) =>
          log.message "Player: seekSmilOffsetOrLastmark: got segment - seeking"
          offset = segment.audioOffset(smilOffset) if smilOffset
          @seekSegmentOffset segment, offset
        (error) =>
          if url.match /__LYT_auto_/
            log.message "Player: failed to load #{url} containing auto generated bookmarks - rewinding to start"
          else
            log.error "Player: failed to load url #{url}: #{error} - rewinding to start"
          @playlist().rewind()
      )
    else
      promise = promise.then => @playlist().rewind()
      promise = promise.then (segment) => @seekSegmentOffset segment, 0
      
    promise.fail ->
      deferred.reject 'failed to find segment'
      log.error "Player: failed to find segment"
    
    promise
    

  seekSegmentOffset: (segment, offset) ->
    log.message "Player: seekSegmentOffset: #{segment.url?()}, offset #{offset}"

    segment or= @segment()
    
    result = jQuery.Deferred().resolve()
    if @playCommand and @playCommand.state is 'pending'
      # Stop playback and ensure that this part of the deferred chain resolves
      # once playback has stopped
      result = result.then =>
        @stop().then(
          -> jQuery.Deferred().resolve()
          -> jQuery.Deferred().resolve()
        )

    # See if we need to initiate loading of a new audio file
    result = result.then => segment
    result = result.then (segment) =>
      if @getStatus().src != segment.audio
        log.message "Player: seekSegmentOffset: load #{segment.audio}"
        (new LYT.player.command.load @el, segment.audio).then -> segment
      else
        jQuery.Deferred().resolve segment

    # Now move the play head
    result = result.then (segment) =>
      log.message 'Player: seekSegmentOffset: check if it is necessary to seek'
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
      if offset - 0.1 < @getStatus().currentTime < offset + 0.1
        # We're already at the right point in the audio stream
        log.message "Player: seekSegmentOffset: already at offset #{offset} - not seeking"
        jQuery.Deferred().resolve segment
      else
        # Not at the right point - seek
        log.message 'Player: seekSegmentOffset: seek'
        (new LYT.player.command.seek @el, offset).then -> segment

    # Once the seek has completed, render the segment
    result.done (segment) => @updateHtml segment

    result

  playSegment: (segment) -> @playSegmentOffset segment, null
  
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

  # If it seems that loading the provided segment will take time
  # display the loading message and pause the player.
  # Not providing a segment is allowed and will cause the loading
  # message to appear and the player to pause.
  setMetadataLoader: (segment) ->
#    if not segment or (segment.state() isnt 'resolved' or segment.audio isnt @currentAudio)
#      # Using a delay and the standard fade duration on LYT.loader.set is the
#      # most desirable, but Safari on IOS blocks right after it starts loading
#      # the sound, which means that the message appears very late.
#      # This is why we use fadeDuration 0 below.
#      LYT.loader.set 'Loading sound', 'metadata', true, 0
#      @el.jPlayer 'pause'

  navigate: (segmentPromise) ->
    
    handler = null
    if @playing
      handler = =>
        @playSegment segmentPromise
        segmentPromise
    else
      handler = =>
        @seekSegmentOffset segmentPromise
        segmentPromise

    if @playCommand
      # Stop playback and set up both done and fail handlers
      @playCommand.cancel()
      @playCommand.then handler, handler
    else
      handler()

  # Skip to next segment
  # Returns segment promise
  nextSegment: ->
    return unless @playlist()?
    if @playlist().hasNextSegment() is false
      LYT.render.bookEnd()
      delete @book.lastmark
      @book.saveBookmarks()
      return
    @navigate @playlist().nextSegment()

  # Skip to next segment
  # Returns segment promise
  previousSegment: ->
    return unless @playlist()?.hasPreviousSegment()
    @navigate @playlist().previousSegment()
  
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
    # Only return something if we have played it recently
    if lastplayed = @lastplayed
      return lastplayed if new Date() - lastplayed.updated < 10000
