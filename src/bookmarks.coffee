# This module fetches/stores bookmarks using the **non**-DODP web service

LYT.bookmarks = do ->
  
  # ## Privileged API
  
  getAjaxOptions = (url, data) ->
    dataType:    "json"
    type:        "POST"
    contentType: "application/json; charset=utf-8"
    data:        JSON.stringify data
    url:         url
  
  # ------------
  
  # ## Public API
  
  # Get a book's bookmarks
  get: (memberId, bookId) ->
    deferred = jQuery.Deferred()
    
    # Get (build) the request options
    options = getAjaxOptions LYT.config.bookmarks.getUrl, {
      memberid: memberId
      itemid:   bookId
    }
    
    # Set up a success handler to parse the response
    options.success = (data, status, jqHXR) ->
      log.message "Bookmarks: Got bookmarks for book #{bookId}", data
      
      marks =
        bookmarks: []
        lastmark:  null
      
      # Go thru each bookmark in the response data
      for mark in data.bookmarks or []
        # If the bookmark is marked as "current", it's the lastmark
        if mark.current
          marks.lastmark = mark
        else
          marks.bookmarks.push mark
      
      deferred.resolve marks
    
    # Set up an error handler
    options.error = (jqXHR, status, error) ->
      log.error "Bookmarks: Failed to get bookmarks for book #{bookId}", status, error
      deferred.reject()
    
    jQuery.ajax options
    deferred
  
  
  # Set a book's bookmarks
  set: (memberId, bookId, marks) ->
    deferred = jQuery.Deferred()
    
    # Set up the JSON data to send to the server
    data =
      memberid: memberId
      itemid:   bookId
      bookmarks: []
    
    # If the book has a lastmark, add it to the JSON data
    if marks.lastmark?
      data.bookmarks.push {
        current: "true"
        section: "#{book.lastmark.section}"
        offset:  "#{book.lastmark.offset}"
      }
    
    # Add in all the other bookmarks
    data.bookmarks.push mark for mark in marks.bookmarks or []
    
    # Get (build) the request options
    options = getAjaxOptions LYT.config.bookmarks.setUrl, request
    
    # Set up a success handler
    options.success = (data, status, jqHXR) ->
      log.message "Bookmarks: Set bookmarks for book #{bookId}", data
      deferred.resolve()
    
    # Set up an error handler
    options.error = (jqXHR, status, error) ->
      log.error "Bookmarks: Failed to set bookmarks for book #{bookId}", status, error
      deferred.reject()
    
    jQuery.ajax options
    deferred
  
