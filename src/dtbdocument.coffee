# This file contains the `LYT.DTBDocument` class, which forms the basis for other classes.
# It is not meant for direct instantiation.

do ->
  # Meta-element name attribute values to look for
  # Name attribute values for nodes that may appear 0-1 times per file  
  # Names that may have variations (e.g. `ncc:format` is the deprecated in favor of `dc:format`) are defined a arrays.
  # C.f. [The DAISY 2.02 specification](http://www.daisy.org/z3986/specifications/daisy_202.html#h3metadef)
  METADATA_NAMES =
    singular:
      coverage:         "dc:coverage"
      date:             "dc:date"
      description:      "dc:description"
      format:          ["dc:format", "ncc:format"]
      identifier:      ["dc:identifier", "ncc:identifier"]
      publisher:        "dc:publisher"
      relation:         "dc:relation"
      rights:           "dc:rights"
      source:           "dc:source"
      subject:          "dc:subject"
      title:            "dc:title"
      type:             "dc:type"
      charset:          "ncc:charset"
      depth:            "ncc:depth"
      files:            "ncc:files"
      footnotes:        "ncc:footnotes"
      generator:        "ncc:generator"
      kByteSize:        "ncc:kByteSize"
      maxPageNormal:    "ncc:maxPageNormal"
      multimediaType:   "ncc:multimediaType"
      pageFront:       ["ncc:pageFront", "ncc:page-front"]
      pageNormal:      ["ncc:pageNormal", "ncc:page-normal"]
      pageSpecial:     ["ncc:pageSpecial", "ncc:page-special"]
      prodNotes:        "ncc:prodNotes"
      producer:         "ncc:producer"
      producedDate:     "ncc:producedDate"
      revision:         "ncc:revision"
      revisionDate:     "ncc:revisionDate"
      setInfo:         ["ncc:setInfo", "ncc:setinfo"]
      sidebars:         "ncc:sidebars"
      sourceDate:       "ncc:sourceDate"
      sourceEdition:    "ncc:sourceEdition"
      sourcePublisher:  "ncc:sourcePublisher"
      sourceRights:     "ncc:sourceRights"
      sourceTitle:      "ncc:sourceTitle"
      timeInThisSmil:  ["ncc:timeInThisSmil", "time-in-this-smil"]
      tocItems:        ["ncc:tocItems", "ncc:tocitems", "ncc:TOCitems"]
      totalElapsedTime:["ncc:totalElapsedTime", "total-elapsed-time"]
      totalTime:       ["ncc:totalTime", "ncc:totaltime"]
    
    # Name attribute values for nodes that may appear multiple times per file
    plural:
      contributor: "dc:contributor"
      creator:     "dc:creator"
      language:    "dc:language"
      narrator:    "ncc:narrator"
  
  # -------
  
  # This class serves as the parent of the `SMILDocument` and `TextContentDocument` classes.  
  # It is not meant for direct instantiation - instantiate the specific subclasses.
  class LYT.DTBDocument
    
    # The constructor takes 1-2 arguments (the 2nd argument is optional):  
    # - url: (string) the URL to retrieve
    # - callback: (function) called when the download is complete (used by subclasses)
    #
    # `LYT.DTBDocument` acts as a Deferred.
    constructor: (@url, callback) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
      @xml = null
      
      # Handlers
      
      resolve = (document) =>
        @xml = jQuery document
        callback? deferred
        deferred.resolve this
      
      reject = (status, error) =>
        deferred.reject status, error
      
      recover = (jqXHR, status) ->
        log.message "DTBDocument: Received invalid XML. Attempting recovery"
        # Get everything in the document element
        content = jqXHR.responseText.match /<html[^>]*>([\s\S]+)<\/html>\s*$/i
        if content? and content[1]
          # If something was found, create an empty HTML
          # document in memory (no DOCTYPE) and put the
          # content in there
          html = jQuery "<html></html>"
          html.html content[1]
          # Do a quick check to see if the HTML was
          # parsed
          if html.find("body").length isnt 0
            log.message "DTBDocument: Recovery succeeded"
            # Sucessfully rescued the content
            # so pretend the load worked fine,
            # and exit the function
            resolve html
            return true
        else
          log.message "DTBDocument: Recovery failed"
        false
      
      ready = (document) =>
        @xml = jQuery document
        callback? deferred
        deferred.resolve this
      
      # On success, wrap the XML with jQuery, call the callback (if any),
      # and propagate the instance
      loaded = (xml, status, jqXHR) =>
        log.group "DTB: Got: #{@url}", xml
        # Check for parser errors
        # TODO: How to improve this?! It seems ripe for cross-browser issues.  
        # I.e. do non-WebKit browsers create that `parsererror` node?
        if jQuery(xml).find("parsererror").length > 0
          recover(jqXHR, status) or reject
        else
          ready xml
        
      
      # On failure, check if it's a parser error.
      # The NCC and text content documents can be very
      # shoddily produced and full of very invalid XML
      # which causes the browser's parser to complain.
      # If that happens, try to rescue the content,
      # by "copying and pasting it" into a tagsoup HTML
      # document. If that also fails, then propagate the
      # failure
      failed = (jqXHR, status, error) =>
        # If the XML failed to parse...
        if status is "parsererror"
          return if recover jqXHR, status
        
        # If all of the above failed, then fail some more
        log.errorGroup "DTB: Failed to get #{@url}", jqXHR, status, error
        reject status, error
      
      # Perform the request
      log.message "DTB: Getting: #{@url}"
      
      # TODO: Move options to `config`?
      jQuery.ajax {
        url:      @url
        dataType: "xml"
        async:    yes
        cache:    yes
        success:  loaded
        error:    failed
        headers:
          # For some strange reason, this avoids a hanging bug in Chrome,
          # even though Chrome refuses to set this particular header...
          connection: "close"
      }
    
    # Parse and return the metadata as an array
    getMetadata: ->
      return {} unless @xml?
      
      # Return cached metadata, if available
      return @_metadata if @_metadata?
      
      # Find the `meta` elements matching the given name-attribute values.
      # Multiple values are given as an array
      findNodes = (values) =>
        values = [values] unless values instanceof Array
        nodes  = []
        selectors = ("meta[name='#{value}']" for value in values).join(", ")
        @xml.find(selectors).each ->
          node = jQuery this
          nodes.push {
            content: node.attr("content")
            scheme:  node.attr("scheme") or null
          }
        
        return null if nodes.length is 0
        return nodes
      
      xml = @xml.find("head").first()
      @_metadata = {}
      
      for own name, values of METADATA_NAMES.singular
        found = findNodes values
        @_metadata[name] = found.shift() if found?
      
      for own name, values of METADATA_NAMES.plural
        found = findNodes values
        @_metadata[name] = found if found?
      
      @_metadata
    
  
