# Higher-level functions for interacting with the server 

# FIXME: Check for errors and attempt re-login etc.

# ## Faults (cf. [Daisy specification](http://www.daisy.org/projects/daisy-online-delivery/drafts/20100402/do-spec-20100402.html#apiReferenceFaults))
window.SERVICE_MUST_LOGON_ERROR     = "mustLogOnError"
window.SERVICE_INTERNAL_ERROR       = "internalServerError"
window.SERVICE_NO_SESSION_ERROR     = "noActiveSession"
window.SERVICE_UNSUPPORTED_OP_ERROR = "operationNotSupported"
window.SERVICE_INVALID_OP_ERROR     = "invalidOperation"
window.SERVICE_INVALID_PARAM_ERROR  = "invalidParameter"


LYT.service = do ->
  # "session" storage
  session =
    username: null
    password: null
  
  # TODO: Store the currently outstanding logon-process?
  
  # Wraps a call in a couple of checks: If the call the fails,
  # check if the reason is due to the user not being logged in.
  # If that's the case, attempt logon, and attempt the call again
  withLogOn = (callback) ->
    deferred = jQuery.Deferred()
    result = callback()
    
    success = (args...) ->
      deferred.resolve args...
    
    failure = (code, message) ->
      deferred.reject code, message
    
    # If everything works, then just pass on the resolve args
    result.done success
    
    # If the call fails
    result.fail (code, message) ->
      # Is it because the user's not logged in?
      if code is SERVICE_NO_SESSION_ERROR
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
          .fail(failure)
      else
        failure code, message
    
    deferred
  
  # Perform the logOn handshake:
  # logOn -> getServiceAttributes -> setReadingSystemAttributes
  logOn = (username = session.username, password = session.password) ->
    deferred = jQuery.Deferred()
    
    unless username? and password?
      deferred.reject SERVICE_MUST_LOGON_ERROR
      return deferred
    
    session.username = username
    session.password = password
    
    # optional operations  
    # TODO: Handle this better
    operations = null
    
    attempts = 2
    
    # (For readability, the handlers are separated out here)
    
    # FIXME: Flesh out error handling
    failed = (code, message) ->
      if code is RPC_UNEXPECTED_RESPONSE_ERROR
        deferred.reject SERVICE_MUST_LOGON_ERROR, "Logon rejected"
      else if --attempts
        attemptLogOn()
      else
        deferred.reject code, message
      
    loggedOn = (success) ->
      LYT.rpc("getServiceAttributes")
        .done(gotServiceAttrs)
        .fail(failed)
    
    gotServiceAttrs = (ops) ->
      operations = ops
      LYT.rpc("setReadingSystemAttributes")
        .done(readingSystemAttrsSet)
        .fail(failed)
    
    readingSystemAttrsSet = ->
      deferred.resolve()
      
      # TODO: If there are service announcements, do they have to be
      # retrieved before the handshake is considered done?
      if operations.indexOf("SERVICE_ANNOUNCEMENTS") isnt -1
        LYT.rpc("getServiceAnnouncements")
          .done(gotServiceAnnouncements)
          # Fail silently
    
    # FIXME: Not implemented
    gotServiceAnnouncements = (announcements) ->
    
    
    attemptLogOn = ->
      LYT.rpc("logOn", username, password)
        .done(loggedOn)
        .fail(failed)
    
    
    # Kick it off
    attemptLogOn()
    
    return deferred
  
  # -- Return ---
  
  logOn: logOn
  
  # TODO: Can logOff fail? If so, what to do?
  logOff: ->
    LYT.rpc("logOff").always ->
      session.username = null
      session.password = null
  
  
  issue: (bookId) ->
    withLogOn -> LYT.rpc "issueContent", bookId
    
  
  
  return: (bookId) ->
    withLogOn -> LYT.rpc "returnContent", bookId
  
  
  getMetadata: (bookId) ->
    withLogOn -> LYT.rpc "getContentMetadata", bookId
  
  
  getResources: (bookId) ->
    withLogOn -> LYT.rpc "getContentResources", bookId
  
  
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
  
  
  # Non-Daisy function
  search: (query) ->
  

