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
  # Logging level: 2 or higher
  message: (messages...) ->
    return unless LYT.config.logging > 1
    console.log? messages...
  
  # Error-checking alias for `console.error()` (falls back to `console.log`)  
  # Logging level: 1 or higher
  error: (messages...) ->
    return unless LYT.config.logging > 0
    method = console.error or console.log
    method?.apply console, messages
  
  # Error-checking alias for `console.warn()` (falls back to `console.log`)  
  # Logging level: 1 or higher
  warn: (messages...) ->
    return unless LYT.config.logging > 0
    method = console.warn or console.log
    method?.apply console, messages
  
  # Error-checking alias for `console.info()` (falls back to `console.log`)  
  # Logging level: 2 or higher
  info: (messages...) ->
    return unless LYT.config.logging > 1
    (console.info or @message).apply console, messages
  
  # Log a group of messages. By default, it'll try to call `console.groupCollapsed()` rather
  # than `console.group()`. If neither function exists, it'll fake it with `log.message`
  # 
  # The first argument is the title of the group. If you pass more than 1 argument, 
  # the remaining arguments will each be logged inside the group by `log.message`, and
  # the group will be "closed" with `log.groupEnd`
  # 
  # Logging level: 2 or higher
  group: (title = "", messages...) ->
    return unless LYT.config.logging > 1
    method = console.groupCollapsed or console.group
    if method?
      method.call console, title
    else
      @message "=== #{title} ==="
    
    if messages.length > 0
      @message message for message in messages
      @closeGroup()
  
  # Same as `group` except it'll log when `config.logging` is 1 or higher  
  # Logging level: 1 or higher
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
  
# ---------

# Convert seconds to a timecode string, e.g.
#     formatTime(3723) #=> "1:02:03"
@formatTime = (seconds) ->
  seconds = parseInt(seconds, 10)
  seconds = 0 if not seconds or seconds < 0
  hours   = (seconds / 3600) >>> 0
  minutes = "0" + (((seconds % 3600 ) / 60) >>> 0)
  seconds = "0" + (seconds % 60)
  "#{hours}:#{minutes.slice -2}:#{seconds.slice -2}"

# Convert a timecode string ("H:MM:SS" or "MM:SS") to seconds, e.g.
#     parseTime("1:02:03") #=> 3723
@parseTime = (string) ->
  components = String(string).match /^(\d*):?(\d{2}):(\d{2})$/
  return 0 unless components?
  components.shift()
  components = (parseInt(component, 10) || 0 for component in components)
  components[0] * 3600 + components[1] * 60 + components[2]

@toSentence = (array) ->
  return "" if not (array instanceof Array) or array.length is 0
  return String(array[0]) if array.length is 1
  "#{array.slice(0, -1).join(", ")} & #{array.slice(-1)}"
  
@getParam = (name, hash) ->
  match = RegExp('[?&]' + name + '=([^&]*)').exec(hash);
  return match and decodeURIComponent(match[1].replace(/\+/g, ' '))

# This utility function converts the arguments given to well-formed XML  
# CHANGED: This function now _will_ re-encode encoded entities.
# I.e. "&amp;" becomes "&amp;amp;"
@toXML = do ->
  # Defined inside a closure since it's recursive and needs to be
  # able to call itself regardless of its name "on the outside"
  toXML = (hash) ->
    xml = ""
    
    # Append XML-strings by recursively calling `toXML`
    # on the data
    append = (nodeName, data) ->
      xml += "<ns1:#{nodeName}>#{toXML data}</ns1:#{nodeName}>"
    
    switch typeof hash
      when "string", "number", "boolean"
        # If the argument is a string, number or boolean,
        # then coerce it to a string and use a pseudo element
        # to handle the escaping of special chars
        return jQuery("<div>").text(String(hash)).html()
    
      when "object"
        # If the argument is an object, go through its members
        for own key, value of hash
          if value instanceof Array
            # If the member is an array, use the `key`
            # as the node name for each item
            append key, item for item in value
          else
            # If the member's something else, pass it
            # on to `append`
            append key, value
    xml

