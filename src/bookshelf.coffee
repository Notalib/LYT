LYT.bookshelf =
  
  load: ->
    LYT.service.getBookshelf(0,5)
    
  add: (id) ->
    LYT.service.issue(id)
    
  remove: (id) ->
    LYT.service.return(id)