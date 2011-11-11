# Defines functions for sending and receiving SOAP data.
#
# The functions are defined in objects nested in the `protocol` object. Each nested
# object - an RPC object - is named after the action it calls on the server. The
# idea is to have 1-to-1 mapping of server actions and RPC objects.
#
# **Note:** The RPC object functions are intended to act as an XML-to-JS layer.
# I.e. taking JS objects and primitives and preparing them for requests, and
# taking the returned XML and parsing it into JS data. The functions should not
# call initiate further calls to the server, and generally be as isolated from
# the rest of the system as possible.
#
# CHANGED: Deprecated the `complete` function in favor of the Promise/Deferred pattern
# 
# An RPC object can have the following functions:
#
#  - `request`   - returns the data to be sent as the request body
#  - `receive`   - parses the response from the server, if the request is successful, and returns the parsed data
#  - `error`     - handles errors
#  - `complete`  - (DEPRECATED) will be called when the request completes, regardless of success or failure
#
# All these members are optional (see below). The `error` and `complete` callbacks.
# 
# An RPC is called by passing its name to the [`rpc` function](rpc.html),
# passing along whatever arguments are needed:
# 
#     rpc "getStuffFromServer", foo, bar
# 
# If an RPC object named "getStuffFromServer" doens't exist, the rpc function
# will throw an exception.
#
# If such an object does exist, the `rpc` function will look for the `request`
# function in that object. If such a function is found, it will be passed the
# arguments (`foo` & `bar` in this example), and its return value (if any)
# will be used to generate the SOAP request body.
# 
# If no `request` function is found, or if it returns a non-object value, the
# request body will simply be an empty XML tag (see below)
# 
# ## RPC example
# 
# All the members of an RPC object are optional. At it's simplest, an RPC can
# be defined as:
# 
#     someServerAction: true
#
# This will allow you to call `rpc "someServerAction"`. The request will use
# the default options and the body of the request data will be an empty SOAP
# tag, mirroring the name, i.e. `<ns1:someServerAction />`
# 
# Below is an example using all the optional members
# 
#     # The RPC's name, i.e. the name of the action to call on the server.
#     # Note: Put the name in quotes
#     "findUser": 
#       
#       # The request function, with whatever
#       # arguments it requires (if any)
#       request: (name) -> 
#         # The request function may optionally return
#         # an object. If it does, that object is then
#         # turned into XML and sent as the SOAP body
#         first: name.split(" ")[0]
#         last:  name.split(" ")[1]
#       
#       # The receive function which will
#       # be passed the data returned by the server
#       receive: ($xml, data, status, xhr) ->
#         # $xml is a jQuery-wrapped XML document,
#         # whereas data is the "raw" XML document.
#         # The receive function is responsible for
#         # the initial parsing and checking of the
#         # XML data returned by the server.
#         # If there's a problem with the data,
#         # the receive function can return
#         # RPC_ERROR
#         if $xml.find("result").length is 0 then
#           return RPC_ERROR
#
#         # In this example, that means extracting
#         # the user IDs returned by the server
#         ids = []
#         $xml.find("result > userid").each ->
#           ids.push jQuery(this).text()
#         
#         # Returning an array, will cause downstream
#         # functions to receive the array's contents
#         # as multiple arguments. So wrap the ids
#         # in another array
#         return [ids]
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
    
    receive: ($xml, data) ->
      resources = {}
      $xml.find("resource").each ->
        resources[ jQuery(this).attr("localURI") ] = jQuery(this).attr("uri")
      
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
        
      
    
  


  