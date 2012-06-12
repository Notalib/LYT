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
    @url   = anchor.attr "href"
    # Create an array to collect any sub-headings
    @children = []
    # The SMIL document (not loaded initially)
    @document = null
    # The section's segments
    @segments = []
    # The current segment-index
    @currentIndex = false
  
  load: ->
    return this if @document?
    
    file = @url.replace /#.*$/, ""
    url  = @resources[file]?.url
    @document = new LYT.SMILDocument url
    
    # SMIL document loaded for this section
    @document.done =>
      textContentDocuments = @document.getTextContentReferences()
      for file, index in textContentDocuments
        unless @resources[file]
          log.error "Section: No absolute URL for file #{file}"
          @_deferred.reject()
          return
        
        unless @resources[file].document?
          @resources[file].document = new LYT.TextContentDocument @resources[file].url
          textContentDocuments[index] = @resources[file].document
        
      jQuery.when.apply(null, textContentDocuments)
        .then => @_deferred.resolve(this)
        .fail => @_deferred.reject(this)
    
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
  mediaAtOffset: (offset = 0) ->
    rawSegment = @document.getSegmentByTime offset
    return null unless rawSegment?
    @segments[rawSegment.index] or= new LYT.Segment this, rawSegment
  
  
  # Flattens the structure from this section and "downwards"
  flatten: ->
    flat = [this]
    flat = flat.concat child.flatten() for child in @children
    flat
  
