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

    panZoomImage segment, image, area, renderDelta

  prevActive = null
  segmentIntoView = (view, segment) ->
    view = $(view)
    el = view.find "##{segment.contentId}"

    # Remove highlighting of previous element
    if prevActive
      prevActive.removeClass "active"

    # Highlight element and scroll to element
    if el.length
      prevActive = el.addClass "active"
      el[0].scrollIntoView()

  # Context viewer - Shows the entire DOM of the content document and
  # scrolls around when appropriate
  renderContext = (segment, view, delta) ->
    book = segment.document.book
    html = book.resources[segment.contentUrl].document
    source = html.source[0]
    view = view[0]

    contentID = "#{book.id}/#{segment.contentUrl}"
    if $(view).data("htmldoc") is contentID
      segmentIntoView view, segment
    else
      log.message "Render: Changing context to #{contentID}"
      $(view).data "htmldoc", contentID

      # Don't load all images from document
      html.hideImages "css/images/ajax-loader.gif"

      # Change to new document
      view.replaceChild(
        document.importNode(source.body.firstChild, true),
        view.firstChild
      )

      view = $(view)
      images = view.find "img"

      if images.length
        margin = 200 # TODO Should be configurable
        showImage = (image, ct, cb) ->
          image = jQuery image
          offset = image.offset()
          if ((ct < offset.top < cb) or
              (ct < offset.bottom < cb)) and image.attr("data-src")?
            image.attr "src", image.attr "data-src"
            image.removeAttr "data-src"

        scrollHandler = ->
          ct = view.scrollTop() - margin
          cb = ct + view.height() + 2 * margin
          images.each -> showImage this, ct, cb

        view.scroll jQuery.throttle 150, scrollHandler

      LYT.render.setStyle()
      segmentIntoView view, segment
      scrollHandler() if scrollHandler? # Show images which visible initially

      # Catch links
      view.find("a[href]").click (e) ->
        e.preventDefault()
        LYT.player.seekSmilOffsetOrLastmark @getAttribute "href"

  selectView = (type) ->
    for viewType in ['cartoon', 'plain', 'context']
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
      if segment.sectionTitle or segment.beginSection
        $('.player-chapter-title').text segment.sectionTitle or segment.beginSection.title

      switch segment.type
        when 'cartoon'
          renderCartoon segment, selectView(segment.type), renderDelta
        else
          requestAnimationFrame ->
            renderContext segment, selectView('context'), renderDelta
    else
      selectView null # Clears the content area

    lastRender = now

# Public API

  renderSegment: renderSegment
  renderText:    renderText
  focusEasing:   focusEasing
  focusDuration: focusDuration
