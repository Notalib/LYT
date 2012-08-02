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
  # Number of segments to preload
  
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
    @audio   = @section.resources[data.audio.src]?.url
    @data    = data
    
  # Loads all resources
  load: ->
    # Skip if already finished
    return this if @loading? or @state() is "resolved"
    @loading = true
    this.always => this.loading = false
    this.fail => log.error "Segment: failed loading segment #{this.url()}"

    # First make sure that the section we belong to has finished loading
    @section.done (section) =>
      log.message "Segment: loading #{@url()}"
      # Parse transcript content
      [@contentUrl, @contentId] = @data.text.src.split "#"
      unless resource = section.resources[@contentUrl]
        log.error "Segment: no absolute URL for content #{@contentUrl}"
        @_deferred.reject()
      else
        unless resource.document
          resource.document = new LYT.TextContentDocument resource.url
          resource.document.done (document) -> document.resolveUrls section.resources
        promise = resource.document.pipe (document) => @parseContent document
        promise.done => @_deferred.resolve this
        promise.fail (status, error) =>
          log.error "Unable to get TextContentDocument for #{resource.url}: #{status}, #{error}"
          @_deferred.reject()
    
    return @_deferred.promise()

  url: -> "#{@section.url}##{@id}"
  
  ready: -> @_deferred.state() isnt "pending"
  
  hasNext: -> @next?
  
  hasPrevious: -> @previous?
  
  getNext: -> @next
  
  getPrevious: -> @previous

  _status: ->
    for image in @_images
      log.message "Segment: image queue: #{image.src}: #{image.deferred.state()}"

  # Will load this segment and the next preloadCount segments  
  preloadNext: (preloadCount = LYT.config.segment.preload.queueSize) ->
    this.load()
    if preloadCount > 0
      this.done (segment) ->
        if next = segment.next
          next.preloadNext(preloadCount - 1)
        else if segment.section.next?
          segment.section.next.firstSegment().done (next) ->
            next.preloadNext(preloadCount - 1)

  # Parse content document and extract segment data
  # Used in pipe, so should return this (the segment itself) or a failed
  # promise in order to reject processing.
  parseContent: (document) ->
    source = document.source
    sourceContent = source.find("##{@contentId}")
    
    # Find images in the HTML and set up preloading
    # Use Deferreds to set up a `when` trigger
    images = []

    if sourceContent.parent().hasClass('page') and sourceContent.is('div') and image = sourceContent.parent().children('img')
      if image.length != 1
        log.error "Segment: parseContent: can't create reliable cartoon type with multiple or zero images: #{this.url()}"
      @type  = 'cartoon'
      # The stuff below simply gets the complete html as a string, as jQuery
      # doesn't have a method for this
      @image = image.clone().wrap('<p>').parent().html()
      @div   = sourceContent.clone().wrap('<p>').parent().html()
      images.push
        src: image[0].src
        element: image[0]
        attempts: LYT.config.segment.imagePreload.attempts
        deferred: jQuery.Deferred()
      
    else
      element = jQuery source.get(0).createElement("DIV")
      element.append sourceContent.first().clone()
      @type = 'standard'
      sibling = element.next()
      until sibling.length is 0 or sibling.attr "id"
        element.append sibling.clone()
        sibling = sibling.next()
  
      # Remove links.  
      # This will fall apart on nested links, I think.
      # Then again, nested links are very illegal anyway
      element.find("a").each (index, item) ->
        item = jQuery item
        item.replaceWith item.html()
  
      @text = jQuery.trim element?.text() or ""
      # Assuming that we
      @html = element?.html()

      jQuery.each element.find("img"), (i, img) ->
        images.push
          src: img.src
          element: img
          attempts: LYT.config.segment.imagePreload.attempts
          deferred: jQuery.Deferred()

    loadImage = (image) =>
      log.message "Segment: #{this.url()}: parseContent: initiate preload of image #{image.src}"
      # Note that clearing the timeout has to be done as the first thing in
      # both handlers. We still have a race condition where the timer may
      # fire just before being cleared.
      errorHandler = () ->
        clearTimeout image.timer
        if image.attempts-- > 0
          backoff = Math.ceil(Math.exp(LYT.config.segment.imagePreload.attempts - image.attempts + 1) * 50)
          log.message "Segment: parseContent: preloading image #{image.src} failed, #{image.attempts} attempts left. Waiting for #{backoff} ms."
          doLoad  = () -> loadImage image
          setTimeout doLoad, backoff
        else
          log.error "Segment: parseContent: unable to preload image #{image.src}"
          image.deferred.reject()
      doneHandler = () ->
        clearTimeout image.timer
        log.message "Segment: parseContent: loaded image #{image.src}"
        image.deferred.resolve()
      # Set timeout, so we can retry again if the load stalls
      image.timer = setTimeout errorHandler, LYT.config.segment.imagePreload.timeout
      # 1998 called; they want their preloading technique back
      tmp = new Image
      tmp.onload  = doneHandler
      tmp.onerror = errorHandler
      tmp.src = image.src
    
    for image in images
      log.message "Segment: queue image for preload: #{image.src}"
      unless prevImage?
        loadImage image
      else
        image.deferred.done () ->
          loadImage image
      prevImage = image

    @_images = images

    # When all images have loaded (or failed)...
    jQuery.when.apply(null, jQuery.map images, (image) -> image.deferred)
      .done =>
        log.group "Segment: #{@url()} finished extracting text, html and loading images", (@text or ''), @html, images
        return this
      .fail =>
        return jQuery.Deferred().reject()
