# Higher-level functions for interacting with the server 

LYT.service =
  logOn: (username, password) ->
    deferred = jQuery.Deferred()
    
    # For readability, the handlers are separated out here
    logOnHandler = (success) ->
      LYT.rpc("getServiceAttributes")
        .then(serviceAttrsHandler)
        .fail(fail)
    
    serviceAttrsHandler = (operations) ->
      LYT.rpc("setReadingSystemAttributes")
        .fail(fail)
      
      if operations.indexOf("SERVICE_ANNOUNCEMENTS") is -1
        deferred.resolve []
      else
        LYT.rpc("getServiceAnnouncements")
          .then (announcements) -> deferred.resolve announcements
          .fail(fail)    
    
    fail = (code, message) -> deferred.reject code, message
    
    LYT.rpc("logOn", username, password)
      .then(logOnHandler)
      .fail(fail)
    
    deferred
  
  logOff: ->
    LYT.rpc("logOff")
  
  
  getBookshelf: (from = 0, to = -1) ->
    deferred = jQuery.Deferred()
    LYT.rpc("getContentList", "issued", from, to)
      .then (list) ->
        for item in list
          info = item.label?.split("$")
          item.author = info[0] or ""
          item.title  = info[1] or ""
          delete item.label
        deferred.resolve list
        
      .fail -> deferred.reject()
    
    deferred
  
      
