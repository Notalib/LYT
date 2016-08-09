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
  localStorageWrapper =
    get: (key) ->
      obj = localStorage.getItem key
      obj && JSON.parse obj

    set: (key, val) ->
      localStorage.setItem key, val

    remove: (key) ->
      localStorage.removeItem key

  localPersistence = do =>
    data = {}

    get: (key) ->
      data[key] && JSON.parse data[key]

    set: (key, val) ->
      data[key] = val

    remove: (key) ->
      delete data[key]

  supported = do ->
    support = 'issupported'
    try
      localStorage.setItem support, support
      localStorage.removeItem support, support
      true
    catch
      false

  # In case localStorage is not supported, we still need to persist some
  # data just for the session - so we do so in an object
  storage = if supported then localStorageWrapper else localPersistence

  # ## Privileged API

  getTimestamp = -> (new Date).getTime()

  # ## Public API

  # Retrieve the object with the given namspace (prefix) and ID
  read: (prefix, id) ->
    cache = storage.get "#{prefix}/#{id}"
    cache?.data or null

  # Store an object under the given namspace (prefix) and ID
  write: (prefix, id, data) ->
    log.message "Cache: Writing '#{prefix}/#{id}'"
    storage.remove "#{prefix}/#{id}"

    if typeof data isnt "object"
      data = String data

    cache =
      type:      typeof data
      data:      data
      timestamp: getTimestamp()

    storage.set "#{prefix}/#{id}", JSON.stringify(cache)

  # Delete the given object from `localStorage`
  remove: (prefix, id) ->
    log.message "Cache: Deleting '#{prefix}/#{id}'"
    storage.remove "#{prefix}/#{id}"

