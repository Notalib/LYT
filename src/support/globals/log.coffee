# A facade for `console.*` functions
# TODO: Move to LYT namespace or to separate project
@log = do ->
  console = window.console

  $(document).one 'pagecreate', ->
    # Use developer console if the user clicks the header element six times
    clicks = 0
    reset = -> clicks = 0
    timer = null
    $(':jqmData(role=header)').bind 'click', ->
      clicks++
      if clicks == 6
        log.receiver = 'devconsole'
        log.level = 3
        log.message 'Opened developer console'
      else if clicks < 6
        clearTimeout timer if timer
        timer = setTimeout reset, 2000

  started = new Date()

  setTime = (messages) ->
    jQuery.map messages, (message) ->
      if typeof message is 'string'
        "[#{new Date() - started}] #{messages[0]}"
      else
        message

  logMethodMessages = (method, messages) ->
    return unless messages.length > 0 and messages[0] isnt null
    if log.receiver in ['all', 'local']
      method or= console?.log
      if method?.apply?
        method.apply console, setTime messages
      else
        # TODO: This should be rewritten to
        # if method
        #   method message for message in setTime messages
        messageArray = setTime messages
        if method
          for message in messageArray
            method message

    if log.receiver in ['all', 'remote']
      data =
        method:   method
        messages: setTime messages
      seen = []
      jsonData = JSON.stringify data, (key, value) ->
        if typeof value is 'object'
          return '__stub__' if jQuery.inArray(value, seen) >= 0
          seen.push value
        return value

      options =
        url:         LYT.config.mobileMessage.LogError.url
        dataType:    'json'
        type:        'POST'
        contentType: 'application/json; charset=utf-8'
        error:       (jqXHR, description, error) -> console?.log 'Logging to server failed: ' + description + ', ' + JSON.stringify error
        data:        jsonData

      # Perform the request
      jQuery.ajax options

    if log.receiver in ['all', 'devconsole']
      $('#devconsole-container').show()
      for message in setTime messages
        if typeof message is 'object'
          txtMessage = null
          if JSON?
            try
              txtMessage = JSON.stringify $.extend {}, message
            catch err
              txtMessage = null

          txtMessage = Object.prototype.toString.call message unless txtMessage?

          message = txtMessage

        $('#devconsole').append '<br/>' + message
        $('#devconsole-container').scrollTop $('#devconsole').height()

  # The level of logging:
  #     0 = No logging
  #     1 = Errors
  #     2 = Errors & warnings
  #     3 = Errors, warnings, and messages (everything)
  level: 0
  # Receiver of logs:
  #     none       = No receiver
  #     local      = Log to the built in console
  #     remote     = Send log entries to server
  #                  (The entries may arrive out of order.)
  #     devconsole = Log to developer console on screen (home brew)
  #     all        = Log to all of the above
  receiver: 'none'
  # To filter the log, set this value to a function that returns true for
  # all items that should appear in the log. If the function throws an
  # exception, the item will appear in the log.
  filter: null

  _filter: (type, messages, title) ->
    try
      return log.filter type, messages, title
    return true

  # Error-checking alias for `console.log()`
  # Logging level: 3 or higher
  message: (messages...) ->
    return unless log.level > 2
    return unless log._filter 'message', messages
    logMethodMessages console?.log, messages

  # Error-checking alias for `console.error()` (falls back to `console.log`)
  # Logging level: 1 or higher
  error: (messages...) ->
    return unless log.level > 0
    return unless log._filter 'error', messages
    logMethodMessages console?.error, messages

  # Error-checking alias for `console.warn()` (falls back to `console.log`)
  # Logging level: 2 or higher
  warn: (messages...) ->
    return unless log.level > 1
    return unless log._filter 'warn', messages
    logMethodMessages console?.warn, messages

  # Error-checking alias for `console.info()` (falls back to `console.log`)
  # Logging level: 3 or higher
  info: (messages...) ->
    return unless log.level > 2
    return unless log._filter 'info', messages
    logMethodMessages console?.info, messages

  # Log a group of messages. By default, it'll try to call `console.groupCollapsed()` rather
  # than `console.group()`. If neither function exists, it'll fake it with `log.message`
  #
  # The first argument is the title of the group. If you pass more than 1 argument,
  # the remaining arguments will each be logged inside the group by `log.message`, and
  # the group will be "closed" with `log.groupEnd`
  #
  # Logging level: 3 or higher
  group: (title = "", messages...) ->
    return unless log.level > 2
    return unless log._filter 'group', messages, title
    method = console?.groupCollapsed or console?.group
    if method?
      method.call console, title
    else
      @message "=== #{title} ==="

    if messages.length > 0
      @message message for message in messages

    @closeGroup()

  # Same as `group` except it'll log when `config.logging` is 1 or higher
  # Logging level: 1 or higher and messages will be logged as errors
  errorGroup: (title = "", messages...) ->
    return unless log.level > 0
    return unless log._filter 'errorGroup', messages, title
    method = console?.groupCollapsed or console?.group
    if console?.groupCollapsed?
      console.groupCollapsed title
    else if console?.group?
      console.group title
    else
      @error "=== #{title} ==="

    if messages.length > 0
      @error message for message in messages

    @closeGroup()

  # Closes an open group
  # Logging level: 1 or higher
  closeGroup: ->
    return unless log.level > 0
    if console?.groupEnd?
      console.groupEnd "=== *** ==="
    else
      @message "=== *** ==="

  # Error-checking alias for `console.trace`
  # Logging level: 1 or higher
  trace: ->
    return unless log._filter 'trace', messages, title
    return unless log.level > 0
    console?.trace?()
