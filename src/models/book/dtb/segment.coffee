# Requires `/common`  

# This class models a "segment" of audio + transcript,
# i.e. a single "sound clip" and its associated text/html
#
# A Segment instance as a Deferred. It resolves when all
# images contained in the transcript have been loaded (by
# calling the `preload` method), or if there were no images
# to load.
# 
# CHANGED: The segment instance will now reject its promise
# if it fails to load an image (before, it resolved no
# matter what)
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
    # Set up deferred load of images
    @_deferred = jQuery.Deferred()
    @_deferred.promise this
    
    # Add properties
    @id      = data.id
    @index   = data.index
    @start   = data.start
    @end     = data.end
    @section = section
    # Will be initialized in the load() method
    @text    = null
    @html    = null
    @images  = []
    @audio   = []
    @data    = data
    
  # Loads all resources
  load: ->
    # Skip if already finished
    return this if @state() is "resolved"

    # First make sure that the section we belong to has finished loading
    @section.done =>
      log.message "Segment: loading #{@url()}"
      # Parse transcript content
      [contentUrl, contentId] = @data.text.src.split "#"
      unless resource = @section.resources[contentUrl]
        log.error "Segment: no absolute URL for content #{contentUrl}"
        @_deferred.reject()
        return @_deferred.promise()
      else
        resource.document or= new LYT.TextContentDocument resource.url
        resource.document.done =>
          element = resource.document.getContentById contentId
          @removeLinks element
          @absolutizeSrcUrls element
          @text   = jQuery.trim element?.text() or ""
          @html   = element?.html()
          @images = @findImageUrls element
          
          queue = []
          for src in @images
            # Use Deferreds to set up a `when` trigger
            load = jQuery.Deferred()
            queue.push load.promise()
            # 1998 called; they want their preloading technique back
            tmp = new Image
            tmp.onload  = -> load.resolve()
            tmp.onerror = -> load.reject()
            tmp.src = src
  
          # When all images have loaded (or failed)...
          jQuery.when.apply(null, queue).then =>
            @audio = @getResource(@data.audio.src)?.url
            log.group "Segment: #{@url()} finished extracting text, html and loading images", (@text or ''), @html, @images
            @_deferred.resolve(this)
    
    return @_deferred.promise()

  url: -> "#{@section.url}##{@id}"
  
  ready: -> @_deferred.state() isnt "pending"
  
  hasNext: -> @next?
  
  hasPrevious: -> @previous?
  
  getNext: -> @next
  
  getPrevious: -> @previous

  # Will load this segment and the next preloadCount segments  
  preloadNext: (preloadCount = 3) ->
    this.load()
    if preloadCount > 0
      this.done (segment) ->
      	if next = segment.next
      	  next.preloadNext(preloadCount - 1)
      	else if segment.section.next
      	  segment.section.next.firstSegment().done (next) ->
      	    next.preloadNext(preloadCount - 1)

  # Get a resource by its local URL
  getResource: (resource) ->
    return null unless resource?
    @section.resources[resource]
  
  # Get the absolute URL for a relative URL
  resolveRelativeUrl: (relative) -> @getResource(relative)?.url or null
  
  # Remove links.  
  # This will fall apart on nested links, I think.
  # Then again, nested links are very illegal anyway
  removeLinks: (element) ->
    return null if not element? or element.length is 0
    element.find("a").each (index, item) ->
      item = jQuery item
      item.replaceWith item.html()
    element
  
  # Fix relative links in `src` attrs
  absolutizeSrcUrls: (element) =>
    return null if not element? or element.length is 0
    element.find("*[src]").each (index, item) =>
      item = jQuery item
      return if item.data("relative")?
      item.attr "src", "#{@resolveRelativeUrl item.attr("src")}"
      item.data "relative", "yes" # Mark as already-processed
    element
  
  # Find images in the HTML
  findImageUrls: (element) ->
    return [] if not element? or element.length is 0
    jQuery.map element.find("img"), (img) -> img.src
