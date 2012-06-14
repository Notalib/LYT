# Requires `/common`  

# This class models a "segment" of audio + transcript,
# i.e. a single "sound clip" and its associated text/html
#
# A Segment instance as a Deferred. It resolves when all
# images contained in the transcript have been loaded (by
# calling the `preload` method), or if there were no images
# to load. Currently, there's no failed state; whether images
# load or not, the Segment should (sooner or later) resolve.
# 
# A Segment instance has the following properties:
#
# - id:              The id of the <par> element in the SMIL document
# - start:           The start time, in seconds, relative to the audio
# - end:             The end time, in seconds, relative to the audio
# - audio:           The url of the audio file (or null)
# - html:            The HTML to display (or null)
# - text:            The text content of the HTML content (or null)
# - images:          Array of image URLs in the HTML content (if any)
# 
# And the following methods (not in prototype, mixed-in in constructor):
#
# - preload:         Preloads transcript content (i.e. images). Returns
#                    a promise (currently, the promise is always
#                    resolved, regardless of errors)
# - ready:           Returns a boolean indicating whether the segment
#                    is ready for display
# 
# Additionally, it has the methods added via `Deferred#promise`

class LYT.Segment
  constructor: (section, data) ->
    # Set up a promise
    deferred = jQuery.Deferred()
    deferred.promise this
    # Images still to be loaded
    queuedImages = []
    # Declare `preload` here to set its scope
    preload = null
    
    # closure to avoid scope pollution
    do =>
      # Preload any images in the transcript (i.e. html)
      preload = ->
        # Skip if already finished
        return deferred.promise() if deferred.state() is "resolved"
        queue = []
        # Load all images
        while queuedImages.length
          src = queuedImages.shift()
          # Use Deferreds to set up a `when` trigger
          load = jQuery.Deferred()
          queue.push load.promise()
          # 1998 called; they want their preloading technique back
          tmp = new Image
          tmp.src = src
          tmp.onload  = ->
            log.message "Preloaded image #{src}"
            load.resolve()
          # Absorb failures
          tmp.onerror = ->
            log.error "Failed to preload image #{src}"
            load.resolve()
        
        # When all images have loaded (or failed)...
        jQuery.when.apply(null, queue).then -> deferred.resolve()
        deferred.promise()
      
    @url = -> "#{section.url}##{@id}"
    
    @section = -> section
    
    @ready = -> deferred.state() isnt "pending"
    
    rawSegments = section.document.segments
    cachedSegment = section.segments
    
    @hasNext = -> @index < rawSegments.length - 1
    
    @hasPrevious = -> @index > 0
    
    @getNext = ->
      return null unless @hasNext()
      section.segments[@index + 1] or= new LYT.Segment section, rawSegments[@index + 1]
    
    @getPrevious = ->
      return null unless @hasPrevious()
      section.segments[@index - 1] or= new LYT.Segment section, rawSegments[@index - 1]
    
    # Get a resource by its local URL
    getResource = (resource) ->
      return null unless resource?
      section.resources[resource]
    
    # Get the absolute URL for a relative URL
    resolveRelativeUrl = (relative) ->
      getResource(relative)?.url or null
    
    # Remove links.  
    # This will fall apart on nested links, I think.
    # Then again, nested links are very illegal anyway
    removeLinks = (element) ->
      return null if not element? or element.length is 0
      element.find("a").each ->
        item = jQuery this
        item.replaceWith item.html()
      element
    
    # Fix relative links in `src` attrs
    absolutizeSrcUrls = (element) ->
      return null if not element? or element.length is 0
      element.find("*[src]").each ->
        item = jQuery this
        return if item.data("relative")?
        item.attr "src", "#{resolveRelativeUrl item.attr("src")}"
        item.data "relative", "yes" # Mark as already-processed
      element
    
    # Find images in the HTML
    findImageUrls = (element) ->
      return [] if not element? or element.length is 0
      jQuery.map element.find("img"), (img) -> img.src
    
    # Add properties
    @id     = data.id
    @index  = data.index
    @start  = data.start
    @end    = data.end
    @audio  = getResource(data.audio.src)?.url
    @text   = null
    @html   = null
    @images = []
    
    # Parse transcript content
    [contentUrl, contentId] = data.text.src.split "#"
    
    # TODO: Check calling sequence - no use checking for "resolved" if it already is
    # and no way to re-call the constructor if it isn't resolved, so it's rather pointless
    if not contentId or getResource(contentUrl)?.document?.state() isnt "resolved"
      throw "SMIL file not loaded"
      
    element = getResource(contentUrl).document.getContentById contentId
    removeLinks element
    absolutizeSrcUrls element
    @text   = jQuery.trim element?.text() or ""
    @html   = element?.html()
    @images = findImageUrls element
    queuedImages = @images.slice 0
    
    # Resolve right away if there are no images
    if queuedImages.length
      preload()
    else
      deferred.resolve()
