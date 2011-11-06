# This function performs a remote procedure call from the `protocol` module
# 
# E.g.
# 
#     rpc "logOn", "someUser", "supeSekretPassword"
#
# See protocol.coffee for more

# --------

# Define `rpc` inside a closure
LYT.rpc = do ->
  
  # The template for SOAP request content
  soapTemplate = '<?xml version="1.0" encoding="UTF-8"?>
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://www.daisy.org/ns/daisy-online/">
    <SOAP-ENV:Body>#{body}</SOAP-ENV:Body>
    </SOAP-ENV:Envelope>'
  
  # The actual `rpc` function
  (action, args...) ->
    # Throw a fit if the argument isn't a string
    unless typeof action is "string"
      throw new TypeError
    
    # Also complain if the `protocol` module doens't contain the RPC
    unless protocol[action]?
      throw "RPC: Action \"#{action}\" not found"
    
    # Get the RPC object
    handlers = protocol[action]
    
    # Clone the default options
    options = jQuery.extend {}, config.rpc.options
    
    # Get the request data from the RPC's `request` function, if present, passing along any arguments
    soap = handlers.request?(args...) or null
    soap = null if typeof soap isnt "object"
    
    # Convert the data obj to XML and insert it into the SOAP template
    xml = {}
    xml[action] = soap
    xml = rpc.toXML xml
    xml = if xml isnt "" then "<ns1:#{action}>#{xml}</ns1:#{action}>" else "<ns1:#{action} />"
    options.data = soapTemplate.replace /#\{body\}/, xml
    
    # Log the call
    log.group "RPC: Calling \"#{action}\"", soap, options.data
    
    # Set up the success handler
    options.success  = (data, status, xhr) ->
      $xml = jQuery data
      # FIXME: Generalize the fault-handling to handle other faults too. Also, wouldn't it be better to check faultcodes rather than faultstrings?
      if $xml.find("faultstring").text().match errorRegExp
        log.group "RPC: Error: Invalid/uninitialized session"
        log.message data
        log.closeGroup()
        eventSystemNotLoggedIn()
      else
        log.group "RPC: Response for action \"#{action}\""
        log.message data
        log.closeGroup()
        # Call the RPC's `receive` function, if it exists
        if handlers.receive? then handlers.receive $xml, data, status, xhr
    
    # Attach the RPC's `complete` handler (if any)
    options.complete = handlers.complete if handlers.complete?
    
    # Attach the RPC's `error` handler (or use the default)
    options.error    = handlers.error or rpc.error
    
    # Perform the request
    jQuery.ajax options

# ---------

# This utility function converts the arguments given to well-formed XML
@rpc.toXML = (hash) ->
  return "" unless hash?
  
  xml = ""
  type = typeof hash
  
  # If the argument is a string, number or boolean, then coerce it to a string and return it
  if type is "string" or type is "number" or type is "boolean"
    # Escape XML special chars
    hash = String(hash).replace /&(?![a-z0-9]+;)/gi, "&amp;"
    hash = hash.replace /</g, "&lt;"
    hash = hash.replace />/g, "&gt;"
    return hash
  
  # If the argument is an object
  if type is "object"
    # Loop through the object, recursively converting members to XML
    for own key, value of hash
      key = rpc.toXML key
      if value instanceof Array
        xml += "<ns1:#{key}>#{rpc.toXML item}</ns1:#{key}>" for item in value
      else
        xml += "<ns1:#{key}>#{rpc.toXML value}</ns1:#{key}>"
  
  # Return the XML
  xml

# ---------

# The default ajax error handler
@rpc.error = do ->
  errorRegExp = /session (is (invalid|uninitialized)|has not been initialized)/i
  
  (xhr, error, exception) ->
    title = "ERROR: RPC: "
    if xhr.status > 399
      title += xhr.status
    else if exception is "timeout"
      alert "Ups - vi misted forbindelsen. Måske har du ingen forbindelse til Internettet?"
      title += "Timed out"
    else if xhr.responseText.match errorRegExp
      eventSystemNotLoggedIn()  # FIXME: Not a great function name
      title += "Invalid/uninitialized session"
    else
      title += "General error"
    
    log.errorGroup title
    log.error xhr
    log.error "Error:", error
    log.error "Exception:", exception
    log.error "Response: ", xhr.responseText
    log.closeGroup()
  
  
  
