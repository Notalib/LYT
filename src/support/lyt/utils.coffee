# Requires `/lyt`

# -------------------

LYT.utils =

  # Convert seconds to a timecode string, e.g.
  #     LYT.utils.formatTime(3723) #=> "1:02:03"
  formatTime: (seconds) ->
    seconds = parseInt(seconds, 10)
    seconds = 0 if not seconds or seconds < 0
    hours   = (seconds / 3600) >>> 0
    minutes = "0" + (((seconds % 3600 ) / 60) >>> 0)
    seconds = "0" + (seconds % 60)
    "#{hours}:#{minutes.slice -2}:#{seconds.slice -2}"

  # Convert a timecode string ("H:MM:SS" or "MM:SS") to seconds, e.g.
  #     LYT.utils.parseTime("1:02:03") #=> 3723
  parseTime: (string) ->
    components = String(string).match /^(\d*):?(\d{2}):(\d{2})$/
    return 0 unless components?
    components.shift()
    components = (parseInt(component, 10) || 0 for component in components)
    components[0] * 3600 + components[1] * 60 + components[2]

  toSentence: (array) ->
    return "" if not (array instanceof Array) or array.length is 0
    return String(array[0]) if array.length is 1
    "#{array.slice(0, -1).join(", ")} & #{array.slice(-1)}"


  # This utility function converts the arguments given to well-formed XML
  # CHANGED: This function now _will_ re-encode encoded entities.
  # I.e. "&amp;" becomes "&amp;amp;"
  toXML: do ->
    # Defined inside a closure since it's recursive and needs to be
    # able to call itself regardless of its name "on the outside"
    toXML = (hash) ->
      xml = ""

      # Handling of namespaces could be done here by initializing a string
      # containing the necessary declarations that can be inserted in append()

      # Append XML-strings by recursively calling `toXML`
      # on the data
      append = (nodeName, data) ->
        nsid = 'ns1:'
        if jQuery.inArray(':', nodeName) > -1
          nsid = ''

        attributes = ''
        if data?.$attributes
          for own key, value of data.$attributes
            escaped = value.replace(/\"/g, '\\"').replace(/\'/g, "\\'")
            attributes += " #{key}=\"#{escaped}\""

          delete data.$attributes

        xml += "<#{nsid}#{nodeName}#{attributes}>#{toXML data}</#{nsid}#{nodeName}>"

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

