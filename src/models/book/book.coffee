# Requires `/common`
# Requires `/support/lyt/utils`
# Requires `/models/service/service`
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
      loaded[id] or= new LYT.Book id
      loaded[id].promise()


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

      got.then (resources) =>
        ncc = null

        # Process the resources hash
        for own localUri, uri of resources

          # We lowercase all resource lookups to avoid general case-issues
          localUri = localUri.toLowerCase()

          # Each resource is identified by its relative path,
          # and contains the properties `url` and `document`
          # (the latter initialized to `null`)
          # Urls are rewritten to use the origin server just
          # in case we are behind a proxy.
          origin = document.location.href.match(/(https?:\/\/[^\/]+)/)[1]
          path = uri.match(/https?:\/\/[^\/]+(.+)/)[1]
          @resources[localUri] =
            url:      origin + path
            document: null

          # If the url of the resource is the NCC document,
          # save the resource for later
          ncc = @resources[localUri] if localUri.match /^ncc\.x?html?$/i

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
      ncc = new LYT.NCCDocument obj.url, this

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
      process.fail -> deferred.reject BOOK_BOOKMARKS_NOT_LOADED_ERROR

      process.done (data) =>
        if data?
          @lastmark = data.lastmark
          @bookmarks = data.bookmarks
          @_normalizeBookmarks()
        resolve()

    # Kick the whole process off
    issue @id

  # ----------

  # Returns all .smil files in the @resources array
  getSMILFiles: () ->
    res for res of @resources when @resources[res].url.match /\.smil$/i

  # Returns all SMIL files which is referred to by the NCC document in order
  getSMILFilesInNCC: () ->
    ordered = []
    for section in @nccDocument.sections
      if not (section.url in ordered)
        ordered.push section.url

    ordered

  getSMIL: (url) ->
    url = url.toLowerCase()
    deferred = jQuery.Deferred()
    if not (url of @resources)
      return deferred.reject()

    smil = @resources[url]
    smil.document or= new LYT.SMILDocument smil.url, this

    smil.document.done (smilDocument) ->
      deferred.resolve smilDocument

    smil.document.fail (error) =>
      smil.document = null
      deferred.reject error

    deferred.promise()

  firstSegment: ->
    @nccDocument
    .then (document) ->
      document.firstSection()
    .then (section) ->
      section.firstSegment()

  getSectionBySegment: (segment) ->
    refs = (section.fragment for section in @nccDocument.sections)
    current = segment

    # Inclusive backwards search
    iterator = () ->
      result = current
      current = current?.previous
      result

    while not id and item = iterator()
      if item.id in refs
        id = item.id
      else
        items = item.el.find("[id]")
        item.el.find("[id]").each ->
          childID = @getAttribute "id"
          if childID in refs
            id = childID
            false # Break out early

    section = @nccDocument.sections[refs.indexOf id]


  # Gets the book's metadata (as stated in the NCC document)
  getMetadata: ->
    @nccDocument?.getMetadata() or null

  saveBookmarks: -> LYT.service.setBookmarks this

  _sortBookmarks: ->
    log.message "Book: _sortBookmarks"
    smils = @getSMILFilesInNCC()

    tmpBookmarks = ( @bookmarks or [] ).slice 0
    tmpBookmarks.sort (aMark, bMark) ->
      [aMarkSmil, aMarkID] = aMark.URI.split '#'
      aMarkIndex = smils.indexOf aMarkSmil

      [bMarkSmil, bMarkID] = bMark.URI.split '#'
      bMarkIndex = smils.indexOf bMarkSmil

      if aMarkIndex < bMarkIndex
        return -1
      else if aMarkIndex is bMarkIndex
        return aMark.timeOffset - bMark.timeOffset
      else if aMarkIndex > bMarkIndex
        return 1

    @bookmarks = tmpBookmarks


  # Delete all bookmarks that are very close to each other
  _normalizeBookmarks: ->
    temp = {}
    for bookmark in @bookmarks
      temp[bookmark.URI] or= []
      # Find an index for this bookmark: either at the end of the array
      # or at the location of anohter bookmark very close to this one
      i = 0
      while i < temp[bookmark.URI].length
        saved = temp[bookmark.URI][i]
        if -2 < saved.timeOffset - bookmark.timeOffset < 2
          break
        i++
      temp[bookmark.URI][i] = bookmark

    @bookmarks = []
    @bookmarks = @bookmarks.concat bookmarks for uri, bookmarks of temp

  # TODO: Add remove bookmark method
  addBookmark: (segment, offset = 0) ->
    log.message "Book: addBookmark"
    bookmark = segment.bookmark offset
    section = @getSectionBySegment segment

    # Add closest section's title as bookmark title
    bookmark.note = text: section.title

    # Add to bookmarks and save
    @bookmarks or= []

    @bookmarks.push bookmark

    @_normalizeBookmarks()
    @_sortBookmarks()
    @saveBookmarks()

  setLastmark: (segment, offset = 0) ->
    @lastmark = segment.bookmark offset
    @saveBookmarks()

  segmentByURL: (url) ->
    deferred = jQuery.Deferred()

    [smil, fragment] = url.split '#'
    smil = smil.split('/').pop()

    @getSMIL(smil)
    .done (document) ->
      if fragment
        segment = document.getContainingSegment fragment
      else
        segment = document.segments[0]

      if segment
        segment.load().done (segment) -> deferred.resolve segment
      else
        deferred.reject()
    .fail ->
      deferred.reject()

    deferred.promise()

  # Get the following segment if we are very close to the end of the current
  # segment and the following segment starts within the fudge limit.
  _fudgeFix: (offset, segment, fudge = 0.1) ->
    segment = segment.next if segment.end - offset < fudge and segment.next and offset - segment.next.start < fudge
    return segment

  segmentByAudioOffset: (start, audio, offset = 0, fudge = 0.1) ->
    if not audio
      log.error 'Book: segmentByAudioOffset: audio not provided'
      return jQuery.Deferred().reject('audio not provided')

    @searchSections start, (section) =>
      for segment in section.document.segments
        # Using 0.01s to cover rounding errors (yes, they do occur)
        if segment.audio is audio and segment.start - 0.01 <= offset < segment.end + 0.01
          segment = @_fudgeFix offset, segment
          # FIXME: loading segments is the responsibility of the section each
          # each segment belongs to.
          log.message "Book: segmentByAudioOffset: load segment #{segment.url()}"
          segment.load()
          return segment

  # Search for sections using a callback handler
  # Returns a jQuery promise.
  # handler: callback that will be called with one section at a time.
  #          If handler returns anything trueish, the search will stop
  #          and the promise will resolve with the returned trueish.
  #          If the handler returns anything falseish, the search will
  #          continue by calling handler once again with a new section.
  #
  #          If the handler exhausts all sections, the promise will reject
  #          with no return value.
  #
  # start:   the section to start searching from (default: current section).
  searchSections: (start, handler) ->
    # The use of iterators below can easily be adapted to the Strategy
    # design pattern, accommodating other search orders.

    # Generate an iterator with start value start and nextOp to generate
    # the next value.
    # Will stop calling nextOp as soon as nextOp returns null or undefined
    makeIterator = (start, nextOp) ->
      current = start
      return ->
        result = current
        current = nextOp current if current?
        return result

    # This iterator configuration will make the iterator return this:
    # this
    # this.next
    # this.previous
    # this.next.next
    # this.previous.previous
    # ...
    iterators = [
      makeIterator start, (section) -> section.previous
      makeIterator start, (section) -> section.next
    ]

    # This iterator will query the iterators in the iterators array one at a
    # time and remove them from the array if they stop returning anything.
    i = 0
    iterator = ->
      result = null
      while not result? and i < iterators.length
        result = iterators[i].apply()
        iterators.splice(i) if not result?
        i++
        i %= iterators.length
        return result if result

    searchNext = () ->
      if section = iterator()
        section.load()
        section.then (section) ->
          if result = handler section
            result
          else
            searchNext()
      else
        jQuery.Deferred().reject()

    searchNext()

