# A facade for `console.*` functions
@log = do ->
  console = window.console or {}
  
  # The level of logging:  
  #     0 = No logging
  #     1 = Errors
  #     2 = Errors & warnings
  #     3 = Errors, warnings, and messages (everything)
  level: 3
  
  # Error-checking alias for `console.log()`  
  # Logging level: 3 or higher
  message: (messages...) ->
    return unless log.level > 2
    if console.log?.apply?
      console.log.apply console, messages 
    else
      console.log? messages
  
  # Error-checking alias for `console.error()` (falls back to `console.log`)  
  # Logging level: 1 or higher
  error: (messages...) ->
    return unless log.level > 0
    method = console.error or console.log
    if method?.apply?
      method.apply console, messages
    else
      method? messages
  
  # Error-checking alias for `console.warn()` (falls back to `console.log`)  
  # Logging level: 2 or higher
  warn: (messages...) ->
    return unless log.level > 1
    method = console.warn or console.log
    if method?.apply?
      method.apply console, messages
    else
      method? messages
  
  # Error-checking alias for `console.info()` (falls back to `console.log`)  
  # Logging level: 3 or higher
  info: (messages...) ->
    return unless log.level > 2
    method = (console.info or @message)
    if method?.apply?
      method.apply console, messages
    else
      method? messages
  
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
    method = console.groupCollapsed or console.group
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
    method = console.groupCollapsed or console.group
    if console.groupCollapsed?
      console.groupCollapsed title
    else if console.group?
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
    if console.groupEnd?
      console.groupEnd "=== *** ==="
    else
      @message "=== *** ==="
  
  # Error-checking alias for `console.trace`  
  # Logging level: 1 or higher
  trace: ->
    return unless log.level > 0
    console.trace?()
  
