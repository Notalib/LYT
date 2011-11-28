# This module handles gui callbacks and various utility functions

LYT.gui =
  
  renderBookshelf: (books, view) ->
    #todo: add pagination
    list = view.find("ul")
    for book in books
      log.message book
      list.append("""<li><a href="#book-play?book=#{book.id}"><h1>#{book.title}</h1><h2>#{book.author}</h2></a></li>""")
    
    list.listview('refresh')
  
  renderBookPlayer: (metadata, section, view) ->
    #fixme: something in this function makes the app hang indefinetely on android phones
    #alert "rendering book player book title"
    #view.find("#title").text metadata.title.content
    #alert "rendering book player boo creator"
    #if metadata.creator?   
    #  view.find("#author").text toSentence(item.content for item in metadata.creator)
    #alert "rendering book player section title" 
    #view.find("#book_chapter").text section.title
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
   
  #renderBookIndex: (book, view) ->