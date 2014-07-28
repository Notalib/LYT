# Requires `/common`

# This class models a "segment" of audio + transcript,
# i.e. a single "sound clip" and its associated text/html
#
# A Segment instance is a Deferred. It resolves when all
# images contained in the transcript have been loaded (by
# calling the `preload` method), or if there were no images
# to load.
#
# A Segment instance has the following properties:
#
# - id:              The id of the <par> element in the SMIL document
# - start:           The start time, in seconds, relative to the audio
# - end:             The end time, in seconds, relative to the audio
# - audio:           The url of the audio file (or null)
# - text:            The text content of the HTML content (or null)
# - type:            Type of this segment. The following two types are
#                    currently supported:
#                     - cartoon:  Display one large image.
#                                 Each segment is an area that the
#                                 player should pan and zoom to.
#                     - standard: Displays the provided content, replacing
#                                 any previous content.
# And the following methods (not in prototype, mixed-in in constructor):
#
# - preload:         Preloads transcript content (i.e. images).
# - state:           This is the state of the `Deferred#promise` used to indicate
#                    if the segment has been loaded yet:
#                     - pending:  the load() method hasn't been called yet
#                                 or the segment is currently loading.
#                     - resolved: the segment has been loaded and can be
#                                 displayed.
#                     - rejected: loading the segment has failed.


