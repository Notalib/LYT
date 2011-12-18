# This module handles gui callbacks and various utility functions

LYT.render =
  
  defaultCover: "/images/default.png"
  
  init: () ->
    log.message 'Render: init'
    @setStyle()
    
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
  
  bookPlayer: (book, view) ->
    view.find("#title").text book.title  
    view.find("#author").text book.author
    #view.find("#book_chapter").text section.title
    
  bookDetails: (book, view) ->
    view.find("#title").text book.title
    view.find("#author").text book.author
    view.find("#totaltime").text book.totalTime
    
  getCoverSrcString: (id) ->
    "http://www.e17.dk/sites/default/files/bookcovercache/#{id}_h80.jpg"
  
  getCover: (id) ->
    src = @getCoverSrcString(id)
    #if jQuery.load(src)
    #  return src
    #else
    #  return defaultCover
    return src
    
  getMediaType: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"
  
  setStyle: () ->
    log.message 'Render: setting custom style'
    $("#textarea-example, #book-text-content").css LYT.settings.get('textStyle')
  
  bookIndex: (book, view) ->  
    # Recursively builds nested ordered lists from an array of items
    mapper = (list, items) ->
      for item in items
        element = jQuery "<li></li>" 
        element.attr "id", item.id
        element.attr "data-href", item.id
        
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
    list.attr "id", "NccRootElement"
    mapper(list, book.nccDocument.structure)
    
    list.listview('refresh')
  
  searchResults: (results, view) ->
    list = view.find("ul").empty()
    if results.length > 0
      for item in results
        log.message item
        list.append("""
         <li id="#{item.id}">
           <a href="#book-details?book=#{item.id}">
             <img class="ui-li-icon" src="#{@getCover(item.id)}">
             <h3>#{item.author}</h3>
             <p>#{item.author} | #{@getMediaType item.media}</p>
           </a>
         </li>""")
       
    list.listview('refresh')