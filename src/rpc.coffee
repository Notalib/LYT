# This function performs a remote procedure call from the `protocol` module
# 
# E.g.
# 
#     rpc "logOn", "someUser", "supeSekretPassword" #=> Deferred object
#
# See protocol.coffee for more

# --------

# ## Constants

window.RPC_ERROR = {}

# --------

# Define `rpc` inside a closure
LYT.rpc = do ->
  
  # The template for SOAP request content
  soapTemplate = 
  '''<?xml version="1.0" encoding="UTF-8"?>
  <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://www.daisy.org/ns/daisy-online/">
  <SOAP-ENV:Body>#{body}</SOAP-ENV:Body>
  </SOAP-ENV:Envelope>'''
  
  # The actual `rpc` function
  (action, args...) ->
    # Throw a fit if the argument isn't a string
    unless typeof action is "string"
      throw new TypeError
    
    # Also complain if the `protocol` module doens't contain the RPC
    unless LYT.protocol[action]?
      throw "RPC: Action \"#{action}\" not found"
    
    # Get the RPC object
    handlers = LYT.protocol[action]
    
    # Clone the default options
    options = jQuery.extend {}, LYT.config.rpc.options
    
    # Get the request data from the RPC's `request` function, if present, passing along any arguments
    soap = handlers.request?(args...) or null
    soap = null if typeof soap isnt "object"
    
    # Convert the data obj to XML and insert it into the SOAP template
    xml = {}
    xml[action] = soap
    xml = LYT.rpc.toXML xml
    options.data = soapTemplate.replace /#\{body\}/, xml
    
    # Set the soapaction header
    options.headers = "Soapaction": "/#{action}"
    
    # Create a new Deferred
    deferred = jQuery.Deferred();
    
    # Log the call
    log.group "RPC: Calling \"#{action}\"", soap, options.data
    
    # Set up the success handler
    options.success  = (data, status, xhr) ->
      $xml = jQuery data
      # FIXME: Generalize the fault-handling to handle other faults too. Also, wouldn't it be better to check faultcodes rather than faultstrings?
      if $xml.find("faultcode").length > 0 or $xml.find("faultstring").length > 0
        message = $xml.find("faultstring").text()
        code    = $xml.find("faultcode").text()
        log.errorGroup "PRO: Resource error: #{code}: #{message}"
        log.message data
        log.closeGroup()
        deferred.reject code, message
      else
        log.group "RPC: Response for action \"#{action}\""
        log.message data
        log.closeGroup()
        # Call the RPC's `receive` function, if it exists
        if handlers.receive?
          results = handlers.receive $xml, data, status, xhr
          if results is RPC_ERROR
            deferred.reject -1, "RPC error"
          else
            if not (results instanceof Array) then results = [results]
            deferred.resolve.apply null, results
        else
          deferred.resolve data.status.xhr
    
    # Attach the RPC's `complete` handler (if any)
    options.complete = handlers.complete if handlers.complete?
    
    # Attach the RPC's `error` handler (or use the default)
    options.error    = handlers.error or LYT.rpc.error
    
    # Perform the request
    jQuery.ajax options
    
    return deferred

# ---------

# This utility function converts the arguments given to well-formed XML
LYT.rpc.toXML = (hash) ->
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
      key = LYT.rpc.toXML key
      if value instanceof Array
        xml += "<ns1:#{key}>#{LYT.rpc.toXML item}</ns1:#{key}>" for item in value
      else
        xml += "<ns1:#{key}>#{LYT.rpc.toXML value}</ns1:#{key}>"
  
  # Return the XML
  xml

# ---------

# The default ajax error handler
LYT.rpc.error = do ->
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
  
  
  
