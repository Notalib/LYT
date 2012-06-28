# Requires `/common`  

# -------------------

# This class models a "playlist" of book sections
# Responsible for navigation in- and load of segments (and their sections)

class LYT.Playlist
  
  constructor: (@book) ->
    # Make the playlist a promise waiting for the ncc document to load
    deferred = jQuery.Deferred()
    deferred.promise this
    @nccDocument = @book.nccDocument
    @nccDocument.done => deferred.resolve this
    @nccDocument.fail => deferred.reject()
    this

  currentSection: -> @currentSegment?.section

  hasNextSegment: -> @currentSegment?.hasNext() or @hasNextSection()

  hasPreviousSegment: -> @currentSegment?.hasPrevious() or @hasPreviousSection()

  hasNextSection: -> @currentSection()?.next?

  hasPreviousSection: -> @currentSection()?.previous?

  load: (segment) ->
    segment.done (segment) =>
    	if segment?
        @currentSegment = segment
    segment

  rewind: -> @load @nccDocument.firstSegment()

  nextSection: ->
    @currentSection().next.load()
    @load @currentSection().next.firstSegment()

  previousSection: ->
    @currentSection().previous.load()
    @load @currentSection().previous.firstSegment()
    
  nextSegment: ->
    if @currentSegment.hasNext()
      return @load @currentSegment.next
    else
    	return @nextSection()
    
  previousSegment: ->
    if @currentSegment.hasPrevious()
      return @load @currentSegment.previous
    else
      @currentSection().previous.load()
      @load @currentSection().previous.lastSegment()

  # Will rewind to start if no url is provided
  segmentByURL: (url) ->
    if url?
      if segment = @nccDocument.getSegmentByURL(url)
        return @load segment
    else
      return @rewind()

  segmentByOffset: (offset = 0) ->
    if segment = @currentSection()?.getSegmentByOffset(offset)
      return @load segment
    else
      log.error "Playlist: segmentByOffset called with offset #{offset} - unable to find any segment"
