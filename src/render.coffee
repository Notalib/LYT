# This module handles gui callbacks and various utility functions

LYT.render =
  
  bookshelf: (books, view) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty()
    for book in books
      list.append("""
        <li>
          <a href="#book-play?book=#{book.id}">
            <h1>#{book.title}</h1>
            <h2>#{book.author}</h2>
          </a>
        </li>""")
    
    list.listview('refresh')
  
  bookPlayer: (book, section, view) ->
    view.find("#title").text book.title  
    view.find("#author").text book.author
    view.find("#book_chapter").text section.title
    
  bookDetails: (book, view) ->
    view.find("#title").text book.title
    view.find("#author").text book.author
    view.find("#totaltime").text book.totalTime
    
  covercache: (element) ->
    $(element).each ->
      id = $(@).attr('id')
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
      img = $(new Image()).load(->
        $("#" + id).find("img").attr "src", u
      ).error(->
      ).attr("src", u)

  covercacheOne: (element, id) ->
    u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
    img = $(new Image()).load(->
      $(element).find("img").attr "src", u
    ).error(->
    ).attr("src", u)
  
  mediaType: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"
   
  bookIndex: (book, view) ->  
    # Recursively builds nested ordered lists from an array of items
    mapper = (list, items) ->
      log.message items
      for item in items
        element = jQuery "<li></li>" 
        element.attr "id", item.id
        element.attr "data-href", item.href
        
        if item.children.length > 0
          element.text item.title        
        else
          element.append("""
            <a href="#book-play?book=#{book.id}&section=#{item.id}"> 
              #{item.title}
            </a>""")
          
        if item.children.length > 0
          nested = jQuery "<ol></ol>"
          mapper(nested, item.children)
          element.append nested
        list.append element
        
        
    # Create an uordered list wrapper for the list
    list = view.children("ol").empty()
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NCCRootElement"
    mapper(list, book.nccDocument.structure)
    
    list.listview('refresh')
    
    #log.message list
  
  searchResults: (results, view) ->
    null
    