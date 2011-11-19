# This class models a book for the purposes of playback.

class LYT.Book
  
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
          if localUri.match /^ncc\.html?$/i then ncc = @resources[localUri]
        
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
        deferred.resolve this
      
    # Kick the whole process off
    issue @id
  
  # ----------
  
  # Loads a section by its ID
  preloadSection: (section = null) ->
    deferred = jQuery.Deferred()
    
    # Find the section in the NCC
    section = @nccDocument.findSection section
    
    # Fail if the section's not found
    unless section?
      deferred.reject(null)
      return
    
    sections = section.flatten()
    # Go through each section, and find the SMIL files to load
    for section in sections
      unless section.document
        file = section.url.replace /#.*$/, ""
        url  = @resources[file]?.url
        unless url?
          deferred.reject(null) 
          return
        
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
  # - id:      The id of the <par> element in the SMIL document
  # - section: The id of the section the media belongs to
  # - start:   The start time, in seconds, relative to the audio
  # - end:     The end time, in seconds, relative to the audio
  # - audio:   The url of the audio file (or null)
  # - text:    The text to display (or null)
  mediaFor: (section = null, offset = null) ->
    deferred = jQuery.Deferred()
    
    # Preload the sections or propagate the failure
    preload = @preloadSection section
    preload.fail -> deferred.resolve null
    
    # Once the sections have loaded, find the data for the
    # time offset
    preload.done (sections) =>
      offset = offset or 0
      for section in sections
        par = null
        if offset < section.document.duration
          par = section.document.getParByTime offset
        if par
          media =
            section: section.id
            start:   par.start
            end:     par.end
          # Get the audio URL, if any
          media.audio = @resources[par.audio.src]?.url or null if par.audio?.src?
          #alert par.text.src
          [txtfile, txtid] = if par.text?.src? then par.text.src.split("#") else [null, null]
          
          # Get the text, if any
          if txtfile? and @resources[txtfile]
            # Load the text document, if necessary
            unless @resources[txtfile].document
              @resources[txtfile].document = new LYT.TextContentDocument @resources[txtfile].url
            # Get the text content
            @resources[txtfile].document.done =>
              media.text = @resources[txtfile].document.getTextById txtid
              deferred.resolve media
            
            @resources[txtfile].document.fail =>
              media.text = null
              deferred.resolve media
          else
            media.text = null
            deferred.resolve media
          
          # Exit the method, since a matching `<par>` element has been found
          return deferred
        
        offset -= section.document.duration
      
      # Didn't find anything in the loop above, so propagate `null`
      deferred.resolve null
    
    # Return the deferred object
    deferred
  

