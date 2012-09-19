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

  hasNextSegment: (segment) ->
    segment or= @currentSegment
    segment?.hasNext() or @hasNextSection segment

  hasPreviousSegment: -> @currentSegment?.hasPrevious() or @hasPreviousSection()

  hasNextSection: (segment) ->
    section = segment?.section or @currentSection()
    section?.next?

  hasPreviousSection: -> @currentSection()?.previous?

  load: (segment) ->
    log.message "Playlist: load: queue segment #{segment.url?() or '(N/A)'}"
    segment.done (segment) =>
      if segment?
        log.message "Playlist: load: set currentSegment to #{segment.url()}"
        @currentSegment = segment
    segment

  rewind: -> @load @nccDocument.firstSegment()

  nextSection: (segment) ->
    section = segment?.section or @currentSection()
    # FIXME: loading segments is the responsibility of the section each
    # each segment belongs to.
    if section.next
      section.next.load()
      @load section.next.firstSegment()

  previousSection: ->
    # FIXME: loading segments is the responsibility of the section each
    # each segment belongs to.
    @currentSection().previous.load()
    @load @currentSection().previous.firstSegment()
    
  nextSegment: (segment) ->
    segment or= @currentSegment
    if segment.hasNext()
      # FIXME: loading segments is the responsibility of the section each
      # each segment belongs to.
      segment.next.load()
      return @load segment.next
    else
      return @nextSection segment
    
  previousSegment: (segment) ->
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
    promise = @_segmentsByAudio audio
    promise.pipe (segments) =>
      for segment in segments
        if segment.start <= offset < segment.end
          segment = @_fudgeFix offset, segment
          # FIXME: loading segments is the responsibility of the section each
          # each segment belongs to.
          segment.load()
          return @load segment

  _segmentsByAudio: (audio) ->
    getters = [
      () => @currentSection()
      () => @currentSection().next
      () => @currentSection().previous
    ]
    iterator = () -> getters.shift()?.apply()

    searchNext = () ->
      if section = iterator()
        section.load()
        return section.pipe (section) ->
          segments = section.getUnloadedSegmentsByAudio audio
          if segments.length > 0
            return segments
          else
            return searchNext()
      else
        return jQuery.Deferred().reject()
     
    searchNext()

  segmentBySectionOffset: (section, offset = 0) ->
    @load section.pipe (section) -> @_fudgeFix offset, section.getSegmentByOffset offset

