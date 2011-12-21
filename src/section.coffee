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
    # The current segment-index
    @currentIndex = false
  
  load: ->
    return this if @document?
    
    file = @url.replace /#.*$/, ""
    url  = @resources[file]?.url
    @document = new LYT.SMILDocument url
    
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
  # Again, this is asynchronous, and the method returns a
  # Deferred object. Here's an example
  # 
  #     # Get media 12 seconds into a section
  #     section.getMediaFor("section-01", 12).done (media) ->
  #       # Check for null
  #       if media?
  #         # do something with the media
  # 
  # The media object that's propagated has the following
  # properties:
  #
  # - id:              The id of the <par> element in the SMIL document
  # - start:           The start time, in seconds, relative to the audio
  # - end:             The end time, in seconds, relative to the audio
  # - audio:           The url of the audio file (or null)
  # - html:            The HTML to display (or null)
  # - text:            The text content of the HTML content (or null)
  # 
  # And the following functions:
  # 
  # - hasNext():       Is there a media segment after this?
  # - getNext():       Get the next media segment object
  # - hasPrevious():   Is there a media segment after this?
  # - getPrevious():   Get the next media segment object
  mediaAtOffset: (offset = 0) ->
    compile = (segment) =>
      # Get a resource by its local URL
      getResource = (resource) =>
        return null unless resource?
        @resources[resource]
      
      # Get the absolute URL for a relative URL
      resolveRelativeUrl = (relative) ->
        getResource(relative)?.url or null
      
      # Prepare HTML content for display:
      #
      # 1. Remove links (leaving their text content in place)
      # 2. Make relative `src` attributes (i.e. images) absolute
      prepareContentElement = (element) ->
        # Check the input
        return null if not element? or element.length is 0
        
        # Remove links.  
        # This will fall apart on nested links, I think.
        # Then again, nested links are very illegal anyway
        element.find("a").each ->
          item = jQuery this
          item.replaceWith item.html()
        
        # Fix relative links in `src` attrs
        element.find("*[src]").each ->
          item = jQuery this
          item.attr "src", "#{resolveRelativeUrl item.attr("src")}"
        
        element.html()
      
      media =
        id:      segment.id
        index:   segment.index
        start:   segment.start
        end:     segment.end
        audio:   @resources[segment.audio.src]?.url
        text:    null
        html:    null
      
      [contentUrl, contentId] = segment.text.src.split "#"
      if @resources[contentUrl]?.document?.state() is "resolved" and contentId
        element = @resources[contentUrl].document.getContentById contentId
        media.text = jQuery.trim element.text()
        media.html = prepareContentElement element
      
      segments = @document.segments
      
      media.hasNext = ->
        @index < segments.length - 1
      
      media.hasPrevious = ->
        @index > 0
      
      media.getNext = ->
        return null unless @hasNext()
        compile segments[@index+1]
      
      media.getPrevious = ->
        return null unless @hasPrevious()
        compile segments[@index-1]
      
      media
    
    unless @document? and @document.state() is "resolved"
      log.warn "Section: SMIL document not loaded"
      return null
    
    segment = @document.getSegmentByTime offset
    unless segment?
      log.warn "Section: Failed to find media for offset #{offset}"
      return null
    
    compile segment
  
  
  # Flattens the structure from this section and "downwards"
  flatten: ->
    flat = [this]
    flat = flat.concat child.flatten() for child in @children
    flat
  
