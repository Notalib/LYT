# This class models a book for the purposes of playback.

class LYT.Book
  
  # Factory-method
  this.load = do ->
    loaded = {}
    (id) -> loaded[id] or (loaded[id] = new LYT.Book id)
      
  
  # The constructor takes one argument; the ID of the book.  
  # The instantiated object acts as a Deferred object, as the instantiation of a book
  # requires several RPCs and file downloads, all of which are performed asynchronously.
  #
  # Here's an example of how to load a book for playback:
  # 
  #     # Instantiate the book
  #     book = new LYT.Book 123
  #     
  #     # Set up a callback for when the book's done loading
  #     # The callback receives the book object as its argument
  #     book.done (book) ->
  #       # Do something with the book
  #     
  #     # Set up a callback to handle any failure to load the book
  #     book.fail () ->
  #       # Do something about the failure
  # 
  # FIXME: reject with error code/message  
  constructor: (@id) ->
    # Create a Deferred, and link it to `this`
    deferred = jQuery.Deferred()
    deferred.promise this
    
    @resources   = {}
    @nccDocument = null
    
    # First step: Request that the book be issued
    issue = =>
      # Perform the RPC
      issued = LYT.service.issue @id
      
      # When the book has been issued, proceed to download
      # its resources list, ...
      issued.then getResources
      
      # ... or fail
      issued.fail -> deferred.reject()
    
    # Second step: Get the book's resources list
    getResources = =>
      # Perform the RPC
      got = LYT.service.getResources @id
      
      # If fail, then fail
      got.fail -> deferred.reject()
      
      got.then (@resources) =>
        ncc = null
        
        # Process the resources hash
        for own localUri, uri of @resources
          # Each resource is identified by its relative path,
          # and contains the properties `url` and `document`
          # (the latter initialized to `null`)
          @resources[localUri] =
            url:      uri
            document: null
          
          # If the url of the resource is the NCC document,
          # save the resource for later
          if localUri.match /^ncc\.x?html?$/i then ncc = @resources[localUri]
        
        # If an NCC reference was found, go to the next step:
        # Getting the NCC document. Otherwise, fail.
        if ncc?
          getNCC ncc
        else
          deferred.reject()
        
      
    # Third step: Get the NCC document
    getNCC = (obj) =>
      # Instantiate an NCC document
      ncc = new LYT.NCCDocument obj.url
      
      # Propagate a failure
      ncc.fail -> deferred.reject()
      
      # 
      ncc.then (document) =>
        obj.document = @nccDocument = document
        
        metadata = @nccDocument.getMetadata()
        
        # Get the author(s)
        creators = metadata.creator or []
        @author = toSentence (creator.content for creator in creators)
        
        # Get the title
        @title = metadata.title?.content or ""
        
        # Get the total time
        @totalTime = metadata.totalTime?.content or ""
        
        deferred.resolve this
      
    # Kick the whole process off
    issue @id
  
  # ----------
  
  # Gets the book's metadata (as stated in the NCC document)
  getMetadata: ->
    @nccDocument?.getMetadata() or null
  
  # Loads a section by its ID
  preloadSection: (section = null) ->
    deferred = jQuery.Deferred()
    
    # Find the section in the NCC
    section = @nccDocument.findSection section
    
    # Fail if the section's not found
    unless section?
      deferred.reject(null)
      return deferred
    
    sections = section.flatten()
    # Go through each section, and find the SMIL files to load
    for section in sections
      unless section.document
        file = section.url.replace /#.*$/, ""
        url  = @resources[file]?.url
        unless url?
          deferred.reject(null) 
          return deferred
        
        # Load the SMIL file, if it hasn't happened already
        unless @resources[file].document?
          @resources[file].document = new LYT.SMILDocument url
          section.document = @resources[file].document
      
    # Get all the SMIL documents
    documents = (section.document for section in sections)
    
    # Setup a listener for when the documents all load
    # (or if any one document fails)
    jQuery.when.apply(null, documents)
      .then -> deferred.resolve(sections)
      .fail -> deferred.reject(null)
    
    # Return the deferred object
    deferred
  
  # ----------
  
  # Retrieves the media (text and audio) for a given section
  # at a given point in time (seconds, relative to that section).  
  # Both arguments are optional. If no arguments are given, 
  # the first section's first text & audio will be loaded.  
  # If no matching media is found, `null` will be propagated.  
  # Again, this is asynchronous, and the method returns a
  # Deferred object. Here's an example
  # 
  #     # Get media 12 seconds into a section
  #     book.mediaFor("section-01", 12).done (media) ->
  #       # Check for null
  #       if media?
  #         # do something with the media
  # 
  # The media object that's propagated has the following
  # members:
  #
  # - id:              The id of the <par> element in the SMIL document
  # - section:         The id of the section the media belongs to
  # - start:           The start time, in seconds, relative to the audio
  # - end:             The end time, in seconds, relative to the audio
  # - audio:           The url of the audio file (or null)
  # - html:            The HTML to display (or null)
  # - text:            The text content of the HTML content (or null)
  # - absoluteOffset:  The _approximate_ absolute start time of the section
  # - previousSection: The ID of the previous section (or null)
  # - nextSection:     The ID of the next section (or null)
  mediaFor: (section = null, offset = null) ->
    # Find the requested section
    findSection = (sections) =>
      offset = offset or 0
      clip = null
      for section in sections
        # Check that the requested offset is in the section. If not,
        # "shift" the offset, and try the next section
        if offset > section.document.duration
          offset -= section.document.duration
          continue
        
        # Get the clip for offset
        clip = section.document.getClipByTime offset
        
        if clip?
          # If a clip was found, get the media for that clip
          # Note that getMedia assumes responsibility for
          # resolving/rejecting `deferred`
          getMedia section, clip
          # Return here, since something was found. Subsequent
          # function will take responsibility for resolving/
          # rejecting the deferred
          return
      
      # If no section was found, or no clip was found in the sections
      # resolve with `null`  
      # TODO: Reject with error?
      deferred.resolve null
    
    # Finds the media (audio URL, HTML) for a clip
    getMedia = (section, clip) ->
      media =
        id:      clip.id
        section: section.id # TODO: Move to Section
        previousSection: section.previousSection?.id or null # TODO: Move to Section
        nextSection:     section.nextSection?.id or null     # TODO: Move to Section
        start:   clip.start
        end:     clip.end
        absoluteOffset: section.document.absoluteOffset # TODO: Deprecate?
        audio:   resolveRelativeUrl clip.audio.src
        text:    null
        html:    null
      
      # Find the content
      content = getContent(clip.text.src)
      
      # If there isn't any, resolve and return
      unless clip.text?.src?
        deferred.resolve media
        return
      
      # Otherwise, get the content
      content.done (content) ->
        jQuery.extend media, (content or {})
        deferred.resolve media
    
    # Gets the content based on the relative src URL
    getContent = (src) ->
      # Create a deferred
      process = jQuery.Deferred()
      
      # Check the input
      unless src?
        process.resolve null
        return
      
      # Split the URL into the resource's filename and element ID
      [resource, id] = src.split "#"
      
      # Get the resource
      resource = getResource resource
      
      # Return null if there's no resource for that resouce-file
      unless resource? and resource.url? and id?
        process.resolve null
        return
      
      # Load the text content document if necessary
      resource.document = new LYT.TextContentDocument resource.url unless resource.document?
      
      # If the load fails, resolve `null`
      resource.document.fail ->
        process.resolve null
      
      # Otherwise, find and prepare the element
      resource.document.done ->
        element = resource.document.getElementById id
        process.resolve prepareElement(element)
      
      # Return the deferred
      process
      
    
    # Parses a content HTML element (jQuery-wrapped)
    prepareElement = (element) ->
      
      # Check the input
      return null if not element? or element.length is 0
      
      # Remove links.  
      # This will fall apart on nested links, I think.
      # Then again, nested links are very illegal anyway
      element.find("a").each ->
        item = jQuery this
        item.replaceWith item.html()
      
      # Fix relative links in `src` attrs
      element.find("*[src]").each ->
        item = jQuery this
        item.attr "src", "#{resolveRelativeUrl item.attr("src")}"
      
      # Return what was found
      text: jQuery.trim element.text() # TODO: Deprecate
      html: element.html()
    
    # Get a resource by its local URL
    getResource = (resource) =>
      return null unless resource?
      @resources[resource]
    
    # Get the absolute URL for a relative URL
    resolveRelativeUrl = (relative) ->
      getResource(relative)?.url or null
    
    # Create a deferred object
    deferred = jQuery.Deferred()
    
    # Preload the sections
    preload = @preloadSection section
    
    # If the preload fails, resolve with `null`
    preload.fail -> deferred.resolve null
    
    # Otherwise find the requested section
    preload.done findSection
    
    # Return the deferred
    deferred
  

