# Requires `/common`  
# Requires `/models/service/service`  

# -------------------

# This module models the bookshelf (i.e. the
# `MemberCatalog`; the list of issued content)

LYT.bookshelf =
  # Load a paginated part of the bookshelf.  
  # Pages are numbered sequentially, starting at 1
  load: (page = 1) ->
    deferred = jQuery.Deferred()
    pageSize = LYT.config.bookshelf.pageSize
    
    # By specifiying the `from` and `to` params
    # this way, the maximum number of items returned
    # will be `pageSize + 1`.  
    # I.e. if the page size is 5 the range will in
    # fact retrieve 6 items, if there are 6 or more
    # items left in the list. If there are 5 or fewer
    # it's obvious that there isn't a "next page".
    # However, if 6 items are returned, there is at
    # least 1 more page to that can be fetched.
    from = (page - 1) * pageSize
    to   = from + pageSize
    
    log.message "Bookshelf: Getting book from #{from} to #{to}"
    
    response = LYT.service.getBookshelf(from, to)
    response.done (list) ->
      # Are there more results than `pageSize`?
      if list.length > pageSize
        # If yes, then there's a next page, so
        # leave out the extra item, and set the
        # next page number
        list.pop()
        list.nextPage = page + 1
      else
        list.nextPage = false
      deferred.resolve list
    
    response.fail (args...) ->
      deferred.reject args...
    
    deferred.promise()
  
  
  # Add (issue) a book to the shelf by its ID
  add: (id) ->
    LYT.service.issue(id)
  
  
  # Remove (return) a book from the shelf by its ID
  remove: (id) ->
    LYT.service.return(id)