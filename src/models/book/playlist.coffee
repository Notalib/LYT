# Requires `/common`  

# -------------------

# This class models a "playlist" of book sections

class LYT.Playlist
  
  constructor: (@book, initialSegmentURL = null) ->
    @nccDocument = @book.nccDocument
    
    deferred = jQuery.Deferred()
    deferred.promise this
    currentSegment = @setCurrentSegment initialSegmentURL

    unless currentSegment
      log.error "Playlist: Failed to find initial segment"
      deferred.reject this
      return
    
    current.done =>
      log.message "Playlist: Loaded initial segment"
      deferred.resolve this
    
    current.fail =>
      log.error "Playlist: Failed to load initial segment"
      deferred.reject this
  
    hasNextSegment: -> @currentSegment.hasNext() or hasNextSection()

    hasPreviousSegment: -> @currentSegment.hasPrevious() or hasPreviousSection()
  
    hasNextSection: -> @currentSection.next?
  
    hasPreviousSection: -> @currentSection.previous?
  
    loadCurrentSection: ->
      if @currentSection?
        @currentSegment = null
        return @currentSection.load()
      else
        return null

    rewind: ->
      @currentSegment = @nccDocument.firstSegment()
      @currentSection = @currentSegment.section
      return @currentSegment

  	nextSection: ->
      @currentSection = @currentSection.next()
      return @loadCurrentSection
  
    previousSection: ->
      @currentSection = @currentSection.previous()
      return @loadCurrentSection
      
    nextSegment: ->
      if @currentSegment.hasNext()
        @currentSegment = @currentSegment.getNext()
        return @currentSegment
      else
        if @currentSection.hasNext()
          @currentSegment = @nextSection.firstSegment()
          return @currentSegment
        else
          return null
      
    previousSegment: ->
      if @currentSegment.hasPrevious()
        @currentSegment = @currentSegment.getPrevious()
        return @currentSegment
      else
        if @currentSection.hasPrevious()
          @currentSegment = @previousSection.lastSegment()
          return @currentSegment
        else
          return null
  
    # Will rewind to start if no url is provided    
    setCurrentSection: (url) ->
    	if url?
        @currentSection = @nccDocument.getSectionByURL(url)
        @currentSegment = @currentSection?.firstSegment()
      else
      	@currentSection = @nccDocument.firstSegment().section
      
      log.warn "Playlist: Couldn't find section" unless @currentSection?

    # Will rewind to start if no url is provided    
    setCurrentSegment: (url) ->
    	if url?
        @currentSegment = @nccDocument.getSegmentByURL(url)
      else
        @currentSegment = @nccDocument.firstSegment()
      if @currentSegment?
        @currentSection = @currentSegment.section
      else
      	log.warn "Playlist: Couldn't find segment"


