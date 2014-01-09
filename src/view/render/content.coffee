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

  segmentIntoView = (view, segment) ->
    el = jQuery(view).find "##{segment.contentId}"
    if el.length
      el.get(0).scrollIntoView()
      view.defaultView.scrollBy 0, -15

  # Context viewer - Shows the entire DOM of the content document and
  # scrolls around when appropriate
  renderContext = (segment, view, delta) ->
    book = segment.document.book
    html = book.resources[segment.contentUrl].document
    source = html.source[0]
    viewer = view.find "iframe"
    viewDoc = viewer.get(0).contentDocument

    contentID = "#{segment.document.book.id}/#{segment.contentUrl}"
    if viewer.data("htmldoc") is contentID
      segmentIntoView viewDoc, segment
    else
      log.message "Render: Changing context to #{contentID}"
      viewer.data "htmldoc", contentID

      # Don't load all images from document
      html.hideImages "css/images/ajax-loader.gif"

      # Change to new document
      viewDoc.replaceChild(
        viewDoc.importNode(source.documentElement, true),
        viewDoc.documentElement
      )

      docEl = jQuery viewDoc.documentElement


      # The #document of the <iframe>
      doc = viewer.contents()
      margin = 200 # TODO Should be configurable
      images = docEl.find "img"

      showImage = (image, ct, cb) ->
        image = jQuery image
        offset = image.offset()
        if ((ct < offset.top < cb) or
            (ct < offset.bottom < cb)) and image.attr("data-src")?
          image.attr "src", image.attr "data-src"
          image.removeAttr "data-src"


      # iOS devices adjusts the <iframe>'s height so that *all* of its content
      # is visible. Due to this *bug* we need to get scroll information from
      # the top-most body
      if /(iPad|iPhone|iPod)/g.test navigator.userAgent
        body = jQuery "body"
        scrollHandler = ->
          ct = body.scrollTop() - margin
          cb = ct + body.height() + 2 * margin
          images.each -> showImage this, ct, cb

        body.scroll jQuery.throttle 150, scrollHandler
      else
        scrollHandler = ->
          ct = doc.scrollTop() - margin
          cb = ct + viewer.height() + 2 * margin
          images.each -> showImage this, ct, cb

        doc.scroll jQuery.throttle 150, scrollHandler

        # Enable hardware acceleration
        # For whatever reason this chrashes iOS devices
        docEl
          .find('body')
          .css
            "transform": "translate3d(0, 0, 0)"
            "-webkit-transform": "translate3d(0, 0, 0)"


      # Catch links
      doc.ready ->
        LYT.render.setStyle()
        segmentIntoView viewDoc, segment
        docEl.find("a[href]").click (e) ->
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
      section = segment.document.book.getSectionBySegment segment # lol
      $('.player-chapter-title').text section.title

      switch segment.type
        when 'cartoon'
          renderCartoon segment, selectView(segment.type), renderDelta
        else
          renderContext segment, selectView('context'), renderDelta
    else
      selectView null # Clears the content area

    lastRender = now

# Public API

  renderSegment: renderSegment
  renderText:    renderText
  focusEasing:   focusEasing
  focusDuration: focusDuration
