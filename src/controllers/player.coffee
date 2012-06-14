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
  
  media: null
  section: null
  time: ""
  book: null #reference to an instance of book class
  playlist: null # reference to an instance of LYT.Playlist
  nextButton: null
  previousButton: null
  playIntentOffset: 0
  playIntentFlag: false
  
  autoProgression: true 
  toggleAutoProgression: null
  progressionMode: null
  
  fakeEndScheduled: false
  
  # Number of segments to preload
  segmentLookahead: 3
  
  _iBug: false
  
  playAttemptCount: 0
  gotDuration : null
  
  
  lastBookmark: (new Date).getTime()
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    @progressionMode = @PROGRESSION_MODES.MP3
    
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
        log.message 'Player: initialization complete'
        #@el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
        #todo: add a silent state where we do not play on can play   
        
        $.jPlayer.timeFormat.showHour = true
        
        # TODO: Disable next/prev buttons if there are not next/prev sections?
        jumpTo = (target) =>
          @media = target
          @renderTranscript()
          target.always =>
            return unless @media is target
            
            # Use `Math.ceil()` to prevent jPlayer from approximating to a slightly
            # earlier point in time, which will cause the wrong segment-object to be
            # loaded
            if @getStatus()?.paused
              @el.jPlayer "pause", Math.ceil(@media.start)
            else
              @el.jPlayer "play", Math.ceil(@media.start)
          
        
        @nextButton.click =>
          if @media?.hasNext()
            jumpTo @media.getNext()
          else
            @nextSection()
          false
        
        @previousButton.click =>
          if @media?.hasPrevious()
            jumpTo @media.getPrevious()
          else
            @previousSection()
          false
                     
      timeupdate: (event) =>
        #@fakeEnd(event.jPlayer.status) 
        @updateHtml(event.jPlayer.status)
      
      loadstart: (event) =>
        log.message 'Player: load start'
        
        if(@playAttemptCount < 1 and ($.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod))
          if (!LYT.config.player.IOSFirstPlay and $.mobile.activePage[0].id is 'book-play')
            # IOS will not AutoPlay...
            LYT.loader.set('Loading sound', 'metadata') 

        else if(@playAttemptCount < 1 and $.mobile.activePage[0].id is 'book-play')
          #Only make the loading sign the first time...
          LYT.loader.set('Loading sound', 'metadata') 
        
        return if $.jPlayer.platform.android

        if ($.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod)
          
          return 
        
        
        return unless jQuery.browser.webkit
        
        @updateHtml(event.jPlayer.status)
        @playOnIntent()
      
      ended: (event) =>
        if @autoProgression
          @nextSection true  
      
      pause: (event) =>
        status = event.jPlayer.status
        return unless @isIOS()
        if @_iBug
          log.warn 'we are ibug'
          #@el.jPlayer('load')
          
        else if status.duration > 0 and jQuery.jPlayer.convertTime(status.duration) is not 'NaN' and jQuery.jPlayer.convertTime(status.duration) is not '00:00' and (status.currentTime is 0 or status.currentTime is status.duration)	
          log.warn 'set ibug'
          @_iBug = true
          if @autoProgression
            @nextSection true
                   
      seeked: (event) =>
        log.message 'Player: event seeked'
        LYT.loader.close('metadata')
        @playOnIntent()

      loadedmetadata: (event) =>
        log.message 'Player: loaded metadata'
        if isNaN( event.jPlayer.status.duration )
          #alert event.jPlayer.status.duration
          @gotDuration = false
          if(@getStatus().src == @media.audio && @playAttemptCount <= LYT.config.player.playAttemptLimit )
            @el.jPlayer "setMedia", {mp3: @media.audio}
            @el.jPlayer "load"
            @playAttemptCount = @playAttemptCount + 1 
            log.message @playAttemptCount
          else if ( @playAttemptCount > LYT.config.player.playAttemptLimit)
            @gotDuration = true
            #faking that we got the duration - we don´t but need to play the file now...
            
        else
         @gotDuration = true
         @playAttemptCount = 0
         #LYT.loader.close('metadata')
         
      
      canplay: (event) =>
        log.message 'Player: event can play'
        if @gotDuration
          @gotDuration = false
          #@el.data('jPlayer').htmlElement.audio.currentTime = @playIntentOffset
          #@pause(@playIntentOffset)
          if @playIntentOffset? and @playIntentOffset > 0 and @isIOS()
            
            if LYT.config.player.IOSFirstPlay
              @pause()
          else
            @playOnIntent()
            LYT.loader.close('metadata')
        if(!@gotDuration?)
          LYT.loader.close('metadata')#windows phone 7

      
      canplaythrough: (event) =>
        log.message 'Player: event can play through'
        if @playIntentOffset? and @playIntentOffset > 0 and @isIOS()
          log.message @isIOS()
          if LYT.config.player.IOSFirstPlay
            LYT.config.player.IOSFirstPlay = false;
            @el.data('jPlayer').htmlElement.audio.currentTime = @playIntentOffset
            @el.data('jPlayer').htmlElement.audio.play()
          else
            @pause(@playIntentOffset)

            @playOnIntent()
            LYT.loader.close('metadata')  
         
        else if LYT.config.player.IOSFirstPlay and @isIOS()
          LYT.config.player.IOSFirstPlay = false;

        
        #@el.data('jPlayer').htmlElement.audio.currentTime = parseFloat("6.4");
        #log.message @el.data('jPlayer').htmlElement.audio.currentTime
        #LYT.loader.close('metadata')
        #@playOnIntent()
      
      progress: (event) =>
        #log.message 'Player: event progress'
        #LYT.loader.close('metadata')
        #@playOnIntent()
      
      error: (event) =>
        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message 'jPlayer: url error'
            $("#submenu").simpledialog({
                'mode' : 'bool',
                'prompt' : 'Der er opstået en fejl!',
                'subTitle' : 'kunne ikke hente bogen.'
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {
                  'Prøv igen': 
                    click: (event) ->
                      window.location.reload()
                    ,
                    theme: "c"
                  ,
                  'Annuller': 
                    click: (event) ->
                      $.mobile.changePage "#bookshelf"
                    ,
                    theme: "c"
                  ,
                   
                }
              
            })
            #reopen the dialog...
            #TODO: this is usually because something is wrong with the session or the internet connection, 
            # tell people to try and login again, check their internet connection or try again later
          when $.jPlayer.error.NO_SOLUTION
            log.message 'jPlayer: no solution error, you need to install flash or update your browser.'
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
        log.warn "Player: media is #{timeleft} seconds from ending but we can't handle endings - schedule a fake end just before"      
        
        setTimeout (
          => 
            @nextSection true
            @fakeEndScheduled = false ),
          (timeleft*1000)-50 
    
  pause: (time) ->
    # Pause playback
    log.message "pause at " + time

    if time?
      @playIntentOffset = time
      @el.jPlayer('pause', time)
    else
      #@playIntentOffset = null
      @el.jPlayer('pause')
  
  getStatus: ->
    # Be cautious only read from status
    @el.data('jPlayer').status
  
  silentPlay: () ->
      ###
      IOS does not allow playing audio without a direct connection to a click event
      we get around this here by starting playback of a silent audio file while 
      the book media loads.
      ###
      
      @el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
      @play(0)
  
  stop: () ->
    if @ready?
      @el.jPlayer('stop')
    
  clear: () ->
    if @ready?
      @el.jPlayer('clearMedia')
      
    
  isIOS: () ->
    if /iPad/i.test(navigator.userAgent) or /iPhone/i.test(navigator.userAgent) or /iPod/i.test(navigator.userAgent)
      return true
    else
      return false
  
  playOnIntent: () ->
    # Calls play and resets flag if the intent flag was set
    
    if @playIntentFlag
      #@playAttemptCount = 0
      log.message 'Player: play intent used offset is #{@playIntentOffset}'
      @playIntentFlag = false
      @play(@playIntentOffset, false)
      @playIntentOffset = null
  
  play: (time, setIntent = true) ->
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from
    #if time is not ""
      #@pause(time)
    
    if setIntent
      log.message 'Player: play intent flag set'
      @playIntentFlag = true
      @playIntentOffset = time
      
    else
      log.message 'Player: Play'
      @el.jPlayer('play')
        
      
  updateHtml: (status) ->
    # Continously update player rendering for current time of section
    return unless @book?
    
    @time = status.currentTime
    if(LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin)
      @updateLastMark()
    return if @media? and @media.start <= @time < @media.end
    @media = @section.mediaAtOffset @time
    
    if @media and not @getStatus()?.paused
      @preloadSegments @media
      if(LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin)
        @updateLastMark()
    
    log.warn "Player: failed to get media segment for offset #{@time}" unless @media?
    
    @renderTranscript()
  
  
  renderTranscript: () ->
    if @media?
      LYT.render.textContent(@media)
      return
    
    # If there's no media, show nothing
    jQuery("#book-text-content").empty()
  
  
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback
  
  load: (book, section = null, offset = 0, autoPlay = true) ->
    #return if book.id is @book?.id
    @book = book
    
    #LYT.loader.register "Loading book", @book
    
    log.message "Player: Loading book #{book.id}, setion #{section}, offset: #{offset}"
    @book.done =>
      jQuery("#book-duration").text @book.totalTime
      @whenReady =>
        @playlist = book.getPlaylist section
        
        @playlist.done =>
          @playSection @playlist.getCurrentSection(), offset, autoPlay
        
        @playlist.fail =>
          log.error "Player: Failed to get playlist"
  
  # Preload segments - stay a few steps ahead of playback  
  # This will preload any images contained in the segments
  preloadSegments: (segment) ->
    preloadCounter = @segmentLookahead
    while preloadCounter--
      segment = segment.getNext() if segment.hasNext()
  
  playSection: (section, offset = 0, autoPlay = true) ->
    
    #return if section is @section
    @section = section
    
    LYT.loader.register "Loading book", @section
    
    @section.done =>
      log.message "Player: Playlist current section #{@section.id}"
      jQuery("#player-chapter-title h2").text section.title
      
      # Preload the next/prev sections
      @playlist.getNextSection() if @playlist.hasNextSection()
      @playlist.getPreviousSection() if @playlist.hasPreviousSection()
      
      # Get the media obj
      @media = @section.mediaAtOffset offset
      
      @renderTranscript()
      
      if @media?
        # TODO: Handle segment-load failures
        @media.always =>
          @el.jPlayer "setMedia", {mp3: @media.audio}
          # Start preloading the next segments
          @preloadSegments @media
      else
        # If no media was found, check whether the section has a single,
        # unambiguous MP3 file, we can load instead
        log.warn "Player: failed to get media"
        mp3s = @section.getAudioUrls()
        if mp3s.length isnt 1
          # No media, no MP3: Just give up...
          log.error "Player: Couldn't determine MP3 file"
          return
        @el.jPlayer "setMedia", {mp3: mp3s.pop()}
      
      # Load the mp3 that was set above
      @el.jPlayer "load"
      
      # TODO: Handle segment-load failures
      @media.always =>
        if autoPlay
          @play offset
        else
          @pause offset
      
    @section.fail ->
      log.error "Player: Failed to load section #{section}"
  
  
  nextSection: (autoPlay = false) ->
    #@playlist.
    if @playlist?.hasNextSection() is false
      LYT.render.bookEnd()

    return null unless @playlist?.hasNextSection()
    section = @playlist.getNextSection()
    log.message section
    
    #if $.mobile.activePage.attr('id') is 'book-play'
    #  $.mobile.changePage "#book-play?book=#{@book.id}&section=#{section.id}", {transition: 'none'}
    #else
    @playSection @playlist.next(), 0, (autoPlay or @getStatus()?.paused is false)

  previousSection:(autoPlay = false) ->

    return null unless @playlist?.hasPreviousSection()
    section = @playlist.getPreviousSection()
    
    #if $.mobile.activePage.attr('id') is 'book-play'
    #  $.mobile.changePage "#book-play?book=#{@book.id}&section=#{section.id}", {transition: 'none'}
    #else
    @playSection @playlist.previous(), 0, (autoPlay or @getStatus()?.paused is false)
  
  updateLastMark: (force = false) ->
    return unless @book? and @section?
    now = (new Date).getTime()
    interval = LYT.config.player?.lastmarkUpdateInterval or 10000
    return unless force or not @lastBookmark or now-@lastBookmark > interval
    if @getStatus().currentTime is 0 or @playIntentOffset > @getStatus().currentTime
      return
    @book.setLastmark @section.id, @getStatus().currentTime
    @lastBookmark = now
  
  getCurrentlyPlaying: ->
    return null unless @book? and @section?
    book:    @book.id
    section: @section.id
    
  getCurrentlyPlayingUrl: (absolute=true, resolution='book') ->
    # Returns the url of the currently playing book
    # Accepts a resolution a string that is either 'book', 'section' or 'offset'
    # Defaults to 'book'
    # If absolute is true it returns the full url with domain
    
    return null unless @book? and @section?
    
    url = "#book-play?book=#{@book.id}"
    if resolution in ['section', 'offset']
      url = url + "&section=#{@section.id}"  
      if resolution is 'offset' and @time?
        url = url + "&offset=#{@time}"
    
    if absolute
      if document.baseURI?
        return document.baseURI + url
      else
        return window.location.hostname+'/'+ url 
    
    return url
