# Requires `/common`
# Requires `/view/render`

# -------------------

# This module handles rendering of book content
#console.log 'Load LYT.render.content'
LYT.render.content = do ->

  _focusEasing   = 'easeInOutQuint'
  _focusDuration = 500

  # Getter and setter
  focusEasing = (easing...) ->
    _focusEasing = easing[0] if easing.length > 0
    _focusEasing

  # Getter and setter
  focusDuration = (duration...) ->
    _focusDuration = duration[0] if duration.length > 0
    _focusDuration

  # Return how much vertical space that is available
  vspace = ->
    result = $(window).height()
    $('#book-content').prevAll().each (i, e) ->
      result -= $(e).height()
    return result

  # Return how much horizontal space that is available
  hspace = -> $(window).width()

  # Given an image and an area of the image, return how the image
  # should be translated in cordinates relative to its containing view.
  # New width and height is returned as well.
  # The object returned contains css attributes that will do the translation.
  # FIXME: This function shouldn't depend on the image having a parent.
  translate = (image, area, view) ->
    result = {}
    view or= image.parent()

    scale = 1
    scale = view.width() / area.width if scale > view.width() / area.width
    scale = vspace() / area.height if scale > vspace() / area.height
#    console.log "render.content: page dimensions: #{$(window).width()}x#{$(window).height()}"
#    console.log "render.content: translate: scale: #{scale}"
#    console.log "render.content: translate: display area: #{JSON.stringify area}"
#    console.log "render.content: translate: view dimensions: #{view.width()}x#{vspace()}"
#    console.log "render.content: translate: image natural dimensions: #{image[0].naturalWidth}x#{image[0].naturalHeight}"
    # FIXME: resizing div to fit content in case div is too large
    centering = if area.width * scale < view.width() then (view.width() - area.width * scale)/2 else 0

    width:  Math.floor(image[0].naturalWidth * scale)
    height: Math.floor(image[0].naturalHeight * scale)
    top:    Math.floor(-area.tl.y * scale)
    left:   Math.floor(centering - area.tl.x * scale)

  # Move straight to focus area without any effects
  focusImage = (image, area) ->
    nextFocus = translate image, area
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.data 'LYT-focus', nextFocus
    image.css nextFocus

  # Move to focus area with effects specified in focusDuration() and focusEasing()
  panZoomImage = (segment, image, area, renderDelta) ->
    timeScale = if renderDelta > 1000 then 1 else renderDelta / 1000
    nextFocus = translate image, area
    #console.log "render.content: panZoomImage: nextFocus: #{JSON.stringify nextFocus}"
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.stop true
    image.animate nextFocus, timeScale*focusDuration(), focusEasing(), () ->
      image.data 'LYT-focus', nextFocus
      if area.height/area.width > 2 and area.height > vspace() * 2
        panArea = jQuery.extend {}, area
        panArea.height = area.width
        image.animate translate(image, panArea), timeScale*focusDuration(), focusEasing(), () ->
          panArea.tl.y = area.height - panArea.height
          image.animate translate(image, panArea), (segment.end - segment.start)*1000 - 2 * focusDuration(), 'linear'

  # Return area object that will focus on the entire image
  # TODO: This method is not cross browser and needs to be rewritten
  wholeImageArea = (image) ->
    width:  image[0].naturalWidth
    height: image[0].naturalHeight
    tl:
      x: 0
      y: 0
    br:
      x: image[0].naturalWidth
      y: image[0].naturalHeight

  scaleArea = (scale, area) ->
    width:  scale * area.width
    height: scale * area.height
    tl:
      x: scale * area.tl.x
      y: scale * area.tl.y
    br:
      x: scale * area.br.x
      y: scale * area.br.y

  # Render cartoon - a cartoon page with one or more focus areas
  renderCartoon = (segment, view, renderDelta) ->
    div   = segment.divObj or= jQuery segment.div
    image = segment.imgObj or= jQuery segment.image

    if view.find('img').attr('src') is image.attr('src')
      # We are already displaying the right image
      image = view.find 'img'
    else
      # Display new image
      view.css 'text-align', 'left'
      image.css 'position', 'relative'
      view.empty().append image
      focusImage image, wholeImageArea image

    left = parseInt (div[0].style.left.match /\d+/)[0]
    top  = parseInt (div[0].style.top.match /\d+/)[0]

    area = scaleArea segment.canvasScale,
      width:  div.width()
      height: div.height()
      tl:
        x: left
        y: top
      br:
        x: left + div.width()
        y: top  + div.height()

