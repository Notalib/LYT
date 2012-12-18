# Requires `/common`  
# Requires `/support/jqm/jqm.extensions`  
# Requires `i18n`  

# -------------------

# This module keeps track of who is trying to load what and animates the interface appropriately

LYT.loader = do ->
  
  # ## Privileged API
    
  loaders = []
  defaultMessage = "Loading"
  
  # Safari mobile will pause most running JavaScript, causing any running
  # fade effects to stop. This is handled by attaching the handler below that
  # will fade back in if it is necessary.
  # TODO: Handle fading out if a loader is active (requires larger rewrite)
  $(window).on 'focus', -> jQuery(".ui-page-active").fadeTo(500, 1) if loaders.length is 0 
    
  lockPage = -> 
    #todo: implement interface locking
    #$('document').click (event) ->
    #  log.message "someone tried to click something while we are loading"
    #  event.preventDefault()
    #  event.preventDefaultPropagation()
  
  unlockPage = -> 
    #todo: implement interface unlocking
  
  # ## Public API
  
  # Register a Promise. When the Promise finishes,
  # it'll close its loading message.  
  # There are 2 ways to call this method:
  # 
  #     LYT.loader.register promiseObj
  # 
  # which uses the default message, or:
  # 
  #     LYT.loader.register message, promiseObj
  register: (message, promise, delay) ->
    [message, promise] = [defaultMessage, promise] if arguments.length is 1
    return unless promise.state() is "pending"
    @set message, promise, false, delay
    promise.always => @close promise
  
  # Set a custom loading message
  set: (message, id, clearStack = true, delay) ->
    # register new loader with ID, if clearStack is true close all previous loaders
    loaders = [] if clearStack
    loaders.push id
    setMessage = ->
      return if jQuery.inArray(id, loaders) is -1
      log.message "Loader: set: setMessage #{message}"
      jQuery.mobile.showPageLoadingMsg LYT.i18n(message)
      lockPage
    if delay?
      log.message "Loader: set: schedule message #{message}, delay #{delay}"
      setTimeout setMessage, delay
    else
      setMessage()
    $(".ui-loader h1").attr("role", "alert")
  
  # in JQueryMobile 1.2 there is a update to the loader (but ugly layout), so we are using our own css.
  # Close a loading message
  close: (id) ->
    # close loader with id and unlock interface if all loaders are closed
    loaders.splice index, 1 while (index = loaders.indexOf id) isnt -1
    
    if loaders.length is 0
      $.mobile.loading 'hide'
      unlockPage()
  
  # Clear the loading stack
  clear: ->
    loaders = []
    $.mobile.loading 'hide'
    unlockPage()
  

