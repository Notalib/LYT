LYT.bookshelf =
  load: (page = 1) ->
    deferred = jQuery.Deferred()
    pageSize = 5
    from = (page - 1) * pageSize
    to   = from + pageSize
    log.message "Bookshelf: Getting book from #{from} to #{to}"
    response = LYT.service.getBookshelf(from, to)
    response.done (list) ->
      log.message "Bookshelf: Got #{list.length} book(s)"
      if list.length >= pageSize
        list.pop()
        list.nextPage = page + 1
      else
        list.nextPage = false
      deferred.resolve list
    
    response.fail (args...) ->
      deferred.reject args...
    
    deferred
    
  add: (id) ->
    LYT.service.issue(id)
    
  remove: (id) ->
    LYT.service.return(id)