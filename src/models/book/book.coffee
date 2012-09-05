# Requires `/common`  
# Requires `/support/lyt/utils`  
# Requires `/models/service/service`  
# Requires `playlist`  
# Requires `dtb/nccdocument`  

# -------------------

# This class models a book for the purposes of playback.

window.BOOK_ISSUE_CONTENT_ERROR        = {}
window.BOOK_CONTENT_RESOURCES_ERROR    = {}
window.BOOK_NCC_NOT_FOUND_ERROR        = {}
window.BOOK_NCC_NOT_LOADED_ERROR       = {}
window.BOOK_BOOKMARKS_NOT_LOADED_ERROR = {}

class LYT.Book
  
  # Factory-method
  # Note: Instances are cached in memory
  this.load = do ->
    loaded = {}
    
    (id) ->
      deferred = jQuery.Deferred()
      
      loaded[id] or= new LYT.Book id
      
      # Book is loaded; load its playlist
      loaded[id].done (book) ->
        book.playlist or= new LYT.Playlist book
        book.playlist.fail (error) -> deferred.reject error
        book.playlist.done -> deferred.resolve book
        
      # Book failed
      loaded[id].fail (error) ->
        loaded[id] = null
        deferred.reject error
      
      deferred.promise()
  
  
  # "Class"/"static" method for retrieving a
  # book's metadata  
  # Note: Results are cached in memory
  #
  # DEPRECATED: Use `catalog.getDetails()` instead
  this.getDetails = do ->
    loaded = {}
    (id) ->
      log.warn "Book.getDetails is deprecated. Use catalog.getDetails() instead"
      deferred = jQuery.Deferred()
      if loaded[id]?
        deferred.resolve loaded[id]
        return deferred
      
      LYT.service.getMetadata(id)
        .done (metadata) ->
          loaded[id] = metadata
          deferred.resolve metadata
        
        .fail (args...) ->
          deferred.reject args...
      
      deferred.promise()
  
  
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
  constructor: (@id) ->
    # Create a Deferred, and link it to `this`
    deferred = jQuery.Deferred()
    deferred.promise this
    
    @resources   = {}
    @nccDocument = null
    
    pending = 2
    resolve = =>
      --pending or deferred.resolve this
    
    # First step: Request that the book be issued
    issue = =>
      # Perform the RPC
      issued = LYT.service.issue @id
      
      # When the book has been issued, proceed to download
      # its resources list, ...
      issued.then getResources
      
      # ... or fail
      issued.fail -> deferred.reject BOOK_ISSUE_CONTENT_ERROR
    
    # Second step: Get the book's resources list
    getResources = =>
      # Perform the RPC
      got = LYT.service.getResources @id
      
      # If fail, then fail
      got.fail -> deferred.reject BOOK_CONTENT_RESOURCES_ERROR
      
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
          if (/^ncc\.x?html?$/i).test localUri then ncc = @resources[localUri]
        
        # If an NCC reference was found, go to the next step:
        # Getting the NCC document, and the bookmarks in
        # parallel. Otherwise, fail.
        if ncc?
          getNCC ncc
          getBookmarks()
        else
          deferred.reject BOOK_NCC_NOT_FOUND_ERROR
        
      
    # Third step: Get the NCC document
    getNCC = (obj) =>
      # Instantiate an NCC document
      ncc = new LYT.NCCDocument obj.url, @resources
      
      # Propagate a failure
      ncc.fail -> deferred.reject BOOK_NCC_NOT_LOADED_ERROR
      
      # 
      ncc.then (document) =>
        obj.document = @nccDocument = document
        
        metadata = @nccDocument.getMetadata()
        
        # Get the author(s)
        creators = metadata.creator or []
        @author = LYT.utils.toSentence (creator.content for creator in creators)
        
        # Get the title
        @title = metadata.title?.content or ""
        
        # Get the total time
        @totalTime = metadata.totalTime?.content or ""
        
        ncc.book = this
        
        resolve()
    

    getBookmarks = =>
      @lastmark  = null
      @bookmarks = []
      
      # Resolve and return early if bookmarks aren't supported
      # unless LYT.service.bookmarksSupported()
      #   resolve()
      #   return
      
      log.message "Book: Getting bookmarks"
      process = LYT.service.getBookmarks(@id)
      
      # TODO: perhaps bookmarks should be loaded lazily, when required?
      process.fail -> 
      #deferred.reject BOOK_BOOKMARKS_NOT_LOADED_ERROR
        marks =
          lastmark:  null
          bookmarks: []

        {@lastmark, @bookmarks} = marks
        resolve()
      
      process.done (data) =>
        if not data?
          data = 
            lastmark:  null
            bookmarks: []
        {@lastmark, @bookmarks} = data
        resolve()
    
    # Kick the whole process off
    issue @id
  
  # ----------
  
  # Gets the book's metadata (as stated in the NCC document)
  getMetadata: ->
    @nccDocument?.getMetadata() or null

  segmentToBookmark: (segment, offset) ->
    # TODO: The server doesn't support npt format, though it is required
    #timeOffset: "npt=#{hours}:#{minutes}:#{seconds}"
    offset or= segment.start
    hours   = Math.floor(offset / 3600)
    minutes = Math.floor((offset - hours*3600) / 60)
    seconds = offset - hours * 3600 - minutes * 60
    hours   = '0' + hours.toString()   if hours < 10
    minutes = '0' + minutes.toString() if minutes < 10
    if seconds < 10
      seconds = '0' + seconds.toFixed(2)
    else
      seconds = seconds.toFixed(2)
    
    return URI: segment.url(), timeOffset: "#{hours}:#{minutes}:#{seconds}", note: {text: "#{segment.section.title} - #{offset.toFixed(2)}"}

  saveBookmarks: ->
    LYT.service.setBookmarks
      book:
        id:      @id
        title:   @title
      lastmark:  @lastmark
      bookmarks: @bookmarks

  # TODO: Sort bookmarks in reverse chronological order
  # TODO: Add remove bookmark method
  addBookmark: (segment, offset = 0) ->
    @bookmarks or= []
    @bookmarks.push @segmentToBookmark segment, offset
    
    # We need the offsets parsed to seconds here, so first
    # they are all added and at the end, we remove them again.
    # TODO: Write class representing bookmarks(!)
    
    temp = {}
    for bookmark in @bookmarks
      bookmark.offset = LYT.utils.parseOffset bookmark.timeOffset
      temp[bookmark.URI] or= []
      # Find an index for this bookmark: either at the end of the array
      # or at the location of anohter bookmark very close to this one
      i = 0
      while i < temp[bookmark.URI].length
        saved = temp[bookmark.URI][i]
        if bookmark.offset - 2 < saved.offset < bookmark.offset + 2
          break
        i++
      temp[bookmark.URI][i] = bookmark

    delete bookmark.offset for bookmark in @bookmarks
    
    @bookmarks = []
    @bookmarks = @bookmarks.concat segment_marks for uri, segment_marks of temp
    # TODO: Sort using chronographical order
    @bookmarks = @bookmarks.sort (a, b) -> a.note.text > b.note.text

    @saveBookmarks()
    
  setLastmark: (segment, offset = 0) ->
    @lastmark = @segmentToBookmark segment
    @saveBookmarks()
      
