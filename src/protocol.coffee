# This module models the Daisy Online Protocol
# 
# An RPC (Remote Procedure Call) is declared as a nested object in the `protocol`-object
# An RPC object can have the following members:
#
#  - `request`   - a function that returns the SOAP data to be sent as the request body
#  - `receive`   - a function that parses the response from the server, if the request is successful
#  - `complete`  - a function that will be called when the request completes
#  - `error`     - an error-handling function
#
# All these members are optional (see below)
# 
# An RPC is called by passing its name to the rpc function, plus whatever arguments are needed:
# 
#     rpc "getStuffFromServer", foo, bar
# 
# If an RPC named "getStuffFromServer" doens't exist, the rpc function will throw an exception.
# If it does exist, the rpc function will look for the request member. If such a member is found, and is a function
# it will be passed the arguments (`foo` & `bar` in this example), and its return value (if any) will be used to
# generate the SOAP request body.
# If no request function is found, or it returns a non-object value, the request body will simply be an empty
# XML tag, mirroring the name of the RPC
# 
# ## RPC example
# 
# All the members of an RPC object are optional. At it's simplest, an RPC can be defined as
# 
#     someServerAction: true
#
# This will allow you to call `rpc "someServerAction"`. The request will use the default options
# and the body of the request data will be an empty SOAP tag, mirroring the name, i.e. `<ns1:someServerAction />`
# 
# Below is an example using all the optional members
# 
#     # The RPC's name, i.e. the name of the action to call on the server.
#     actionName: 
#       
#       # The request function, with whatever
#       # arguments it requires (if any)
#       request: (args...) -> 
#         # The request function may optionally return
#         # an object. If it does, that object is then
#         # turned into XML and sent as the SOAP body
#         key1: value1
#       
#       # The receive function which will
#       # be passed the data returned by the server
#       receive: ($xml, data, status, xhr) -> ...
#       
#       # The complete callback
#       complete: (xhr, status) -> ...
#       
#       # The error handler
#       error: (xhr, status, error) -> ...

LYT.protocol =
  
  # -----
  
  logOn:
    request: (username, password) ->
      username: username
      password: password
    
    receive: ($xml, data) ->
      if $xml.find("logOnResult").text() is "true"
        rpc "getServiceAttributes"
      else
        eventSystemForceLogin "Du har indtastet et forkert brugernavn eller password" # FIXME: Not a great function name. Also, hard-coded error message
  
  
  logOff:
    # FIXME: Can log off fail? If so, how should it be handled?
    receive: ($xml, data) ->
      eventSystemLogedOff $xml.find("logOffResult")?.text() or "" # FIXME: Not a great function name - and it's spelled wrong
  
  
  getServiceAttributes:
    receive: ($xml, data) ->
      $xml.find("supportedOptionalOperations > operation").each ->
        op = jQuery this
        DODP.service.announcements = (op.text() is "SERVICE_ANNOUNCEMENTS")
      rpc "setReadingSystemAttributes"
  
  
  setReadingSystemAttributes:
    request: ->
      readingSystemAttributes:
        manufacturer: "NOTA"
        model: "LYT"
        serialNumber: "1"
        version: "1"
        config: null
    
    receive: ($xml, data) ->
       if $xml.find("setReadingSystemAttributesResult").text() is "true"
         eventSystemLogedOn true, $xml.find("MemberId").text()  # FIXME: Not a great function name - and it's spelled wrong
       
         # TODO: There's something weird going on here (read on)
         # If DODP.service.announcements is true (and announcements should be shown), then getServiceAnnouncements() is called
         # But getServiceAnnouncements' callback is responsible for setting DODP.service.announcements to true/false
         # So as far as I can tell, it's circular
         if DODP.service.announcements and false then rpc "getServiceAnnouncements" # FIXME: replace false with SHOW_SERVICE_ANNOUNCEMENTS
       else
         alert aLang.translate "MESSAGE_LOGON_FAILED" # FIXME: What the...? There's localization? Since when?
  
  
  getServiceAnnouncements:
    receive: ($xml, data) ->
      $xml.find("announcements > announcement").each ->
        announcement = jQuery this
        alert announcement.find("text").text()
        rpc "markAnnouncementsAsRead", announcement.id
  
  
  markAnnouncementsAsRead:
    # TODO: Can you send an array or list of IDs instead? If you can, it would reduce the number of calls/requests
    request: (id) ->
      read:
        item: id
    
  
  getContentList:
    request: (listID, firstItem, lastItem) ->
      id:        listID
      firstItem: firstItem
      lastItem:  lastItem
    
    receive: ($xml, data) ->
      eventSystemGotBookShelf data
    
  
  issueContent:
    request: (bookID) ->
      contentID: bookID
    
    receive: ($xml) ->
      if $xml.find('issueContentResult').text() is "true"
        rpc "getContentResources", settings.get('currentBook')
      else
        log.error "PRO: Error in issueContent parsing: #{$xml.find("faultcode").text()} - #{$xml.find('faultstring').text()}"
        alert "#{$xml.find("faultcode").text()} - #{$xml.find('faultstring').text()}"
      
    
  returnContent:
    request: (bookID) ->
      contentId: bookID
    
    receive: ($xml) ->
      if $xml.find("returnContentResult").text() is "true"
        rpc "getBookShelf"
      else
        log.error "PRO: Error in returnContent parsing: #{$xml.find("faultcode").text()} - #{$xml.find('faultstring').text()}"
        alert "#{$xml.find("faultcode").text()} - #{$xml.find('faultstring').text()}"
      
  
  getContentMetadata:
    request: (bookID) ->
      contentID: bookID
  
  
  
  getContentResources:
    request: (bookID) ->
      contentID: bookID
    
    # FIXME: Not fully implemented
    receive: ($xml, data) ->
      fault = $xml.find('faultstring').text()
      if fault isnt ""
        if fault is "s:invalidParameterFault"
          eventSystemEndLoading()
        log.error "PRO: Resource error: #{fault}"
        return
          
        
      $xml.find("resource").each ->
        resource = jQuery this
        resourceURI = resource.attr "uri"
        components = resourceURI.match /^([^\/]+)\/\/([^\/]+)\/(.*)$/
        
        url = "#{components[1]}//#{window.location.hostame}/#{components[3]}"
        if resourceURI.match /ncc.htm$/i then nccPath = url
        
      # FIXME: Not fully implemented
  
  
  setBookmarks:
    # FIXME: Not fully implemented
    request: (bookID, bookmarkData) ->
      contentID: bookID
      bookmarkSet:
        title:
          text: bookID
          audio: ""
        uid: bookID
        lastmark:
          ncxref:     "xyub00066"
          URI:        "cddw000A.smil#xyub00066"
          timeOffset: "00:10.0"
        
      
    
  


  