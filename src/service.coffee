# Higher-level functions for interacting with the server
#
# The `service` object may emit the following events:
# 
# - `logon:rejected` (data: none) - The username/password was rejected, or
#    not supplied. User must log in
# - `error:rpc` (data: `{code: [RPC_* error constants]}`) - A communication error,
#    e.g. timeout, occurred (see [rpc.coffee](rpc.html) for error codes)
# - `error:service` (data: `{code: [DODP_* error constant]}`) - The server barfed
#    (see [rpc.coffee](rpc.html) for error constants)
#
# Events are emitted and can be observed via jQuery. Example:
#
#     jQuery(LYT.service).bind "logon:rejected", ->
#       # go to the log-in page

# ---------------

LYT.service = do ->
  
  # "session" storage  
  session =
    username: null
    password: null
  
  
  # optional service operations  
  operations =
    DYNAMIC_MENUS:         false
    SET_BOOKMARKS:         false
    GET_BOOKMARKS:         false
    SERVICE_ANNOUNCEMENTS: false
    PDTB2_KEY_PROVISION:   false
  
  
  getCredentials = ->
    unless session? and session.username? and session.password?
      session = LYT.cache.read "session", "credentials"
    session
  
  setCredentials = (username, password) ->
    session or= {}
    [session.username, session.password] = [username, password]
    LYT.cache.write "session", "credentials", session if session.username? and session.password?
  
  deleteCredentials = ->
    [session.username, session.password] = [null, null]
    LYT.cache.remove "session", "credentials"
  
  
  # The current logon process(es)
  currentLogOnProcess = null
  currentRefreshSessionProcess = null
  
  # Emit an event
  emit = (event, data = {}) ->
    obj = jQuery.Event event
    delete data.type if data.hasOwnProperty "type"
    jQuery.extend obj, data
    log.message "Service: Emitting #{event} event"
    jQuery(LYT.service).trigger obj
  
  
  # Emit an error event
  emitError = (code) ->
    switch code
      when RPC_GENERAL_ERROR, RPC_TIMEOUT_ERROR, RPC_ABORT_ERROR, RPC_HTTP_ERROR
        emit "error:rpc", code: code
      else
        emit "error:service", code: code
  
  
  # Wraps a call in a couple of checks: If the call the fails,
  # check if the reason is due to the user not being logged in.
  # If that's the case, attempt logon, and attempt the call again
  withLogOn = (callback) ->
    deferred = jQuery.Deferred()
    
    # If the call goes through
    success = (args...) ->
      deferred.resolve args...
    
    
    # If the call fails 
    failure = (code, message) ->
      emitError code
      deferred.reject code, message
    
    
    # Make the call
    result = callback()
    
    
    # If everything works, then just pass on the resolve args
    result.done success
    
    
    # If the call fails
    result.fail (code, message) ->
      # Is it because the user's not logged in?
      if code is DODP_NO_SESSION_ERROR
        # If so , the attempt log-on
        logOn()
          .done ->
            # Logon worked, so re-attempt the call
            callback()
              # If it works, this time around, then great
              .done(success)
              
              # If it doesn't, then give up
              .fail(failure)
          
          # Logon failed, so propagate the error
          .fail (code, message) ->
            deferred.reject code, message
      else
        failure code, message
    
    deferred
  
  # Perform the logOn handshake:
  # logOn -> getServiceAttributes -> setReadingSystemAttributes
  logOn = (username, password) ->
    # Check for pending logon processes
    return currentLogOnProcess if currentLogOnProcess? and currentLogOnProcess.state() is "pending"
    
    currentRefreshSessionProcess.reject() if currentRefreshSessionProcess? and currentRefreshSessionProcess.state() is "pending"
    
    deferred = currentLogOnProcess = jQuery.Deferred()
    
    if username and password
      setCredentials username, password
    else
      {username, password} = credentials if (credentials = getCredentials())
    
    unless username and password
      emit "logon:rejected"
      deferred.reject()
      return deferred
    
    session.username = username
    session.password = password
    
    # The maximum number of attempts to make
    attempts = LYT.config.service?.logOnAttempts? or 3
    
    # (For readability, the handlers are separated out here)
    
    # FIXME: Flesh out error handling
    failed = (code, message) ->
      if code is RPC_UNEXPECTED_RESPONSE_ERROR
        emit "logon:rejected"
        deferred.reject()
      else
        if attempts > 0
          attemptLogOn()
        else
          emitError code
          deferred.reject code, message
    
    
    loggedOn = (success) ->
      LYT.rpc("getServiceAttributes")
        .done(gotServiceAttrs)
        .fail(failed)
    
    
    gotServiceAttrs = (ops) ->
      operations[op] = false for op of operations
      operations[op] = true for op in ops
      LYT.rpc("setReadingSystemAttributes")
        .done(readingSystemAttrsSet)
        .fail(failed)
    
    
    readingSystemAttrsSet = ->
      deferred.resolve()
      
      if LYT.service.announcementsSupported()
        LYT.rpc("getServiceAnnouncements")
          .done(gotServiceAnnouncements)
          # Fail silently
          .fail -> # noop
    
    # FIXME: Not implemented
    gotServiceAnnouncements = (announcements) ->
    
    
    attemptLogOn = ->
      --attempts
      log.message "Service: Attempting log-on (#{attempts} attempt(s) left)"
      LYT.rpc("logOn", username, password)
        .done(loggedOn)
        .fail(failed)
    
    
    # Kick it off
    attemptLogOn()
    
    return deferred
  
  # -------
  # # Public API
  # ## Basic operations
  
  logOn: logOn
  
  # Silently attempt to refresh a session. I.e. if this fails, no logOn errors are
  # emitted directly. This is intended for use with e.g. DTBDocument.
  # However, if there's an explicit logon process running, it'll use that
  refreshSession: ->
    return currentLogOnProcess if currentLogOnProcess? and currentLogOnProcess.state() is "pending"
    return currentRefreshSessionProcess if currentRefreshSessionProcess? and currentRefreshSessionProcess.state() is "pending"
    deferred = currentRefreshSessionProcess = jQuery.Deferred()
    
    fail = -> deferred.reject()
    
    {username, password} = credentials if (credentials = getCredentials())
    unless username and password
      fail()
      return deferred
    
    loggedOn = ->
      LYT.rpc("getServiceAttributes").then gotServiceAttrs, fail
    
    gotServiceAttrs = ->
      LYT.rpc("setReadingSystemAttributes").then readingSystemAttrsSet, fail
    
    readingSystemAttrsSet = ->
      deferred.resolve()
    
    LYT.rpc("logOn", username, password).then loggedOn, fail
    
    deferred
  
  # TODO: Can logOff fail? If so, what to do? Very zen!  
  # Also, there should probably be some global "cancel all
  # outstanding ajax calls!" when log off is called
  logOff: ->
    LYT.rpc("logOff").always ->
      deleteCredentials()
      emit "logoff"
  
  
  issue: (bookId) ->
    withLogOn -> LYT.rpc "issueContent", bookId
    
  
  return: (bookId) ->
    withLogOn -> LYT.rpc "returnContent", bookId
  
  
  getMetadata: (bookId) ->
    withLogOn -> LYT.rpc "getContentMetadata", bookId
  
  
  getResources: (bookId) ->
    withLogOn -> LYT.rpc "getContentResources", bookId
  
  
  # The the list of issued content (i.e. the bookshelf)
  # Note: The `getContentList` API gets items by range
  # I.e. from 1 item index to (and including) another
  # index. So getting item 0 to 5, will get you 6 items.
  # Specifying `-1` as the `to` argument will get all
  # items from the `from` index to the end of the list
  getBookshelf: (from = 0, to = -1) ->
    deferred = jQuery.Deferred()
    
    response = withLogOn -> LYT.rpc("getContentList", "issued", from, to)
    
    response.done (list) ->
      for item in list
        # TODO: Using $ as a make-shift delimiter in XML? Instead of y'know using... more XML? Wow.  
        # To quote [Nokogiri](http://nokogiri.org/): "XML is like violence - if it doesn’t solve your problems, you are not using enough of it."
        [item.author, item.title] = item.label?.split("$") or ["", ""]
        delete item.label
      deferred.resolve list
    
    response.fail (err, message) -> deferred.reject err, message
    
    deferred
  
  # -------
  # ## Optional operations
  
  bookmarksSupported: ->
    operations.GET_BOOKMARKS and operations.SET_BOOKMARKS
  
  # TODO: Temporarily store and fetch bookmarks locally
  getBookmarks: (id) ->
    deferred = jQuery.Deferred()
    bookmarks = LYT.cache.read "bookmarks", id
    
    deferred.resolve bookmarks or null
    
    # TODO: Implement this properly
    # withLogOn -> LYT.rpc("getBookmarks", id)
  
  setBookmarks: (bookId, bookmarks) ->
    deferred = jQuery.Deferred()
    LYT.cache.write "bookmarks", bookId, bookmarks
    
    deferred.resolve()
    
    # TODO: Implement this properly
    # withLogOn -> LYT.rpc("setBookmarks", bookmarks)
  
  announcementsSupported: ->
    operations.SERVICE_ANNOUNCEMENTS
  

