# This module handles playback of current media and timing of transcript updates

LYT.player =
  
  ready: false 
  jplayer: null
  el: jQuery("#jplayer")
  media: null #id, start, end, text
  time: ""
  book: null #reference to an instance of book class
  
  # todo: consider array of all played sections and a few following
  
  setup: =>
    # Initialize jplayer and set ready True when ready
    @jplayer = @el.jPlayer
      ready: =>      
        @ready = True
      
      swfPath: "/lib/jplayer"
      supplied: "mp3"
      solution: 'html, flash'
      
  pause: =>
    # Pause current media
    @jplayer('pause')
  
  stop: =>
    # Stop playing and stop downloading current media file
    @jplayer('stop')
    @jplayer('clearmedia')
  
  play: (time) =>
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from 
    # when media was paused, else from the beginning.
    if not time?
      @jplayer('play')
    else
      @jplayer('play', time)
  
  update: (time) =>
    # Continously update media for current time of section
    @time = time
    
    if not @media?
      # get media if we don't have it yet    
      @book.mediaFor().done (media) =>
        if not media?
          @media = media
        else
          #todo:error
    else if @media.end < @time
      @book.mediaFor(@section, @time).done (media) =>
        if not media?
          if @media.audio is not media.audio
             @jplayer('setmedia', media)
             @play()
          
          @media = media
          
    if @currentTranscript.end < @currentTime
      #LYT.gui.hideTranscript("")
      
    else if @currentTranscript.start >= @currentTime
      #LYT.gui.updateTranscript("")
      #LYT.gui.showTranscript("")
     
  loadBook: (book, section, offset) =>
    if @ready
      @book = book
      
      # select section or take first off book.sections
         
      @el.bind jQuery.jPlayer.event.timeupdate, (event) =>
         @update(event.jPlayer.status.currentTime)
      
  nextPart: () ->
    @stop()
    # get next part
    @load()
    
  previousPart: () ->
    @stop()
    # get next part
    @load()
     

  