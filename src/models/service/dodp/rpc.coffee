# Requires `/common`
# Requires `/support/lyt/utils`
# Requires `protocol`

# -------------------

# This function performs a remote procedure call from the `protocol` module
#
# E.g.
#
#     rpc "logOn", "someUser", "supeSekretPassword" #=> Deferred object
#
# See protocol.coffee for more

# --------

# ## Constants

# TODO: Move the constants below out of global namespace

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
    <SOAP-ENV:Envelope
     xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
     xmlns:ns1="http://www.daisy.org/ns/daisy-online/"
     xmlns:ns2="http://www.daisy.org/z3986/2005/bookmark/"
    >
    <SOAP-ENV:Body>#{body}</SOAP-ENV:Body>
    </SOAP-ENV:Envelope>'''


  # AJAX options
  ajaxOptions =
    async:       yes
    cache:       no
    contentType: "text/xml; charset=utf-8"
    dataType:    "xml"
    processData: yes
    timeout:     10000
    type:        "POST"
    url:         LYT.config.rpc.url


  identifyDODPError = do ->
    # Faults (cf. [Daisy specification](http://www.daisy.org/projects/daisy-online-delivery/drafts/20100402/do-spec-20100402.html#apiReferenceFaults))
    # They're defined here, and added dynamically since they're needed in obj-form later
    faultCodes =
      DODP_INTERNAL_ERROR:       ///\b internalServerError ///i
      DODP_NO_SESSION_ERROR:     /// noActiveSession ///i
      DODP_UNSUPPORTED_OP_ERROR: ///\b operationNotSupported ///i
      DODP_INVALID_OP_ERROR:     ///\b invalidOperation ///i
      DODP_INVALID_PARAM_ERROR:  ///\b invalidParameter ///i

    # Add the faux-constants to `window`
    window[fault] = {} for fault of faultCodes

    # A catch-all error, in case none of the other errors
    # match (which they should, according to the spec, but
    # that's no guarantee)
    window.DODP_UNKNOWN_ERROR = {}

    # Return the function
    (code, string) ->
      for fault, signature of faultCodes
        return window[fault] if signature.test(code) or signature.test(string)
      window.DODP_UNKNOWN_ERROR


  isTherefault = (xml, deferred) ->
    faultstring = jQuery.trim xml.find("faultstring").text()
    faultcode   = jQuery.trim xml.find("faultcode").text()
    fault       = jQuery.trim xml.find("Fault").text()

    if faultcode or faultstring or fault
      dodpFault = identifyDODPError faultcode, faultstring
      log.errorGroup "RPC: Resource error: #{faultcode}: #{faultstring}"
      deferred.reject dodpFault, faultstring
      return true
    else
      return false

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
    options = jQuery.extend {}, ajaxOptions

    # Get the request data from the RPC's `request` function, if present,
    # passing along any arguments
    soap = handlers.request?(args...) or null
    soap = null if typeof soap isnt "object"

    # Convert the data obj to XML and insert it into the SOAP template.
    # This has to be on separate lines, since JavaScript won't accept
    # string-interpolated key-names such as `{ "#{action}": soap }`
    xml = {}
    xml[action] = soap
    xml = LYT.utils.toXML xml
    options.data = soapTemplate.replace /#\{body\}/, xml

    # Set the soapaction header
    options.headers or= {}
    options.headers["Soapaction"] = "/#{action}"

    # Create a new Deferred
    deferred = jQuery.Deferred()

    # Log the call
    log.group "RPC: Calling \"#{action}\"", soap, options.data

    # Set up the success/error handlers
    options.success = (data, status, xhr) ->
      if not data or not (xml = jQuery data)
        return deferred.reject DODP_UNKNOWN_ERROR, "Unknown error"

      return if isTherefault xml, deferred

      log.group "RPC: Response for action \"#{action}\"", data

      return deferred.resolve data, status, xhr unless handlers.receive?

      # Call the RPC's `receive` function, if it exists
      try
        results = handlers.receive xml, data, status, xhr
      catch error
        log.errorGroup "RPC: #{error}", data
        deferred.reject RPC_UNEXPECTED_RESPONSE_ERROR, "#{error}"

      if not (results instanceof Array) then results = [results]
      deferred.resolve results...


    # FIXME: Structure this better, so the errorHandler doesn't need to
    # be passed the success-handler
    options.error =  (jqXHR, status, error) ->
      # A status 500 by default invokes this error handler,
      # but if there's responseXML the response should
      # instead be handled by the success handler, since
      # it will parse the response (which contains fault
      # codes etc), and handle it appropriately.
      
      # This fixes a jQuery bug, where sometimes the response XML won't be
      # parsed into .responseXML!
      responseXML = jqXHR.responseXML || (jqXHR.responseText? && $(jqXHR.responseText))

      if jqXHR.status is 500 and responseXML
        if isTherefault responseXML, deferred
          return

      errCode = switch status
        when "timeout"     then RPC_TIMEOUT_ERROR
        when "abort"       then RPC_ABORT_ERROR
        when "parsererror" then RPC_PARSER_ERROR
        when "error", null then RPC_GENERAL_ERROR
        else                    RPC_HTTP_ERROR

      deferred.reject errCode, error

    # Perform the request
    jQuery.ajax options
    # Return the deferred's promise
    deferred.promise()
