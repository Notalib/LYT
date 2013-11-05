# Requires `/common`
# Requires `/models/member/session`

# -------------------

# This module handles error message and other messages needed to be returned to NOTA...

# --------

# ## Constants

window.MOBILEMESSAGE_GENERAL_ERROR = {}

# --------

# Define the `LYT.mobileMessage` object
LYT.mobileMessage = do ->

  emit = (event, data = {}) ->
    obj = jQuery.Event event
    delete data.type if data.hasOwnProperty "type"
    jQuery.extend obj, data
    log.message "mobileMessage: Emitting #{event} event"
    jQuery(LYT.mobileMessage).trigger obj


  getAjaxOptions = (url, data) ->
    dataType:    "json"
    type:        "POST"
    contentType: "application/json; charset=utf-8"
    data:        JSON.stringify data
    url:         url

  GetVersion = (data = null) ->
    deferred = jQuery.Deferred()
    url  = LYT.config.mobileMessage.GetVersion.url
    options = getAjaxOptions url, data

    # Perform the request
    jQuery.ajax(options)
      # On success, extract the results and pass them on
      .done (data) ->
        #Making a javascript object...
        JSONResult = data.d
        deferred.resolve JSONResult
      # On fail, reject the deferred
      .fail ->
        deferred.reject()

    deferred.promise()


  NotifyMe = (item, userId) ->
    # ## Public API
    serverRequestData = {}
    serverRequestData.item = String(item)
    serverRequestData.userId = String(userId)

    deferred = jQuery.Deferred()
    url  = LYT.config.mobileMessage.NotifyMe.url
    options = getAjaxOptions url, serverRequestData

    # Perform the request
    jQuery.ajax(options)
      # On success, extract the results and pass them on
      .done (data) ->
        #Making a javascript object...
        JSONResult = data.d
        deferred.resolve JSONResult
      # On fail, reject the deferred
      .fail ->
        deferred.reject()

    deferred.promise()

  # ## Public API
  GetVersion:        GetVersion
  NotifyMe:          NotifyMe
