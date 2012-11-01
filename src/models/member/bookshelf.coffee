# Requires `/common`  
# Requires `/models/service/service`  

# -------------------

# This module models the bookshelf (i.e. the
# `MemberCatalog`; the list of issued content)

LYT.bookshelf =
  # Load a paginated part of the bookshelf.  
  # Pages are numbered sequentially, starting at 1

  #holds the nextpage number if there is one....
  nextPage: false

  load: (page = 1, zeroAndUp = false) ->
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

    if zeroAndUp
      from = 0
      to   = pageSize * (page - 1)
      if to > LYT.config.bookshelf.maxShow
        to = LYT.config.bookshelf.maxShow
      size = to
    else
      from = (page - 1) * pageSize
      to   = from + pageSize
      size = pageSize
    
    log.message "Bookshelf: Getting book from #{from} to #{to}"
    
    response = LYT.service.getBookshelf(from, to)
    response.pipe (list) =>
      # Are there more results than `pageSize`?
      if list.length > size
        # If yes, then there's a next page, so
        # leave out the extra item, and set the
        # next page number
        list.pop()
        list.nextPage = page + 1
      else
        list.nextPage = false
      if not zeroAndUp 
        @nextPage = page + 1
      return list
  
  
  # Add (issue) a book to the shelf by its ID
  add: (id) ->
    LYT.service.issue(id)
  
  
  # Remove (return) a book from the shelf by its ID
  remove: (id) ->
    LYT.service.return(id)

  getNextPage: ->
    @nextPage