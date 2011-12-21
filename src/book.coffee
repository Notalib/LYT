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
    (id) -> loaded[id] or (loaded[id] = new LYT.Book id)
  
  
  # "Class"/"static" method for retrieving a
  # book's metadata  
  # Note: Results are cached in memory
  this.getDetails = do ->
    loaded = {}
    (id) ->
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
      
      deferred
  
  
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
        @author = toSentence (creator.content for creator in creators)
        
        # Get the title
        @title = metadata.title?.content or ""
        
        # Get the total time
        @totalTime = metadata.totalTime?.content or ""
        
        resolve()
    
    
    getBookmarks = =>
      @lastMark  = null
      @bookmarks = []
      
      # Resolve and return early if bookmarks aren't supported
      unless LYT.service.bookmarksSupported()
        resolve()
        return
      
      process = LYT.service.getBookmarks(@id)
      
      # TODO: Currently, failing to get the bookmarks will "fail" the
      # the entire book loading-process... perhaps the system should
      # be more lenient, and allow bookmarks to fail? Or perhaps they
      # should be loaded lazily, when required?
      process.fail -> deferred.reject BOOK_BOOKMARKS_NOT_LOADED_ERROR
      
      process.done (set) ->
        @lastMark = set.lastmark
        @bookmarks = set.bookmarks
        resolve()
    
    # Kick the whole process off
    issue @id
  
  # ----------
  
  # Gets the book's metadata (as stated in the NCC document)
  getMetadata: ->
    @nccDocument?.getMetadata() or null
  
  getPlaylist: (initialSection = null) ->
    if @_playlist?
      @_playlist.setCurrentSection initialSection
      return @_playlist 
    @_playlist = new LYT.Playlist @nccDocument.sections, @resources, initialSection
  
