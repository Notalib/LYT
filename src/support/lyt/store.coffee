# Requires `/common`
# -------------------

LYT.store =
  # Retrieve the object with the given ID
  read: (id) ->
    log.message "Store: Reading '#{id}'"
    localStorage.getItem id

  # Store an object under the given ID
  write: (id, data) ->
    log.message "Store: Writing '#{id}'"

    if typeof data is "object"
      log.warn "Coercing data into object", data
      data = JSON.stringify data

    try
      localStorage.setItem id, data
    catch error
      # Throw error unless it's a qouta-exceeded error
      throw error unless error.code is 22 or error.code is 1014
      log.warn "Silently ignoring quota limit error"

  # Delete the given object from `localStorage`
  remove: (id) ->
    log.message "Store: Deleting '#{id}'"
    localStorage.removeItem id

