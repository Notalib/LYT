# Requires `/common`
# Requires `/view/render`

# -------------------

# This module handles rendering of book content
console.log 'Load LYT.render.content'
LYT.render.content = do ->
  
  _focusEasing   = 'easeInOutQuint'
  _focusDuration = 2000
  
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
    $('#book-text-content').prevAll().each (i, e) ->
      result -= $(e).height()
    return result
    
  # Return how much horizontal space that is available
  hspace = -> $(window).width()

  # Given an image and an area of the image, return how the image
  # should be translated in cordinates relative to its containing div.
  # New width and height is returned as well.
  # The object returned contains css attributes that will do the translation.
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
    left: Math.floor((image[0].naturalWidth/2 - area.tl.x - area.width/2)*scale)

  # Move straight to focus area without any effects  
  focusImage = (image, area) ->
    nextFocus = translate image, area
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.data 'LYT-focus', nextFocus
    image.css nextFocus
  
  # Move to focus area with effects specified in focusDuration() and focusEasing()
  panZoomImage = (segment, image, area) ->
    nextFocus = translate image, area
    thisFocus = image.data('LYT-focus') or translate image, wholeImageArea image
    image.animate nextFocus, focusDuration(), focusEasing(), () ->
      image.data 'LYT-focus', nextFocus
      if area.height/area.width > 2 and area.height > vspace() * 2
        panArea = jQuery.extend {}, area
        panArea.height = area.width
        image.animate translate(image, panArea), focusDuration(), focusEasing(), () ->
          panArea.tl.y = area.height - panArea.height
          image.animate translate(image, panArea), (segment.end - segment.start)*1000 - 2 * focusDuration(), 'linear'
  
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
    
  # Render cartoon - a cartoon page with one or more focus areas
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
    
    panZoomImage segment, image, area
    
    return true

  # Standard renderer - render everything in the text document
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

  render:        render
  focusEasing:   focusEasing
  focusDuration: focusDuration