#    console.log "Area: #{area.width}x#{area.height}, (#{area.tl.x}, #{area.tl.y})"

    panZoomImage segment, image, area, renderDelta

    return true

  # Stack renderer - stack segments
  renderStack = (currentSegment, view, renderDelta) ->

    log.message "Render: content: renderStack: renderDelta #{renderDelta}, vspace: #{vspace()}"

    timeScale = if renderDelta > 1000 then 1 else renderDelta / 1000

    bookSection = (segment) ->
      book = segment.document.book
      "#{book.id}:#{book.getSectionBySegment(segment).url}"

    contentContainerId = (segment) ->
      "content-#{segment.contentUrl}--#{segment.contentId}"

    missingContainerId = (segment) ->
      "missing-segment-#{segment.url().replace /[#.]/g, '--'}"

    renderedSection = view.data "LYT-render-book-section"

    # Empty view if book or section has changed
    if not renderedSection or renderedSection isnt bookSection currentSegment
      log.message 'Render: content: renderStack: empty view - wrong section'
      view.data 'LYT-render-book-section', bookSection currentSegment
      view.children().detach()
      view.append $("<div class=\"missingSegment\" id=\"#{missingContainerId missingSegment}\">⋮</div>") for missingSegment in currentSegment.document.segments

    view.css('overflow-x', 'scroll')

    segment = currentSegment
    while segment and segment.state() is "resolved"
      log.message "Render: content: renderStack: rendering #{segment.url()}"
      # Using getElementById in this loop for performance reasons
      element = $(document.getElementById contentContainerId segment)
      if element.length == 0
        # There is no content container for this segment, so it should be
        # rendered now. First see if we have an HTML element cached from
        # before (in segment.element). If that fails, render it again.
        element = segment.element
        unless element
          element = $(document.createElement('div'))
          element.attr 'id', contentContainerId segment
          element.attr 'class', 'segmentContainer'
          element.html segment.html
          element.find('img').each ->
            image = $(this)
            image.click -> image.toggleClass('zoom')
          segment.element = element

        $(document.getElementById missingContainerId(segment)).replaceWith element
        element.css 'display', 'none'
      else
        # The element may already have been created by a previous segment, so
        # set a reference to it here.
        segment.element = element
        # TODO: The following should be possible to remove because the missing
        #       segment containers are removed in the block above.
        if missingContainer = $(document.getElementById missingContainerId(segment))
          missingContainer.remove()

      segment = segment.next

    view.find('img').each ->
      image = $(this)
      image.css translate(image, wholeImageArea(image), view)

    # Hide segments that follow missing segments (this would confuse the reader)
    currentSegment.element.nextAll('.missingSegment ~ .segmentContainer').css 'display', 'none'
    # Halt all animations
    view.children('.current').stop true, true

    # Set current container and hide all content containers before it
    before = currentSegment.element.prevAll(':visible')
    view.children('.current').removeClass 'current'
    currentSegment.element.addClass 'current'
    before.hide()
    show = (el) ->
      el.css
        visibility: 'visible'
        display: 'block'
        opacity: 1
    show currentSegment.element
    show currentSegment.element.nextAll '.segmentContainer'

    # Function that calculates the available vertical space and preloads if
    # there is any space available
    preload = ->
      totalHeight = currentSegment.element.height()
      maxHeight = totalHeight
      currentSegment.element.nextAll('.segmentContainer').each ->
        height = $(this).height()
        totalHeight += height
        maxHeight or= height
        maxHeight = height if height > maxHeight
      if segment and totalHeight < vspace() + 2*maxHeight
        log.message "Render: content: renderStack: preloading #{Math.floor(totalHeight / maxHeight + 1)} segments"
        segment.preloadNext Math.floor(totalHeight / maxHeight + 1)

    # Fade in all segments from the current and up to the first missing segment
    currentSegment.element.fadeIn(500*timeScale) if currentSegment.element.is ':hidden'
    hiddenContainers = currentSegment.element.nextUntil('.missingSegment', '.segmentContainer:hidden')
    if hiddenContainers.length > 0
      hiddenContainers.fadeIn 1000*timeScale, preload
    else
      preload()


  # Plain renderer - render everything in the segment
  renderPlain = (segment, view) ->
    view.css 'text-align', 'center'
    segment.dom or= $(document.createElement('div')).html segment.html
    segment.dom.find('img').each ->
      img = $(this)

      return if img.data("vspace-processed")? == "yes"

      img.data "vspace-processed", "yes" # Mark as already-processed

      if img.height() > vspace()
        img.height vspace()
        img.width 'auto'

      if img.width() > view.width()
        img.width '100%'
        img.height 'auto'

      img.click -> img.toggleClass('zoom')
    view.empty().append segment.dom

  selectView = (type) ->
    result
    viewTypes = ['stack', 'cartoon', 'plain']
    for viewType in viewTypes
      view = $("#book-#{viewType}-content")
      if viewType is type
        result = view
      else
        view.hide()
    result?.show()
    return result

  renderText = (text) -> selectView('plain').html text

  lastRender = null
  renderSegment = (segment) ->
    now = new Date()
    renderDelta = now - lastRender if lastRender

    if segment
      section = segment.document.book.getSectionBySegment segment # lol
      $('.player-chapter-title').text section.title
      switch segment.type
        when 'cartoon'
          renderCartoon segment, selectView(segment.type), renderDelta
        else
          renderStack segment, selectView('stack'), renderDelta
    else
      selectView null # Clears the content area

    lastRender = now

# Public API

  renderSegment: renderSegment
  renderText:    renderText
  focusEasing:   focusEasing
  focusDuration: focusDuration
