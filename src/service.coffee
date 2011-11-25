# Higher-level functions for interacting with the server
#
# The `service` object may emit the following events:
# 
# - `logon:rejected` (data: none) - The username/password was rejected, or
#    not supplied. User must log in
# - `error:rpc` (data: `{code: [error constant]}`) - A communication error, e.g. timeout, occurred
# - `error:service` (data: `{code: [error constant]}`) - The server barfed
#
#
#

window.SERVICE_MUST_LOGON_ERROR = {}

LYT.service = do ->
  # "session" storage
  session =
    username: null
    password: null
  
  # The current logon process
  currentLogOnProcess = null
  
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
        emit "error:server", code: code
  
  # TODO: Store the currently outstanding logon-process?
  
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
  logOn = (username = session.username, password = session.password) ->
    # Check for pending logon processes
    return currentLogOnProcess if currentLogOnProcess? and currentLogOnProcess.state is "pending"
    
    deferred = currentLogOnProcess = jQuery.Deferred()
    
    unless username? and password?
      emit "logon:rejected"
      deferred.reject SERVICE_MUST_LOGON_ERROR
      return deferred
    
    session.username = username
    session.password = password
    
    # optional operations  
    # TODO: Handle this better
    operations = null
    
    # The maximum number of attempts to make
    attempts = LYT.config.service.logOnAttempts
    
    # (For readability, the handlers are separated out here)
    
    # FIXME: Flesh out error handling
    failed = (code, message) ->
      if code is RPC_UNEXPECTED_RESPONSE_ERROR
        emit "logon:rejected"
        deferred.reject SERVICE_MUST_LOGON_ERROR, "Logon rejected"
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
  

