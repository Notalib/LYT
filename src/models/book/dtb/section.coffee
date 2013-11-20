# Requires `/common`
# Requires `textcontentdocument`
# Requires `smildocument`
# Requires `segment`

# -------------------

# This class models a "section" of a book - e.g. a chapter

class LYT.Section
  constructor: (heading, @book) ->
    @_deferred = jQuery.Deferred()
    @_deferred.promise this

    # Wrap the heading in a jQuery object
    heading = jQuery heading
    # Get the basic attributes
    @ref   = heading.attr "id"
    @class = heading.attr "class"
    # Get the anchor element of the heading, and its attributes
    anchor = heading.find("a:first")
    @title = jQuery.trim anchor.text()
    # The [NCC](http://www.daisy.org/z3986/specifications/daisy20.php#5.0%20NAVIGATION%20CONTROL%20CENTER%20%28NCC%29)
    # standard dictates that all references should point to a specific par or
    # seq id in the SMIL file. Since the section class represents the entire
    # SMIL file, we remove the id reference from the url.
    [@url, @fragment] = (anchor.attr "href").split('#')
    # We get some weird uris from IE8 due to missing documentElement substituted with iframe contentDocument.
    # Here we trim away everything before the filename.
    @url   = @url.substr @url.lastIndexOf('/') + 1 unless @url.lastIndexOf('/') == -1
    # Create an array to collect any sub-headings
    @children = []
    # The SMIL document (not loaded initially)
    @document = null
    # If this is a "meta-content" section (listed in src/config/config.coffee)
    # this property will be set to true
    @metaContent = false

  load: ->
    return this if @loading or @state() is "resolved"
    @loading = true
    @always => @loading = false

    log.message "Section: loading(\"#{@url}\")"
    # trim away everything after the filename.
    file = @url.replace /#.*$/, ""
    if not file of @book.resources
      log.error "Section: load: url not found in resources: #{file}"

    @book.getSMIL(file)
    .done (document) =>
      @document = document
      @_deferred.resolve this
    .fail =>
      log.error "Section: Failed to load SMIL-file #{@url.replace /#.*$/, ""}"
      @_deferred.reject()

    this

  segments: -> @document.segments

  getOffset: ->
    return null unless @document?.state() is "resolved"
    @document.absoluteOffset

  getAudioUrls: ->
    return [] unless @document?.state() is "resolved"
    urls = []
    for file in @document.getAudioReferences()
      url = @resources[file]?.url
      urls.push url if url
    urls

  hasNext: -> @next?

  hasPrevious: -> @previous?

  hasParent: -> @parent?

  # Since segments are sub-components of this class, we ensure that loading
  # is complete before returning them.

  # Helper function for segment getters
  # Return a promise that ensures that resources for both this object
  # and the segment are loaded.
  _getSegment: (getter) ->
    deferred = jQuery.Deferred()
    this.fail (error) -> deferred.reject error
    this.done (section) =>
      if not section?.document?.segments
        throw "Section: _getSegment: Invalid section loaded"

      if segment = getter section.document.segments
        segment.load()
        segment.done -> deferred.resolve segment
        segment.fail (error) -> deferred.reject error
      else
        # TODO: We should change the call convention to just resolve with null
        #       if no segment is found.
        deferred.reject 'Segment not found'
    deferred.promise()

  firstSegment: -> @_getSegment (segments) -> segments[0]

  lastSegment: -> @_getSegment (segments) -> segments[segments.length - 1]

  getSegmentById: (id) ->
    @_getSegment (segments) ->
      for segment in segments
        return segment if segment.id is id

  getUnloadedSegmentsByAudio: (audio) ->
    if this.state() isnt 'resolved'
      throw "Section: getSegmentsByAudio only works on resolved sections"
    jQuery.grep @document.segments, (segment) ->
      if segment.audio is audio
        return true

  getSegmentsByAudioOffset: (audio, offset) ->
    for segment in @getUnloadedSegmentsByAudio(audio)
      return segment if segment.containsOffset offset

  getSegmentBySmilOffset: (offset = 0) ->
    @_getSegment (segments) ->
      currentOffset = 0
      for segment in segments
        if currentOffset <= offset <= currentOffset + segment.duration
          return segment
        currentOffset += segment.duration

  getSegmentByOffset: (offset = 0) ->
    @_getSegment (segments) ->
      for segment in segments
        if segment.start <= offset < segment.end
          return segment

  # Flattens the structure from this section and "downwards"
  flatten: ->
    flat = [this]
    flat = flat.concat child.flatten() for child in @children
    flat
