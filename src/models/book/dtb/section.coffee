# Requires `/common`  
# Requires `textcontentdocument`  
# Requires `smildocument`  
# Requires `segment`  

# -------------------

# This class models a "section" of a book - e.g. a chapter

class LYT.Section
  constructor: (heading, @resources) ->
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
    @url   = (anchor.attr "href").split('#')[0]
    # Create an array to collect any sub-headings
    @children = []
    # The SMIL document (not loaded initially)
    @document = null
  
  load: ->
    return this if @state() is "resolved"
    @loading = true
    this.always => this.loading = false

    log.message("Section: loading(\"#{@url}\")")

    file = @url.replace /#.*$/, ""
    url  = @resources[file]?.url
    @document = new LYT.SMILDocument this, url

    @document.done => @_deferred.resolve(this)    
    @document.fail =>
      log.error "Section: Failed to load SMIL-file #{@url.replace /#.*$/, ""}"
      @_deferred.reject()
    
    this
  
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
  
  # Since segments are sub-components of this class, we ensure that loading
  # is complete before returning them.

  # Helper function for segment getters
  # Return a promise that ensures that resources for both this object
  # and the segment are loaded.
  _getSegment: (getter) ->
    deferred = jQuery.Deferred()
    this.done (section) ->
      if segment = getter section.document.segments
        segment.load()
        segment.done -> deferred.resolve segment
        segment.fail -> deferred.reject()
      else
        deferred.reject()
    deferred.promise()

  firstSegment: -> @_getSegment (segments) -> segments[0]

  lastSegment: -> @_getSegment (segments) -> segments[segments.length - 1]
  
  getSegmentById: (id) ->
    @_getSegment (segments) ->
      for segment in segments
        return segment if segment.id is id
  
  # Retrieves the media (text and audio) at a given point
  # in time (seconds, relative to the section).
  # Both arguments are optional. If no arguments are given, 
  # the first section's first text & audio will be loaded.  
  # If no matching media is found, `null` will be propagated.
  #
  # CHANGED: Now caches and returns `LYT.Segment` instances  
  # TODO: There's a lot of unnecessary data-duplication going
  # on between the various models... that should probably
  # be alleviated somehow
  getSegmentByOffset: (offset = 0) -> 
    @_getSegment (segments) ->
      for segment in segments
        return segment if segment.start <= offset < segment.end
  
  # Flattens the structure from this section and "downwards"
  flatten: ->
    flat = [this]
    flat = flat.concat child.flatten() for child in @children
    flat
