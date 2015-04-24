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
# CHANGED: Removed the `complete` function in favor of the Promise/Deferred pattern
# CHANGED: Removed the `error` function since it'd be rather complex to make it
# work with the deferred object created by LYT.rpc
#
#
# An RPC object can have the following functions:
#
#  - `request`   - returns the data to be sent as the request body
#  - `receive`   - parses the response from the server, if the request is successful, and returns the parsed data
#  - `error`     - (REMOVED) handles errors
#  - `complete`  - (REMOVED) will be called when the request completes, regardless of success or failure
#
# All these members are optional (see below).
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
#         # the receive function throw an exception
#         # (the exception being a simple string)
#         if $xml.find("result").length is 0 then
#           throw "Uh-oh"
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

LYT.protocol =

  # -----

  logOn:
    request: (username, password) ->
      username: username
      password: password
    #$xml, data, status, xhr
    receive: ($xml, data, status, xhr) ->
      throw "logOnFailed" unless $xml.find("logOnResult").text() is "true"
      # Note: Can't use the `"Envelope > Header"` syntax for some reason
      # but `find("Envelope").find("Header")` works...
      # It's probably because Sizzle has a proble with the XML namespacing...and IE and firefox...so use ->$xml.find("s\\:Envelope, Envelope").find("s\\:Header, Header").first()
      #header = $xml.find("Envelope").find("Header").first()(old code)
      header = $xml.find("s\\:Envelope, Envelope").find("s\\:Header, Header").first()

      return {} unless header.length is 1
      data = {}
      header.children().each ->
        key   = @nodeName.slice(0, 1).toLowerCase() + @nodeName.slice(1)
        value = jQuery.trim jQuery(this).text()
        data[key] = value
      data


  logOff:
    receive: ($xml, data) ->
      throw "logOffResult failed" unless $xml.find("logOffResult").text() is "true"
      true


  # TODO: Do we need to pull anything besides the optional operations out of the response?
  getServiceAttributes:
    receive: ($xml, data) ->
      NS = 'http://www.daisy.org/ns/daisy-online/'
      container = $xml[0].getElementsByTagNameNS NS, 'supportedOptionalOperations'
      if container.length
        optionals = container[0].getElementsByTagNameNS NS, 'operation'
        operations = [].slice.call(optionals).map (optional) -> optional.textContent

      [operations]


  setReadingSystemAttributes:
    request: ->
      readingSystemAttributes: LYT.config.protocol.readingSystemAttributes

    receive: ($xml, data) ->
      throw "setReadingSystemAttributes failed" unless $xml.find("setReadingSystemAttributesResult").text() is "true"
      true


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
    # TODO: Can you send an array or list of IDs instead? If you can, it could reduce the number of calls/requests
    # ----: Yes, the markAnnouncementsAsRead method takes a list of announcement id's as input (array of strings)
    request: (ids) ->
      read:
        item: ids

    receive: ($xml, data) ->
      throw "markAnnouncementsAsRead failed" unless $xml.find("markAnnouncementsAsReadResult").text() is "true"
      true


  getContentList:
    request: (listIdentifier, firstItem, lastItem) ->
      id:        listIdentifier
      firstItem: firstItem
      lastItem:  lastItem

    receive: ($xml, data) ->
      NS = 'http://www.daisy.org/ns/daisy-online/'
      items = []
      $xml.find("contentItem").each ->
        item = jQuery this
        # TODO: Is this safe?
        label = (@getElementsByTagNameNS NS, 'text')?[0].textContent
        # TODO: Should really extract the lang attribute too - it'd make it easier to correctly markup the list in the UI
        items.push {
          id: item.attr("id")
          label: label
        }
      [items]


  issueContent:
    request: (bookID) ->
      contentID: bookID

    receive: ($xml) ->
      throw "issueContent failed" unless $xml.find('issueContentResult').text() is "true"
      true


  returnContent:
    request: (bookID) ->
      contentID: bookID

    receive: ($xml) ->
      throw "returnContent failed" unless $xml.find("returnContentResult").text() is "true"
      true


  getContentMetadata:
    request: (bookID) ->
      contentID: bookID

    receive: ($xml, data) ->
      NS = 'http://www.daisy.org/ns/daisy-online/'
      containerEl = $xml[0].getElementsByTagNameNS(NS, 'contentMetadata')[0]
      sampleEl = containerEl.getElementsByTagNameNS NS, 'sample'
      metadata =
        daisy: {}
        misc: {}

      metadata.sample = sampleEl[0].getAttribute('id') if sampleEl.length

      metadataEl = containerEl.getElementsByTagNameNS(NS, 'metadata')[0]
      metas = [].slice.call(metadataEl.children).forEach (meta) ->
        if meta.namespaceURI is NS
          if meta.localName is 'meta'
            metadata.daisy[meta.getAttribute('name').toLowerCase()] = meta.getAttribute('content')
          else
            metadata.daisy[meta.localName.toLowerCase()] = meta.textContent
        else
          metadata.misc[meta.localName.toLowerCase()] = meta.textContent

      metadata


  getContentResources:
    request: (bookID) ->
      contentID: bookID

    receive: ($xml, data) ->
      resources = {}
      $xml.find("resource").each ->
        resources[ jQuery(this).attr("localURI") ] = jQuery(this).attr("uri")
      resources


  # TODO: Handle hilite-nodes? cf. [the specs](http://www.daisy.org/z3986/2005/Z3986-2005.html#li_447)
  getBookmarks:
    request: (bookID) ->
      contentID: bookID

    receive: ($xml) ->
      NS = 'http://www.daisy.org/z3986/2005/bookmark/'
      deserialize = (data) ->
        for child in data.children
          switch child.localName.toLowerCase()
            when 'uri' then uri = child.textContent
            when 'timeoffset' then timeOffset = child.textContent
            when 'note'
              note = child.children[0].textContent

        # Convert from Dodp offset to floating point in seconds
        # TODO: Implement correct parsing of all time formats provided in
        #       http://www.daisy.org/z3986/2005/Z3986-2005.html#Clock
        # Parse offset strings ("HH:MM:SS.ss") to seconds, e. g.
        #     parseOffset("1:02:03.05") #=> 3723.05
        # We keep this function as well as parseTime in LYT.utils because they
        # are used to parse formats that are not completely identical.
        parseOffset = (timeOffset) ->
          if values = timeOffset.match /\d+/g
            if values.length is 4
              values[3] or= "0"
              values[3] = "0.#{values[3]}"
              values = jQuery.map values, parseFloat
              values[0] * 3600 + values[1] * 60 + values[2] + values[3]

        timeOffset = parseOffset timeOffset
        if uri and timeOffset?
          return new LYT.Bookmark
            ncxRef:     null
            URI:        uri
            timeOffset: timeOffset
            note:       text: note || '-'


      set = $xml[0].getElementsByTagNameNS(NS, 'bookmarkSet')[0]
      bookmarkSet =
        bookmarks: []
        book: {}

      for child in set.children
        switch child.localName.toLowerCase()
          when 'uid' then bookmarkSet.book.uid = child.textContent
          when 'lastmark' then bookmarkSet.lastmark = deserialize child
          when 'title'
            text = child.getElementsByTagNameNS(NS, 'text')
            audio = child.getElementsByTagNameNS(NS, 'audio')
            title = {}
            title.text = text[0].textContent if text.length
            title.audio = audio[0].textContent if audio.length
            bookmarkSet.book.title = title
          when 'bookmark'
            bookmark = deserialize child
            if bookmark
              bookmarkSet.bookmarks.push bookmark
            else
              log.errorGroup 'Protocol: getBookmarks: receive: unable to parse bookmark', child

      bookmarkSet

  # FIXME: lastmark may be placed after the bookmarks in bookmarkSet as the specification dictates. This is caused by XML serializer (util.toXML)
  # -----: There is no specific order of element placements. Elements such as lastmark og bookmark can appear either below or above the other., however
  #        Nota's service implementation would probably have the lastmark before bookmark, but it all depends on the serializer, and can change when
  #        new releases of the service is compiled with newer versions of the .NET framework..  Do not depend on element position.
  setBookmarks:

    request: (book) ->

      # Convert from floating point in seconds to Dodp offset
      formatDodpOffset = (timeOffset) ->
        # TODO: The server doesn't support npt format, though it is required
        #timeOffset: "npt=#{hours}:#{minutes}:#{seconds}"
        offset  = timeOffset
        hours   = Math.floor(offset / 3600)
        minutes = Math.floor((offset - hours*3600) / 60)
        seconds = offset - hours * 3600 - minutes * 60
        hours   = '0' + hours.toString()   if hours < 10
        minutes = '0' + minutes.toString() if minutes < 10
        if seconds < 10
          seconds = '0' + seconds.toFixed(2)
        else
          seconds = seconds.toFixed(2)
        "#{hours}:#{minutes}:#{seconds}"

      serialize = (bookmark) ->
        if LYT.config.isMTM
          URI: bookmark.URI
          #ncxRef: bookmark.URI.split('#')[1] #TODO: THIS IS NOT THE RIGHT VALUE
          timeOffset: formatDodpOffset bookmark.timeOffset
          note:       bookmark.note
        else
          URI:        bookmark.URI
          timeOffset: formatDodpOffset bookmark.timeOffset
          note:       bookmark.note

      setnamespace = (ns, obj) ->
        if typeof obj == "object"
          if obj instanceof Array
            return jQuery.map(obj, (value) -> setnamespace(ns, value) )
          else
            newObj = {}
            for key, value of obj
              newObj[ns + ':' + key] = setnamespace(ns, value)
            return newObj
        else
          return obj

      throw "setBookmarks failed - you have to provide a book with an id" unless book? and book.id?
      data = contentID: book.id
      bookmarkSet =
        title: book.title
        uid: book.getMetadata().identifier?.content
        bookmark: (serialize bookmark for bookmark in book.bookmarks)

      if LYT.config.isMTM
        bookmarkSet.title = text: bookmarkSet.title

      if book.lastmark?
        bookmarkSet.lastmark = serialize book.lastmark

      bookmarkSet = setnamespace 'ns2', bookmarkSet
      data['ns2:bookmarkSet'] = bookmarkSet

      data

    receive: ($xml) ->
      throw "setBookmarks failed" unless $xml.find("setBookmarksResult").text() is "true"
      true

  #
  # Request:
  #
  # getQuestions([
  #   { id: 'question1', value: 2 },
  #   { id: 'question3', value: 6 }
  # ])
  #
  # --
  # Response:
  # {
  #   questions: [
  #     { type: 'input', id: 'questionInput3' },
  #     {
  #       type: 'multipleChoice',
  #       id: 'questionMultiple2',
  #       choices: [
  #         { id: 'c2', label: 'Choose this' },
  #         { id: 'c5', label: 'No, this!' }
  #       ]
  #     }
  #   ],
  #
  #   contentListRef: null
  # }
  #
  #
  getQuestions:
    request: (responses) ->
      userResponses:
        userResponse: responses.map((response) ->
          res = questionID: response.id
          res.value = response.value if response.value

          $attributes: res
        )

    receive: ($xml) ->
      NS = 'http://www.daisy.org/ns/daisy-online/'

      # Support multiple choice Questions
      multiples = []
      multipleChoices = $xml[0].getElementsByTagNameNS NS, 'multipleChoiceQuestion'
      multipleChoices = [].slice.call multipleChoices
      multiples = multipleChoices.map (multipleChoice) ->
        label = ''
        choices = []

        for child in multipleChoice.childNodes
          continue if child.namespaceURI isnt NS

          # Find label
          if child.localName is 'label'
            label = child.textContent

          # Find choices
          if child.localName is 'choices'
            for choice in child.childNodes
              if choice.localName is 'choice'
                choices.push(
                  id: choice.getAttribute('id'),
                  label: choice.textContent
                )


        type: 'multipleChoice'
        label: label
        id: multipleChoice.getAttribute 'id'
        choices: choices

      # Support inputQuestions
      inputs = []
      inputQuestions = $xml[0].getElementsByTagNameNS NS, 'inputQuestion'
      inputQuestions = [].slice.call inputQuestions
      inputs = inputQuestions.map (inputQuestion) ->
        label = ''
        types = []

        for child in inputQuestion.childNodes
          continue if child.namespaceURI isnt NS

          # Find label
          if child.localName is 'label'
            label = child.textContent

          # Find choices
          if child.localName is 'inputTypes'
            for input in child.childNodes
              if input.localName is 'input'
                types.push input.getAttribute('type')


        type: 'inputQuestion'
        label: label
        id: inputQuestion.getAttribute 'id'
        types: types

      returnObj =
        questions: multiples.concat inputs

      # Get contentListRef if it's there
      contentListRef = $xml[0].getElementsByTagNameNS NS, 'contentListRef'
      returnObj.contentListRef = contentListRef[0].textContent if contentListRef.length
      returnObj
