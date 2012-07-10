# Requires `/common`
# Requires `/view/render`

# -------------------

# This module handles rendering of book content
console.log 'Load LYT.render.content'
LYT.render.content = do ->
  
  vspace = ->
    result = $(window).height()
    $('#book-text-content').prevAll().each (i, e) ->
      result -= $(e).height()
    return result
    
  hspace = -> $(window).width()

  # Given an image and an area of the image, return how the image
  # should be translated in cordinates relative to its containing div.
  # New width and height is returned as well
  translate = (image, area) ->
    result = {}
    view = image.parent()

    scale = 1;
    if view.width() < area.width
      scale = view.width() / area.width
    else if vspace() < area.height
      scale = vspace() / area.height
    # FIXME: resizing div to fit content in case div is too large
    # return
    width: Math.floor(image[0].naturalWidth * scale)
    height: Math.floor(image[0].naturalHeight * scale)
    top: Math.floor(- area.tl.y * scale)
    left: Math.floor(hspace() / 2 - (area.tl.x + area.width/2) * scale)
  
  focusImage = (image, area) ->
    nextFocus = translate image, area
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.data 'LYT-focus', nextFocus
    image.width nextFocus.width
    image.height nextFocus.height
    image.css 'top', nextFocus.top
    offset = image.offset()
    offset.left = nextFocus.left
    image.offset offset
    log.group 'content: focusImage: moved to new focus', nextFocus
    
  panZoomImage = (image, area) ->
    nextFocus = translate image, area
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.data 'LYT-focus', nextFocus
    
  # Return area object that will focus on the entire image
  wholeImageArea = (image) ->
      width:  image[0].naturalWidth
      height: image[0].naturalHeight
      tl:
        x: 0
        y: 0
      br:
        x: image[0].naturalWidth
        y: image[0].naturalHeight
    
  renderCartoon = (segment, view) ->
    div   = segment.divObj or= jQuery segment.div
    image = segment.imgObj or= jQuery segment.image
    
    if view.find('img').attr('src') is image.attr('src')
      image = view.find 'img'
    else
      image.css 'position', 'relative'
      view.empty().append image 
    
    left = parseInt (div[0].style.left.match /\d+/)[0]
    top  = parseInt (div[0].style.top.match /\d+/)[0]
    # FIXME: The calculations below are not working as they should (XXX)
    area =
      width:  div.width()  #image.naturalWidth
      height: div.height() #image.naturalHeight
      tl:
        x: left
        y: top
      br:
        x: left + div.width()  #image.naturalWidth
        y: top  + div.height() #image.naturalHeight
    
    focusImage image, area
    
    return true

  renderStandard = (segment, view) ->
    segment.dom or= $(document.createElement('div')).html segment.html
    segment.dom.find("img").each ->
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
  
  render = (segment, view) ->
    switch segment.type
      when 'cartoon' then renderCartoon segment, view
      else renderStandard segment, view

# Public API

  render: render
