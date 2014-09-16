# Requires `/common`
# Requires `/support/lyt/loader`
# Requires `/models/member/settings`
# ----------------------------------

# ########################################################################### #
# Handles playback of current media and timing of transcript updates          #
# ########################################################################### #

LYT.player =

  # Attributes ############################################################## #

  ready: false
  el: null
  book: null #reference to an instance of book class
  playing: null
  refreshTimer: null
  firstPlay: true
  playbackRate: 1
  lastBookmark: (new Date).getTime()
  inSkipState: false
  showingPlay: true # true if the play triangle button is shown, false otherwise
  playLoader: null

  # Be cautious only read from the returned status object
  getStatus: -> @el.data('jPlayer').status

  dumpStatus: -> log.message field + ': ' + LYT.player.getStatus()[field] for field in ['currentTime', 'duration', 'ended', 'networkState', 'paused', 'readyState', 'src', 'srcSet', 'waitForLoad', 'waitForPlay']

  # Register callback to call when jPlayer is ready
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback


  # Initialization ########################################################## #

  # General initialization
  init: ->
    log.message 'Player: starting initialization'
    @el = jQuery('#jplayer')
    @playbackRate = LYT.settings.get('playbackRate')

    jPlayerParams =
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html'
      ready: =>
        @setupAudioInstrumentation()
        @setupUi()
        LYT.instrumentation.record 'ready', @getStatus()
        log.message "Player: event ready: paused: #{@getStatus().paused}"

        @setPlaybackRate @playbackRate
        @ready = true

    jPlayerParams.warning = (event) =>
      LYT.instrumentation.record 'warning', event.jPlayer.status
      log.error "Player: event warning: #{event.jPlayer.warning.message}, #{event.jPlayer.warning.hint}", event

    jPlayerParams.error = (event) =>
      LYT.instrumentation.record 'error', event.jPlayer.status
      log.error "Player: event error: #{event.jPlayer.error.message}, #{event.jPlayer.error.hint}", event

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

    # Instrument every possible event that jPlayer offers that doesn't already
    # have a handler.
    instrument = (eventName) ->
      jPlayerParams[eventName] or= (event) ->
        LYT.instrumentation.record eventName, event.jPlayer.status
    instrument eventName for eventName, jPlayerName of $.jPlayer.event

    @el.jPlayer jPlayerParams

  # Sets up instrumentation on the audio element inside jPlayer
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

  # Sets up bindings for the user interface
  setupUi: ->
    $.jPlayer.timeFormat.showHour = true

    @showPlayButton()

    $('.lyt-pause').click =>
      LYT.instrumentation.record 'ui:stop'
      if not @showingPlay
        @showPauseButton()

      @stop()

    $('.lyt-play').click (e) =>
      LYT.instrumentation.record 'ui:play'
      if @playClickHook
        @playClickHook(e).done => @play()
      else
        @play()

    $('a.next-section').click =>
      log.message "Player: next: #{@currentSegment.next?.url()}"
      LYT.instrumentation.record 'ui:next'
      @playNextSegment()

    $('a.previous-section').click =>
      log.message "Player: previous: #{@currentSegment.previous?.url()}"
      LYT.instrumentation.record 'ui:previous'
      @playPreviousSegment()

    $('a.forward15').click =>
      log.message "Player: forward15:"
      LYT.instrumentation.record 'ui:fastforward15'
      @playheadSeek(15)
    $('a.back15').click =>
      log.message "Player: rewind15:"
      LYT.instrumentation.record 'ui:rewind15'
      @playheadSeek(-15)

    Mousetrap.bind 'alt+ctrl+space', =>
      if @playing
        @stop()
      else
        @play()
      return false

    Mousetrap.bind 'alt+right', =>
      @playNextSegment()
      return false

    Mousetrap.bind 'alt+left', =>
      @playPreviousSegment()
      return false

    # FIXME: add handling of section jumps
    Mousetrap.bind 'alt+ctrl+n', ->
      log.message "next section"
      return false

    Mousetrap.bind 'alt+ctrl+o', ->
      log.message "previous section"
      return false


  # Main methods ############################################################ #

  # Load a book and seek to position provided by:
  # url:        url pointing to par or seq element in SMIL file.
  # smilOffset: SMIL offset relative to url.
  # play:       flag indicating if the book should start playing after loading
  #             has finished.
  # Returns a promise that resolves with a loaded book.
  load: (book, url = null, smilOffset, play) ->
    log.message "Player: Load: book #{book}, " +
      "segment #{url}, smilOffset: #{smilOffset}, play #{play}"

    loading = @stop()
      .then =>
        if book is @book?.id then @book else LYT.Book.load book
      .then (book) =>
        # Setting @book should be done after seeking has completed, but the
        # dependency on the books playlist and firstplay issue prohibits this.
        @book = book

        # If the book doesn't have a lastmark, we're in skip state which
        # mean that we'll skip all "meta-content" sections in the book when
        # played chronologically
        @inSkipState = not book.lastmark?
        jQuery("#book-duration").text book.totalTime
      .then =>
        if @firstPlay and not Modernizr.autoplayback
          log.message "Player: We are in firstPlay mode and no Modernizr.autoplayback"
          # The play click handler will call @playClickHook which enables the
          # player to start seeking.
          @playClickHook = (e) =>

            # If this is the first click by the user (on an iOS device), the
            # playbackrate tests will fire off at the same time as this. For
            # whatever reason, that makes the silentplay command stall after two
            # timeupdate/progress events, and we never get any further. Therefore
            # we need to stop the bubbling of the event
            e.stopImmediatePropagation()
            e.preventDefault()

            @playClickHook = null
            silentplay = new LYT.player.command.silentplay @el
            LYT.loader.register 'Initializing', silentplay
            LYT.render.disablePlayerNavigation()

            silentplay.then =>
              log.message 'Player: load: silentplay done - will load (and possibly seek) now'
              @seekSmilOffsetOrLastmark(url, smilOffset).always ->
                LYT.render.disablePlayerNavigation()
        else
          log.message 'Player: chaining seeked because we are not in firstPlay mode'
          @seekSmilOffsetOrLastmark(url, smilOffset).always ->
            LYT.render.disablePlayerNavigation()
      .then =>
        log.message "Player: book #{@book.id} loaded"
        # Never start playing if firstplay flag set
        @play() if play and not @firstPlay

        # We don't want to return the result of @play() since that is a
        # promise that resolves when playing *ends* (We should reconsider how
        # fortunate this is)
        return true
      .then =>
        LYT.render.enablePlayerNavigation()
        @book
      .fail (err) ->
        log.error "Player: failed to load book, reason #{err}"

    # Register loading spinner
    LYT.loader.register 'Loading book', loading.promise()
    loading

  # Stops playback but doesn't change the playing flag
  wait: ->
    log.message 'Player: wait'
    ok = jQuery.Deferred().resolve()
    if command = @playCommand
      command.done => @playCommand = null if @playCommand is command
      command.cancel()
      return command.then(
        -> ok
        -> ok
      )
    else
      return ok

  # This is a public method - stops playback
  # The stop command returns the last play command or null in case there
  # isn't any.
  stop: ->
    log.message 'Player: stop'
    @playing = false
    @wait()

  setPlaybackRate: (playbackRate = @playbackRate) ->
    log.message "Player: setPlaybackRate: (#{@playbackRate} -> #{playbackRate})"
    # playbackRate is set on the audio element on the timeupdate-event defined in @init-function

    @playbackRate = playbackRate

    if not Modernizr.playbackrate and Modernizr.playbackratelive
      # Workaround for IOS6 that doesn't alter the perceived playback rate
      # before starting and stopping the audio (issue #480)
      jPlayer = @el.data 'jPlayer'
      audio = jPlayer.htmlElement.audio

      if @playing
        @stop().then =>
          audio.playbackRate = @playbackRate
          @play()
      else
        @play().progress =>
          audio.playbackRate = @playbackRate
          @stop()

     if command = @playCommand
       command.setPlaybackRate @playbackRate

  # Starts playback
  play: ->
    command = null
    nextSegment = null
    # TODO: Refactor to make getPlayCommand take a segment as argument
    #       This should eliminate the complicated logic inside getPlayCommand
    #       that has to take into account that nextSegment may have changed.
    getPlayCommand = =>
      @playLoader.resolve() if @playLoader && @playLoader.state() != 'resolved'

      @playLoader = jQuery.Deferred()
      LYT.loader.register 'Loading sound', @playLoader
      LYT.render.disablePlayerNavigation()
      command = new LYT.player.command.play @el
      command.setPlaybackRate @playbackRate
      command.progress progressHandler
      command.done =>
        log.group 'Player: play: play command done.', command.status()
        # Audio stream finished. Put on the next one.
        if nextSegment?.state() is 'pending'
          log.message 'Player: play: play: waiting for next segment'
          nextSegment.done (segment) =>
            @playSegment segment
        else
          @playNextSegment()
      command.always =>
        @showPlayButton() unless @playing or @showingPlay

    progressHandler = (status) =>
      unless @book?
        log.message "play: progressHandler: no @book"
        return

      if @playLoader && @playLoader.state() != 'resolved'
        LYT.render.enablePlayerNavigation()
        @playLoader.resolve()

      @firstPlay = false if @firstPlay

      # If this is a newly loaded file, we set the user's playback rate
      if @newAudioLoaded
        #@setPlaybackRate()
        @newAudioLoaded = false

      if @showingPlay
        @showPauseButton()

      # Don't do anything else if we're already moving to a new segment
      if nextSegment?.state() is 'pending'
        log.message "play: progressHandler: nextSegment is pending"
        return

      time = status.currentTime

      # Update lastmark if necessary
      @updateLastMark()

      # We move to the segment at the current time interval if the current
      # segment is in the past or the current time is within two seconds in the
      # past of the current segment - If not we assume that the user has seeked
      segment = @currentSegment
      if segment? and status.src == segment.audio and
         segment.start < time + 0.1 < segment.end + 2
        # Do nothing if we're playing the right segment
        return if time < segment.end

        # If there're no more segments to play, the book has finished
        if not @hasNextSegment()
          command.cancel()
          LYT.render.bookEnd()
          log.message 'Player: play: book has ended'
          return

        # Segment and audio are not in sync, move to next segment
        # This block uses the current segment for synchronization.
        log.message "Player: play: progress: queue for offset #{time}"
        log.message "Player: play: progress: current segment: " +
          "[#{segment.url()}, #{segment.start}, #{segment.end}, " +
          "#{segment.audio}], no segment at #{time}, skipping to next segment."

        # A timeout handler if the next segment is loading slowly (over 1000ms)
        timeoutHandler = =>
          LYT.loader.register 'Loading book', nextSegment
          LYT.render.disablePlayerNavigation()
          nextSegment.always -> LYT.render.enablePlayerNavigation()
          nextSegment.done ->
            getPlayCommand()
          nextSegment.fail -> log.error "Player: play: progress: unable to " +
                                        "load next segment after pause."
          command.cancel()

        # If we're in skip state, and about to change section
        if @inSkipState and not segment.hasNext()
          log.message "Player: play: progress: In skip state"
          nextSection = @book.getSectionBySegment segment

          skips = 0
          while (nextSection = nextSection.next)?.metaContent
            skips++

          log.message "Player: play: Skipping #{skips} meta-content sections"
          nextSegment = nextSection.load().firstSegment()
          nextSegment.then =>
            command.cancel()
            command.always =>
              clearTimeout timer
              @playSegment nextSegment
          return

        isNextInSync = (seg) =>
          log.message "Player: play: isNextInSync: #{seg.audio}"
          nextSegment = @_getNextSegment seg
          nextSegment.then (next) =>
            # If the segment fits in the time interval we simply update the view
            if next.start - 0.01 <= time < next.end + 0.01 and next.audio is status.src
              clearTimeout timer
              @_setCurrentSegment next
              @updateHtml next

            # If the audio file has changed, or the next segment jumps more
            # than two seconds forwards or backwards, we skip/seek to it
            else if next.audio isnt status.src or
                    next.end < time - 2 or
                    next.start > time + 2
              clearTimeout timer
              command.always => @playSegment next
              command.cancel()
            # If neither of above we try the next segment
            else
              isNextInSync next

        # Kick it off
        timer = setTimeout timeoutHandler, 1000
        isNextInSync segment
      else
        # This block uses the current offset in the audio stream for
        # synchronization - a strategy that fails if there is no segment for
        # the current offset.
        log.group "Player: play: progress: segment and sound out of sync. Fetching segment for #{status.src}, offset #{time}", status
        if segment
          log.group "Player: play: progress: current segment: [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]: ", segment
        else
          log.message 'Player: play: progress: no current segment set.'
        nextSegment = @book.segmentByAudioOffset @currentSection(), status.src, time, 0.1
        nextSegment.fail (error) ->
          # TODO: The user may have navigated to a place in the audio stream
          #       that isn't included in the book. This should be handled by
          #       changing the seek bar to make it impossible to click on
          #       points in the stream that aren't in the book.
          log.error "Player: play: progress: Unable to load next segment: #{error}."
        nextSegment.then (next) =>
          if next
            log.message "Player: play: progress: (#{status.currentTime}s) moved to #{next.url()}: [#{next.start}, #{next.end}]"
            @_setCurrentSegment next
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

    previous.then =>
      @playCommand = getPlayCommand()

  seekSmilOffsetOrLastmark: (url, smilOffset) ->
    log.message "Player: seekSmilOffsetOrLastmark: #{url}, #{smilOffset}"

    # Now seek to the right point in the book
    if not url and @book.lastmark?
      url = @book.lastmark.URI
      smilOffset = @book.lastmark.timeOffset
      log.message "Player: resuming from lastmark #{url}, smilOffset #{smilOffset}"

    promise = $.Deferred()
    $.when(url)
      .then (url) =>
        if url then @book.segmentByURL(url) else @book.firstSegment()
      .then (segment) =>
        log.message "Player: seekSmilOffsetOrLastmark: got segment - seeking"
        offset = segment.audioOffset(smilOffset) if smilOffset

        # Check if it has beginSection or not. If not we need to set the
        # correct section title
        if not segment.beginSection?
          segment.sectionTitle = @book.getSectionBySegment(segment)?.title

        @seekSegmentOffset(segment, offset).then -> promise.resolve()
      .fail (error) =>
        log.error "Player: failed to load url #{url}: #{error} - rewinding to start"
        @book.firstSegment().then (segment) =>
          @seekSegmentOffset(segment).then -> promise.resolve()

    promise


  seekSegmentOffset: (segmentPromise = @currentSegment, offset) ->
    log.message "Player: seekSegmentOffset: #{segmentPromise.url?()}, offset #{offset}"

    # If this takes a long time, put up the loader
    # The timeout ensures that we don't display the loader if seeking
    # without switching audio stream, since that is a very fast operation
    # which would cause the loader to flicker.
    # TODO: Only set the loader if switching audio is necessary.
    setTimeout(
      =>
        LYT.loader.register 'Loading sound', result
        LYT.render.disablePlayerNavigation()
        result.always -> LYT.render.enablePlayerNavigation()
      500
    )

    # Stop playback and ensure that this part of the deferred chain resolves
    # once playback has stopped
    if @playCommand and @playCommand.state is 'pending'
      initial = @stop()
    else
      initial = jQuery.Deferred().resolve()

    # See if we need to initiate loading of a new audio file
    result = initial
      .then -> segmentPromise # Wait for the segmentPromise to be fully loaded
      .then (segment) =>
        if @getStatus().src != segment.audio
          log.message "Player: seekSegmentOffset: load #{segment.audio}"
          throw 'Player: seekSegmentOffset: segment has no audio' unless segment.audio

          (new LYT.player.command.load @el, segment.audio).then =>
            @newAudioLoaded = true
            segment
        else
          jQuery.Deferred().resolve segment
      .then (segment) => # Now move the play head
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
        else
          # Not at the right point - seek
          log.message 'Player: seekSegmentOffset: seek'
          seek = new LYT.player.command.seek @el, offset

      .then => # Once the seek has completed, render the segment
        segmentPromise.done (segment) =>
          @updateHtml segment
          @_setCurrentSegment segment

  # Plays the given segment
  playSegment: (segment) -> @playSegmentOffset segment, null

  # Seeks seconds forward or backward
  playheadSeek: (seconds) ->
    seek = =>
      currTime = @getStatus().currentTime
      duration = @getStatus().duration
      seekTime = currTime + seconds

      deferred = $.Deferred()
      # if time is within boundaries of current section
      if(seekTime >= 0 && seekTime < duration)
        @wait()
          .then =>
            new LYT.player.command.seek @el, seekTime
          .done =>
            @play() if @playing
            deferred.resolve()
          .fail =>
            @play() if @playing
            deferred.reject()

      else if seekTime < 0

        # if seekTime is less than 0 we are seeking a segment in previous section if available
        seekTime = seekTime - currTime
        seekTime = seekTime + (currTime - @currentSegment.start)
        @wait().then =>
          prevSegment = (seg) =>
            prev = @_getPreviousSegment seg
            prev.done (prev) =>
              seekTime = seekTime + prev.duration()
              if (seekTime >= 0)
                @seekSegmentOffset(prev, seekTime+prev.start).then =>
                  @play() if @playing
                  deferred.resolve()
              else
                prevSegment prev

            # If no previous section found and still seconds left to rewind play from start
            prev.fail =>
              @seekSegmentOffset(seg, seg.start).then =>
                @play() if @playing
                deferred.reject()

          prevSegment @currentSegment

      else if seekTime > duration
        # if seekTime greater than current section duration we are seeking a segment in next section if available
        @wait().then =>
          seconds = seconds - (@currentSegment.end - currTime)
          nextSegment = (seg) =>
            next = @_getNextSegment seg
            next.done (next) =>
              if (seconds < next.duration())
                # segment found
                @seekSegmentOffset(next, seconds).then =>
                  @play() if @playing
                  deferred.resolve()
              else
                seconds = seconds-next.duration()
                nextSegment next
            next.fail =>
              @seekSegmentOffset(seg, seg.end).then =>
                @play() if @playing
                deferred.reject()

          nextSegment @currentSegment

      deferred.promise()

    # We're chaining seek calls, so that they don't mess each other up.
    # If multiple seek calls are active at the same time, they'll all
    # interact with the same jPlayer audio element, which is bad news
    if @currentSeek
      @currentSeek = @currentSeek.then(seek, seek)
    else
      @currentSeek = seek()


  # Plays the next segment in queue, and updates currentSegment
  playNextSegment: ->
    if not @hasNextSegment()
      LYT.render.bookEnd()
      delete @book.lastmark
      @book.saveBookmarks()
    else
      next = @_getNextSegment()
      @navigate next

  # Plays the previous segment in queue, and updates currentSegment
  playPreviousSegment: ->
    return unless @hasPreviousSegment()
    prev = @_getPreviousSegment()
    @navigate prev

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

  navigate: (segmentPromise) ->
    if @playing
      handler = =>
        segmentPromise.done (segment) =>
          @playSegment segment or segmentPromise
    else
      handler = =>
        segmentPromise.done (segment)=>
          @seekSegmentOffset segment or segmentPromise

    if @playCommand
      # Stop playback and set up both done and fail handlers
      @playCommand.cancel()
      @playCommand.then handler, handler
    else
      handler()

  currentSection: -> @book.getSectionBySegment @currentSegment

  hasNextSegment: -> @currentSegment?.hasNext() or @hasNextSection()

  hasPreviousSegment: -> @currentSegment?.hasPrevious() or @hasPreviousSection()

  hasNextSection: -> @currentSection()?.next?

  hasPreviousSection: -> @currentSection()?.previous?

  _setCurrentSegment: (segment) ->
    log.message "Player: _setCurrentSegment: queue segment #{segment.url?() or '(N/A)'}"
    segment.done (segment) =>
      if segment?
        log.message "Player: _setCurrentSegment: set currentSegment to " +
          "[#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]"
        @currentSegment = segment
    segment

  _getNextSegment: (currsegment = @currentSegment) ->
    return jQuery.Deferred().reject() unless currsegment

    if currsegment.hasNext()
      currsegment.next.load()
    else
      section = @book.getSectionBySegment currsegment
      return jQuery.Deferred().reject() if not section.next
      section
        .next
        .load()
        .firstSegment()

  _getPreviousSegment: (currsegment = @currentSegment) ->
    return jQuery.Deferred().reject() unless currsegment

    if currsegment.hasPrevious()
      currsegment.previous.load()
    else
      section = @book.getSectionBySegment (currsegment)
      return jQuery.Deferred().reject() if not section.previous
      section
        .previous
        .load()
        .then (section) -> section.lastSegment()
        .then (last) -> last.load()

  updateLastMark: (force = false, segment) ->
    return unless LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin
    return unless (segment or= @currentSegment)
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


  # View related methods - should go into a file akin to render.coffee

  setFocus: ->
    for button in [$('.lyt-pause'), $('.lyt-play')]
      unless button.css('display') is 'none'
        button.addClass('ui-btn-active').focus()

  showPlayButton: ->
    @showingPlay = true
    $('.lyt-pause').css 'display', 'none'
    $('.lyt-play').css('display', '')
    @setFocus()

  showPauseButton: ->
    @showingPlay = false
    $('.lyt-play').css 'display', 'none'
    $('.lyt-pause').css('display', '')
    @setFocus()

  refreshContent: (now = false) ->
    # Using timeout to ensure that we don't call updateHtml too often
    refreshHandler = =>
      if @book and segment = @currentSegment
        @updateHtml segment
    clearTimeout @refreshTimer if @refreshTimer
    if now
      refreshHandler.call @
    else
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
