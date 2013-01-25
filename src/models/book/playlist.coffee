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
    @nccDocument.fail (status, error) -> deferred.reject "NCCDocument: #{status}, #{error}"
    this

  currentSection: -> @currentSegment?.section

  hasNextSegment: -> @currentSegment?.hasNext() or @hasNextSection()

  hasPreviousSegment: -> @currentSegment?.hasPrevious() or @hasPreviousSection()

  hasNextSection: -> @currentSection()?.next?

  hasPreviousSection: -> @currentSection()?.previous?

  load: (segment) ->
    log.message "Playlist: load: queue segment #{segment.url?() or '(N/A)'}"
    segment.done (segment) =>
      if segment?
        log.message "Playlist: load: set currentSegment to [#{segment.url()}, #{segment.start}, #{segment.end}, #{segment.audio}]"
        @currentSegment = segment
    segment

  rewind: -> @load @nccDocument.firstSegment()

  nextSection: ->
    # FIXME: loading segments is the responsibility of the section each
    # each segment belongs to.
    if @currentSection().next
      @currentSection().next.load()
      @load @currentSection().next.firstSegment()

  previousSection: ->
    # FIXME: loading segments is the responsibility of the section each
    # each segment belongs to.
    @currentSection().previous.load()
    @load @currentSection().previous.firstSegment()
    
  nextSegment: ->
    if @currentSegment.hasNext()
      # FIXME: loading segments is the responsibility of the section each
      # each segment belongs to.
      @currentSegment.next.load()
      return @load @currentSegment.next
    else
      return @nextSection()
    
  previousSegment: ->
    if @currentSegment.hasPrevious()
      # FIXME: loading segments is the responsibility of the section each
      # each segment belongs to.
      @currentSegment.previous.load()
      return @load @currentSegment.previous
    else
      if @currentSection().previous
        @currentSection().previous.load()
        @currentSection().previous.pipe (section) =>
          @load section.lastSegment()

  # Will rewind to start if no url is provided
  segmentByURL: (url) ->
    if url?
      if segment = @nccDocument.getSegmentByURL(url)
        return @load segment
    else
      return @rewind()

  # Get the following segment if we are very close to the end of the current
  # segment and the following segment starts within the fudge limit.
  _fudgeFix: (offset, segment, fudge = 0.1) ->
    segment = segment.next if segment.end - offset < fudge and segment.next and offset - segment.next.start < fudge
    return segment

  segmentByAudioOffset: (audio, offset = 0, fudge = 0.1) ->
    if not audio? or audio is ''
      log.error 'Playlist: segmentByAudioOffset: audio not provided'
      return jQuery.Deferred().reject('audio not provided')
    deferred = jQuery.Deferred()
    promise = @searchSections (section) =>
      for segment in section.document.segments
        # Using 0.01s to cover rounding errors (yes, they do occur)
        if segment.audio is audio and segment.start - 0.01 <= offset < segment.end + 0.01
          segment = @_fudgeFix offset, segment
          # FIXME: loading segments is the responsibility of the section each
          # each segment belongs to.
          log.message "Playlist: segmentByAudioOffset: load segment #{segment.url()}"
          segment.load()
          return @load segment
    promise.done (segment) ->
      segment.done -> deferred.resolve segment
    promise.fail -> deferred.reject()
    deferred.promise()

  # Search for sections using a callback handler
  # Returns a jQuery promise.
  # handler: callback that will be called with one section at a time.
  #          If handler returns anything trueish, the search will stop
  #          and the promise will resolve with the returned trueish.
  #          If the handler returns anything falseish, the search will
  #          continue by calling handler once again with a new section.
  #
  #          If the handler exhausts all sections, the promise will reject
  #          with no return value.
  #
  # start:   the section to start searching from (default: current section).
  searchSections: (handler, start = @currentSection()) ->

    # The use of iterators below can easily be adapted to the Strategy
    # design pattern, accommodating other search orders. 

    # Generate an iterator with start value start and nextOp to generate
    # the next value.
    # Will stop calling nextOp as soon as nextOp returns null or undefined
    makeIterator = (start, nextOp) ->
      current = start
      return ->
        result = current
        current = nextOp current if current?
        return result

    # This iterator configuration will make the iterator return this:
    # this
    # this.next
    # this.previous
    # this.next.next
    # this.previous.previous
    # ...
    iterators = [
      makeIterator start, (section) -> section.previous
      makeIterator start, (section) -> section.next
    ]

    # This iterator will query the iterators in the iterators array one at a
    # time and remove them from the array if they stop returning anything.
    i = 0
    iterator = ->
      result = null
      while not result? and i < iterators.length
        result = iterators[i].apply()
        iterators.splice(i) if not result?
        i++
        i %= iterators.length
        return result if result

    searchNext = () ->
      if section = iterator()
        section.load()
        return section.pipe (section) ->
          if result = handler section
            return jQuery.Deferred().resolve(result)
          else
            return searchNext()
      else
        return jQuery.Deferred().reject()
     
    searchNext()

  segmentBySectionOffset: (section, offset = 0) ->
    @load section.pipe (section) -> @_fudgeFix offset, section.getSegmentByOffset offset
