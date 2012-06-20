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
    return @_deferred.promise() if @_deferred.state() is "resolved"

    # Parse transcript content
    [contentUrl, contentId] = @data.text.src.split "#"
    unless resource = @section.resources[contentUrl]
      log.error "Segment: no absolute URL for content #{contentUrl}"
      @_deferred.reject()
      return @_deferred.promise()
    else
      resource.document = new LYT.TextContentDocument resource.url
      _this = this
      resource.document.done ->
        element = resource.document.getContentById contentId
        _this.removeLinks element
        _this.absolutizeSrcUrls element
        _this.text   = jQuery.trim element?.text() or ""
        _this.html   = element?.html()
        _this.images = _this.findImageUrls element

        queue = []
        for src in _this.images
          # Use Deferreds to set up a `when` trigger
          load = jQuery.Deferred()
          queue.push load.promise()
          # 1998 called; they want their preloading technique back
          tmp = new Image
          tmp.onload  = ->
            log.message "Preloaded image #{src}"
            load.resolve()
          tmp.onerror = ->
            log.error "Failed to preload image #{src}"
            load.reject()
          tmp.src = src

        # When all images have loaded (or failed)...
        jQuery.when.apply(null, queue).then ->
          _this.audio = _this.getResource(_this.data.audio.src)?.url
          _this._deferred.resolve(_this)
    
    return @_deferred.promise()
    

  url: -> "#{@section.url}##{@id}"
  
  ready: -> @_deferred.state() isnt "pending"
  
  hasNext: -> @next?
  
  hasPrevious: -> @previous?
  
  getNext: -> @next
  
  getPrevious: -> @previous
  
  # Get a resource by its local URL
  getResource: (resource) ->
    return null unless resource?
    @section.resources[resource]
  
  # Get the absolute URL for a relative URL
  resolveRelativeUrl: (relative) ->
    @getResource(relative)?.url or null
  
  # Remove links.  
  # This will fall apart on nested links, I think.
  # Then again, nested links are very illegal anyway
  removeLinks: (element) ->
    return null if not element? or element.length is 0
    element.find("a").each ->
      item = jQuery this
      item.replaceWith item.html()
    element
  
  # Fix relative links in `src` attrs
  absolutizeSrcUrls: (element) ->
    return null if not element? or element.length is 0
    element.find("*[src]").each ->
      item = jQuery this
      return if item.data("relative")?
      item.attr "src", "#{@resolveRelativeUrl item.attr("src")}"
      item.data "relative", "yes" # Mark as already-processed
    element
  
  # Find images in the HTML
  findImageUrls: (element) ->
    return [] if not element? or element.length is 0
    jQuery.map element.find("img"), (img) -> img.src
