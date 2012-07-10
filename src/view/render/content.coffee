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
  
  focusImg = (image, area) ->
    view = image.parent()

    scale = 1;
    if view.width() < area.width
      scale = view.width() / area.width
    else if vspace() < area.height
      scale = vspace() / area.height
    # FIXME: resizing div to fit content in case div is too large
    image.width Math.floor image[0].naturalWidth * scale;
    image.height Math.floor image[0].naturalHeight * scale;
    image.css('top', Math.floor(- area.tl.y * scale))
    offset = image.offset()
    offset.left = hspace() / 2 - (area.tl.x + area.width/2) * scale
    image.offset offset
  
  renderCartoon = (segment, view) ->
    div   = segment.divObj or= jQuery segment.div
    image = segment.imgObj or= jQuery segment.image
    
    # TODO: Optimization: don't re-render if this image is already on display
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
    
    focusImg image, area
    
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
