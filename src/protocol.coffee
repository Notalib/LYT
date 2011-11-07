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
      $xml.find("logOnResult").text() is "true" or RPC_ERROR
  
  
  logOff:
    receive: ($xml, data) ->
      $xml.find("logOffResult").text() is "true" or RPC_ERROR
  
  
  getServiceAttributes:
    receive: ($xml, data) ->
      operations = []
      $xml.find("supportedOptionalOperations > operation").each ->
        operations.push $(this).text()
      [operations]
  
  
  setReadingSystemAttributes:
    request: ->
      readingSystemAttributes:
        manufacturer: "NOTA"
        model: "LYT"
        serialNumber: "1"
        version: "1"
        config: null
    
    receive: ($xml, data) ->
      $xml.find("setReadingSystemAttributesResult").text() is "true" or RPC_ERROR
  
  
  getServiceAnnouncements:
    receive: ($xml, data) ->
      announcements = []
      $xml.find("announcements > announcement").each ->
        announcement = jQuery this
        announcements.push {
          text: announcement.find("text").text()
          id:   announcement.attr("id")
        }
      [announcements]
  
  
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
      items = []
      $xml.find("contentItem").each ->
        item = jQuery this
        # TODO: Should really extract the lang attribute too - it'd make it easier to correctly markup the list in the UI
        items.push {
          id: item.attr("id")
          label: item.find("label > text").text()
        }
      [items]
    
  
  issueContent:
    request: (bookID) ->
      contentID: bookID
    
    receive: ($xml) ->
      $xml.find('issueContentResult').text() is "true" or RPC_ERROR
      
    
  returnContent:
    request: (bookID) ->
      contentID: bookID
    
    receive: ($xml) ->
      $xml.find("returnContentResult").text() is "true" or RPC_ERROR
      
  
  getContentMetadata:
    request: (bookID) ->
      contentID: bookID
  
  
  
  getContentResources:
    request: (bookID) ->
      contentID: bookID
    
    # FIXME: Not fully implemented
    receive: ($xml, data) ->
      isMP3  = /\.mp3$/i
      isSMIL = /\.smil$/i
      isNCC  = /ncc.html?$/i
      
      resources =
        smil: []
        mp3:  []
      
      # TODO: Assumes only 1 NCC file...
      $xml.find("resource").each ->
        resource = jQuery this
        uri = resource.attr("uri")
        if isMP3.test uri then       resources.mp3.push uri
        else if isSMIL.test uri then resources.smil.push uri
        else if isNCC.test uri then  resources.ncc = uri
      
      return resources
  
  
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
        
      
    
  


  