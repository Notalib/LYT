# Requires `/common`

# -------------------

# This module provides a simple API for the browser's `localStorage` object
#
# Objects are stored under a namespace and an ID. The namespace is intended
# to collect similar objects, whereas the ID is unique within the given
# namespace.
#
# The objects are stored as JSON strings along with a timestamp. Should the
# `localStorage` object run out of space, other objects in the namespace
# will be deleted from oldest to newest until there's room.

LYT.cache = do =>
  supported = do ->
    try
      window.localStorage?
    catch
      false

  # ## Privileged API

  getCache = (key) ->
    return null unless supported
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

  # --------------------

  # ## Public API

  # Retrieve the object with the given namspace (prefix) and ID
  read: (prefix, id) ->
    return null unless supported
    cache = getCache "#{prefix}/#{id}"
    cache?.data or null

  # Store an object under the given namspace (prefix) and ID
  write: (prefix, id, data) ->
    return null unless supported
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
        localStorage.setItem "#{prefix}/#{id}", JSON.stringify(cache)
        success = true
      catch error
        if error.name is "QUOTA_EXCEEDED_ERR"
          removeOldest prefix
        else
          break

    success

  # Delete the given object from `localStorage`
  remove: (prefix, id) ->
    return null unless supported
    log.message "Cache: Deleting '#{prefix}/#{id}'"
    removeCache "#{prefix}/#{id}"

