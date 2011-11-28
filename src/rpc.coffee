# This function performs a remote procedure call from the `protocol` module
# 
# E.g.
# 
#     rpc "logOn", "someUser", "supeSekretPassword" #=> Deferred object
#
# See protocol.coffee for more

# --------

# TODO: Better error handling/propagation

# ## Constants

window.RPC_UNEXPECTED_RESPONSE_ERROR = {}
window.RPC_GENERAL_ERROR             = {}
window.RPC_TIMEOUT_ERROR             = {}
window.RPC_ABORT_ERROR               = {}
window.RPC_PARSER_ERROR              = {}
window.RPC_HTTP_ERROR                = {}

# --------

# Define `rpc` inside a closure
LYT.rpc = do ->
  
  # The template for SOAP request content
  soapTemplate = 
    '''<?xml version="1.0" encoding="UTF-8"?>
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://www.daisy.org/ns/daisy-online/">
    <SOAP-ENV:Body>#{body}</SOAP-ENV:Body>
    </SOAP-ENV:Envelope>'''
  
  
  identifyDODPError = do ->
    # Faults (cf. [Daisy specification](http://www.daisy.org/projects/daisy-online-delivery/drafts/20100402/do-spec-20100402.html#apiReferenceFaults))  
    # They're defined here, and added dynamically since they're needed in obj-form later
    faultCodes =
      DODP_INTERNAL_ERROR:       ///\b internalServerError ///i
      DODP_NO_SESSION_ERROR:     ///\b noActiveSession ///i
      DODP_UNSUPPORTED_OP_ERROR: ///\b operationNotSupported ///i
      DODP_INVALID_OP_ERROR:     ///\b invalidOperation ///i
      DODP_INVALID_PARAM_ERROR:  ///\b invalidParameter ///i
      # A catch-all error, in case none of the other errors
      # match (which they should, according to the spec, but
      # that's no guarantee)
      DODP_UNKNOWN_ERROR:        "unknownerror" 

    # Add the faux-constants to `window`
    window[fault] = {} for fault of faultCodes
    
    # Return the function
    (code, string) ->
      for fault, signature of faultCodes
        return window[fault] if signature.test code
      window.DODP_UNKNOWN_ERROR
  
  
  # Error-handler-factory-function-and-I-like-hyphens
  createErrorHandler = (deferred) ->
    (jqXHR, status, error) ->
      switch status
        when "timeout"
          deferred.reject RPC_TIMEOUT_ERROR, error
          return
        when "error", null
          deferred.reject RPC_GENERAL_ERROR, error
          return
        when "abort"
          deferred.reject RPC_ABORT_ERROR, error
          return
        when "parsererror"
          deferred.reject RPC_PARSER_ERROR, error
          return
      deferred.reject RPC_HTTP_ERROR, error
  
  
  createResponseHandler = (action, deferred) ->
    handlers = LYT.protocol[action]
    
    (data, status, xhr) ->
      $xml = jQuery data
      
      # TODO: This is kinda brittle. Unless the server totally respects the
      # DODP/SOAP specifications, there're all kinds of ways this code will
      # fail to find a fault in the response...
      faultstring = jQuery.trim $xml.find("faultstring").text()
      faultcode   = jQuery.trim $xml.find("faultcode").text()
      
      if faultcode or faultstring or $xml.find("Fault").length > 0
        fault = identifyDODPError faultcode, faultstring
        log.errorGroup "RPC: Resource error: #{faultcode}: #{faultstring}", data
        deferred.reject fault, faultstring
        return
      
      log.group "RPC: Response for action \"#{action}\"", data
      
      unless handlers.receive?
        deferred.resolve data, status, xhr
        return
      
      # Call the RPC's `receive` function, if it exists
      try
        results = handlers.receive $xml, data, status, xhr
      catch error
        log.errorGroup "RPC: #{error}", data
        deferred.reject RPC_UNEXPECTED_RESPONSE_ERROR, "#{error}"
      
      if not (results instanceof Array) then results = [results]
      deferred.resolve.apply null, results
  
  
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
    
    # Clone the default options (since we'll be modifying the options)
    options = jQuery.extend {}, LYT.config.rpc.options
    
    # Get the request data from the RPC's `request` function, if present,
    # passing along any arguments
    soap = handlers.request?(args...) or null
    soap = null if typeof soap isnt "object"
    
    # Convert the data obj to XML and insert it into the SOAP template.  
    # This has to be on separate lines, since JavaScript won't accept
    # string-interpolated key-names such as `{ "#{action}": soap }`
    xml = {}
    xml[action] = soap
    xml = toXML xml
    options.data = soapTemplate.replace /#\{body\}/, xml
    
    # Set the soapaction header
    options.headers or= {}
    options.headers["Soapaction"] = "/#{action}"
    
    # Create a new Deferred
    deferred = jQuery.Deferred();
    
    # Log the call
    log.group "RPC: Calling \"#{action}\"", soap, options.data
    
    # Set up the success/error handlers
    options.success = createResponseHandler action, deferred
    options.error   = createErrorHandler deferred
    
    # Perform the request
    jQuery.ajax options
    
    # Return the deferred
    deferred

# ---------

# Deprecated
LYT.rpc.toXML = (hash) ->
  log.warn "LYT.rpc.toXML is deprecated. Use [window.]toXML instead"
  toXML hash

# ---------

# The default ajax error handler
LYT.rpc.error = do ->
  errorRegExp = /session (is (invalid|uninitialized)|has not been initialized)/i
  
  (xhr, error, exception) ->
    title = "ERROR: RPC: "
    if xhr.status > 399
      title += xhr.status
    else if exception is "timeout"
      # FIXME: No `alert()`s here! 
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
  
  
  
