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
    @nccDocument.pipe () =>
      console.log this
      deferred.resolve(this)
    this

  currentSection: -> @currentSegment?.section

  hasNextSegment: -> @currentSegment?.hasNext() or hasNextSection()

  hasPreviousSegment: -> @currentSegment?.hasPrevious() or hasPreviousSection()

  hasNextSection: -> @currentSection()?.next?

  hasPreviousSection: -> @currentSection()?.previous?

  load: (segment) ->
    segment.done (segment) => @currentSegment = segment
    segment

  rewind: -> @load @nccDocument.firstSegment()

  nextSection: -> @load @currentSection().next()

  previousSection: -> @load @currentSection().previous()
    
  nextSegment: ->
    if @currentSegment.hasNext()
      return @load @currentSection(), @currentSegment.next
    else
      if @currentSection().hasNext()
        return @load @currentSection().next.firstSegment()
      else
        return null
    
  previousSegment: ->
    if @currentSegment.hasPrevious()
      return @load @currentSection(), @currentSegment.previous
    else
      if @currentSection().hasPrevious()
        return @load @currentSection().previous.firstSegment()
      else
        return null

  # Will rewind to start if no url is provided
  segmentByURL: (url) ->
    if url?
      if segment = @nccDocument.getSegmentByURL(url)
        return @load segment
    else
      return @rewind()

  segmentByOffset: (offset = 0) ->
    if segment = @nccDocument.getSegmentByOffset(offset)
      return @load segment
