# This module keeps track of who is trying to load what and animates the interface appropriately

LYT.loader = do ->
  
  # ## Privileged API
    
  loaders = []
  
  uiLock = ->
    jQuery(".ui-page-active").fadeTo(500, 0.4)
    #todo: implement interface locking
    #$('document').click (event) ->
    #  log.message "someone tried to click something whle we are loading"
    #  event.preventDefault()
    #  event.preventDefaultPropagation()
  
  uiUnLock = ->
    jQuery(".ui-page-active").fadeTo(500, 1)
  
  # ## Public API
  
  set: (msg, id, clearStack=true) ->
    # register new loader with ID, if clearStack is true close all previous loaders
    
    jQuery.mobile.showPageLoadingMsg(msg)
    if loaders.length is 0
      uiLock()
    
    if clearStack
      loaders = [id]
    else
      loaders.push id
    
  clear: () ->
    loaders = []
    jQuery.mobile.hidePageLoadingMsg()
    uiUnLock()
  
  close: (id) ->
    # close loader with id and unlock interface if we all loaders are closed
    while (index = loaders.indexOf(id)) > -1
      loaders.splice index, 1
    
    if loaders.length is 0
      jQuery.mobile.hidePageLoadingMsg()
      uiUnLock()
  
