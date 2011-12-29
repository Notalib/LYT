# TODO: Split this file up? Perhaps namespace some of it
# under `LYT`? Or `utils`. Just seems a little weird that
# the global logging functions are dependent on e.g.
# `LYT.config`

# A facade for `console.*` functions
#
# These functions respect the `config.logging` setting
@log = do ->
  console = window.console or {}
  
  # Error-checking alias for `console.log()`  
  # Logging level: 3 or higher
  message: (messages...) ->
    return unless LYT.config.logging > 2
    console.log? messages...
  
  # Error-checking alias for `console.error()` (falls back to `console.log`)  
  # Logging level: 1 or higher
  error: (messages...) ->
    return unless LYT.config.logging > 0
    method = console.error or console.log
    method?.apply console, messages
  
  # Error-checking alias for `console.warn()` (falls back to `console.log`)  
  # Logging level: 2 or higher
  warn: (messages...) ->
    return unless LYT.config.logging > 1
    method = console.warn or console.log
    method?.apply console, messages
  
  # Error-checking alias for `console.info()` (falls back to `console.log`)  
  # Logging level: 3 or higher
  info: (messages...) ->
    return unless LYT.config.logging > 2
    (console.info or @message).apply console, messages
  
  # Log a group of messages. By default, it'll try to call `console.groupCollapsed()` rather
  # than `console.group()`. If neither function exists, it'll fake it with `log.message`
  # 
  # The first argument is the title of the group. If you pass more than 1 argument, 
  # the remaining arguments will each be logged inside the group by `log.message`, and
  # the group will be "closed" with `log.groupEnd`
  # 
  # Logging level: 3 or higher
  group: (title = "", messages...) ->
    return unless LYT.config.logging > 2
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
    return unless LYT.config.logging > 0
    method = console.groupCollapsed or console.group
    if method?
      method.call console, title
    else
      @error "=== #{title} ==="
    
    if messages.length > 0
      @error message for message in messages
      @closeGroup()
  
  # Closes an open group
  # Logging level: N/A
  closeGroup: ->
    (console.groupEnd or @message).call console, "=== *** ==="
  
  # Error-checking alias for `console.trace`  
  # Logging level: 1 or higher
  trace: ->
    return unless LYT.config.logging > 0
    console.trace?()
  
