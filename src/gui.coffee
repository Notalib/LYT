# This module handles gui callbacks and various utility functions

LYT.gui =
  
  renderBookshelf: (books, view) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty()
    for book in books
      list.append("""<li><a href="#book-play?book=#{book.id}"><h1>#{book.title}</h1><h2>#{book.author}</h2></a></li>""")
    
    list.listview('refresh')
  
  renderBookPlayer: (metadata, section, view) ->
    #fixme: something in this function makes the app hang indefinetely on android phones
    #todo: use direct properties on book class book.title .author and .totaltime
    #alert "rendering book player book title"
    view.find("#title").text metadata.title.content
    #alert "rendering book player boo creator"
    if metadata.creator?   
      view.find("#author").text toSentence(item.content for item in metadata.creator)
    #alert "rendering book player section title" 
    view.find("#book_chapter").text section.title
    #alert "done"
    
  renderBookDetails: (metadata, view) ->
    view.find("#title").text metadata.title.content
    
    if metadata.creator?
      view.find("#author").text toSentence(item.content for item in metadata.creator)
    
    if metadata.narrator?
      view.find("#narrator").text toSentence(item.content for item in metadata.narrator)
    
    view.find("#totaltime").text metadata.totalTime.content
    
  covercache: (element, id) ->
    $(element).each ->
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
  
  parseMediaType: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"
   
  renderBookIndex: (book, view) ->  
    # Recursively builds nested ordered lists from an array of items
    mapper = (list, items) ->
      log.message items
      for item in items
        element = jQuery "<li></li>"
        element.attr "id", item.id
        element.attr "data-href", item.href
        element.text item.title
        if item.children.length > 0
          nested = jQuery "<ol></ol>"
          mapper(nested, item.children)
          element.append nested
        list.append element
        
        element.click ->
          log.message "go to now: #book-play?book=#{book.id}&section=#{item.id}"
          $.mobile.changePage "#book-play?book=#{book.id}&section=#{item.id}"
        

    # Create an uordered list wrapper for the list
    list = view.children("ol").empty()
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NCCRootElement"
    mapper(list, book.nccDocument.structure)
    
    list.trigger 'create'
    
    #log.message list
  
    