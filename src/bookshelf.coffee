LYT.bookshelf =
  
  load: (page = 0) ->
    if page is 0
      from = 0 
    else
      from = page*5   
    to = from+5
    
    LYT.service.getBookshelf(from,to)
    
  add: (id) ->
    LYT.service.issue(id)
    
  remove: (id) ->
    LYT.service.return(id)