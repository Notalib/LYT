# Higher-level functions for interacting with the server 

LYT.service =
  # Perform the logOn handshake:
  # logOn -> getServiceAttributes -> setReadingSystemAttributes
  logOn: (username, password) ->
    deferred = jQuery.Deferred()
    operations = null
    
    # For readability, the handlers are separated out here
    failed = (code, message) ->
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
    
    # Kick it off
    LYT.rpc("logOn", username, password)
      .done(loggedOn)
      .fail(failed)
    
    return deferred
  
  # TODO: Can logOff fail? If so, what to do?
  logOff: ->
    LYT.rpc("logOff")
  
  
  getBookshelf: (from = 0, to = -1) ->
    deferred = jQuery.Deferred()
    LYT.rpc("getContentList", "issued", from, to)
      .then (list) ->
        for item in list
          [item.author, item.title] = item.label?.split("$") or ["", ""]
          delete item.label
        deferred.resolve list
        
      .fail -> deferred.reject()
    
    return deferred
  
      