class LYT.Segment
  constructor: (data, document) ->
    # Set up deferred load of images
    @_deferred = jQuery.Deferred()
    @_deferred.promise this

    # Properties initialized in the constructor
    @id          = data.id
    @index       = data.index
    @start       = data.start
    @end         = data.end
    @canBookmark = data.canBookmark
    @audio       = document.book.resources[data.audio?.src?.toLowerCase()]?.url
    @data        = data
    @el          = data.par
    @document    = document

    # Will be initialized in the load() method:
    @text        = null
    @smil        = data.smil

  # Loads all resources
  load: ->
    # Skip if already finished
    return this if @loading? or @state() is "resolved"
    @loading = true
    @always =>
      @loading = false
    @fail   =>
      log.error "Segment: failed loading segment #{this.url()}"

    log.message "Segment: loading #{@url()}"

    # Parse transcript content
    [@contentUrl, @contentId] = @data.text.src.split "#"
    resources = @document.book.resources
    resource = resources[@contentUrl.toLowerCase()]
    if not resource
      log.error "Segment: no absolute URL for content #{@contentUrl}"
      @_deferred.reject()
    else
      if not resource.document
        resource.document = new LYT.TextContentDocument resource.url, resources

      promise = resource.document.then (document) => @parseContent document
      promise.done => @_deferred.resolve this
      promise.fail (status, error) =>
        log.error "Unable to get TextContentDocument for #{resource.url}: #{status}, #{error}"
        @_deferred.reject()

    @_deferred.promise( this )

  url: -> "#{@document.filename}##{@id}"

  ready: -> @_deferred.state() isnt "pending"

  hasNext: -> @next?

  hasPrevious: -> @previous?

  getNext: -> @next

  getPrevious: -> @previous

  duration: -> @end - @start

  search: (iterator, filter, onlyOne = true) ->
    if onlyOne
      while item = iterator()
        return item if filter item
    else
      result = []
      while item = iterator()
        result.push item if filter item
      return result

  searchBackward: (filter, onlyOne) ->
    current = this
    iterator = () -> current = current.previous
    return @search iterator, filter, onlyOne

  searchForward: (filter, onlyOne) ->
    current = this
    iterator = () -> current = current.next
    return @search iterator, filter, onlyOne

  bookmark: (audioOffset) ->
    new LYT.Bookmark
      URI:        @url()
      timeOffset: @smilOffset audioOffset

  smilStart: ->
    return @smil.start if @smil.start?
    start = 0
    segment = this
    while segment = segment.previous
      start += segment.duration()
    @smil.start = start
    start

  # Convert from smil offset to audio offset
  audioOffset: (smilOffset) -> @start + smilOffset - @smilStart()

  # Convert from audio offset to smil offset
  smilOffset: (audioOffset) -> @smilStart() + audioOffset - @start

  containsSmilOffset: (smilOffset) -> @smilStart() <= smilOffset <= @smilStart() + @duration()

  containsOffset: (offset) -> @start <= offset <= @end

  # Will load this segment and the next preloadCount segments
  preloadNext: (preloadCount = LYT.config.segment.preload.queueSize) ->
    @load()
    return if not (preloadCount > 0)

    @done (segment) =>
      if next = segment.next
        next.preloadNext(preloadCount - 1)
      else
        nextSection = (@document.book.getSectionBySegment segment)?.next
        if nextSection
          nextSection.firstSegment().done (next) ->
            next.preloadNext(preloadCount - 1)

  # Parse content document and extract segment data
  # Used with deferreds, so should return this (the segment itself) or a failed
  # promise in order to reject processing.
  parseContent: (document) ->
    source = document.source
    sourceContent = source.find("##{@contentId}")

    # Check if the source document is using whole page cartoon html or not
    if sourceContent.parent().hasClass('page') and sourceContent.is('div') and image = sourceContent.parent().children('img')

      @type  = 'cartoon' # Cartoon html
      getCanvasSize = (image) ->
        result = {}
        for type in ['height', 'width']
          # Try reading canvas size from height/width attribute on image
          if dim = image.attr type
            result[type] = dim
            continue
          # Try parsing style attribute
          if dim = image.attr('style').match(type + '\\s*:\\s*(\\d+)\\s*px')
            result[type] = dim[1]
            continue
          # Try reading canvas size from css on the containing div
          if image.parent().css(type).match(/(\d+)(?:px)?/)
            result[type] = dim[1]
            continue
          else
            # Finally just give up and use naturalHeight/naturalWidth
            attr = type.replace /^([a-z])/g, (m, p1) -> 'natural' + p1.toUpperCase()
            log.warn "render.content: imageDim: no #{type} attribute or css #{type} on image. Falling back to #{attr} which is not known to be cross browser"
            result[type] = image[attr]
        result

      getCanvasScale = (canvasSize, imageSize) ->
        # TODO: We should check that imageSize.width / canvasSize.width == imageSize.height / canvasSize.height
        #       ...and complain loudly if it isn't the case
        if canvasSize.width != imageSize.width
          try
            imageSize.width / canvasSize.width
          catch e
            1
        else
          return 1

      loadImage = (image) =>
        log.message "Segment: #{this.url()}: parseContent: initiate preload of image #{image.src}"
        # Note that clearing the timeout has to be done as the first thing in
        # both handlers. We still have a race condition where the timer may
        # fire just before being cleared.
        errorHandler = (event) ->
          clearTimeout image.timer
          if image.attempts-- > 0
            backoff = Math.ceil(Math.exp(LYT.config.segment.imagePreload.attempts - image.attempts + 1) * 50)
            log.message "Segment: parseContent: preloading image #{image.src} failed, #{image.attempts} attempts left. Waiting for #{backoff} ms."
            doLoad = -> loadImage image
            setTimeout doLoad, backoff
          else
            log.error "Segment: parseContent: unable to preload image #{image.src}"
            image.deferred.reject image, event

        doneHandler = (event) ->
          clearTimeout image.timer
          log.message "Segment: parseContent: loaded image #{image.src}"
          image.deferred.resolve image, event

        # Set timeout, so we can retry again if the load stalls
        image.timer = setTimeout errorHandler, LYT.config.segment.imagePreload.timeout
        # 1998 called; they want their preloading technique back
        tmp = new Image
        $(tmp).load(doneHandler).error(errorHandler)
        tmp.src = image.src

      if image.length != 1
        log.error "Segment: parseContent: can't create reliable cartoon type " +
          "with multiple or zero images: #{this.url()}"
        throw "Segment: parseContent: unable to find exactly one image in " +
          "cartoon display div"

      # FIXME: We're basically cloning the image and div elements. This should
      # be fixed when we move to a better rendering architecture
      @image = image.clone().wrap('<p>').parent().html()
      @div = sourceContent.clone().wrap('<p>').parent().html()
      @canvasSize = getCanvasSize image
      imageData =
        src: image.attr('src')
        element: image[0]
        attempts: LYT.config.segment.imagePreload.attempts
        deferred: jQuery.Deferred()
      imageData.deferred.done (imageData, event) =>
        @canvasScale = getCanvasScale @canvasSize,
          width:  event.target.width
          height: event.target.height

      loadImage imageData
      return imageData.deferred.done =>
        log.group "Segment: #{@url()} finished extracting text, html and loading images",
          @text, image
        this
    else
      @type = 'standard' # Standard html

    $.Deferred().resolve()

