LYT.cache = do =>
  
  read = (prefix, id) ->
    return null unless window.localStorage?
    log.message "Cache: Reading '#{prefix}/#{id}'"
    cache = getCache "#{prefix}/#{id}"
    cache?.data or null
  
  write = (prefix, id, data) ->
    return null unless window.localStorage?
    log.message "Cache: Writing '#{prefix}/#{id}'"
    removeCache "#{prefix}/#{id}"
    
    if typeof data isnt "object"
      data = String data
    
    cache =
      type:      typeof data
      data:      data
      timestamp: getTimestamp()
    
    success = false
    until success
      try
        # FIXME: Check that the JSON-object is available on all targeted platforms and/or use jQuery's options
        localStorage.setItem "#{prefix}/#{id}", JSON.stringify(cache)
        success = true
      catch error
        if error is QUOTA_EXCEEDED_ERR
          removeOldest prefix
        else
          break
    
    success 
  
  remove = (prefix, id) ->
    return null unless window.localStorage?
    log.message "Cache: Deleting '#{prefix}/#{id}'"
    removeCache "#{prefix}/#{id}"
  
  # ----------
  
  getCache = (key) ->
    return null unless window.localStorage?
    cache = localStorage.getItem key
    return null unless cache and (cache = JSON.parse(cache))
    cache
  
  removeCache = (key) ->
    try
      localStorage.removeItem key
    catch error
      return
  
  getTimestamp = -> (new Date).getTime()
  
  # TODO: Save timestamps elsewhere for quicker/lighter lookup?
  removeOldest = (prefix) ->
    oldestTimestamp = getTimestamp()
    oldestKey       = false
    
    for index in [0...localStorage.length]
      key = localStorage.key(index)
      if key?.indexOf(prefix) is 0
        cache = getCache key
        if cache.timestamp < oldestTimestamp
          oldestTimestamp = cache.timestamp
          oldestKey = key
    
    if oldestKey then removeCache key
  
  read:   read
  write:  write
  remove: remove
  
