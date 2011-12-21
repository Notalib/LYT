# This module handles gui callbacks and various utility functions

LYT.render =
  
  defaultCover: "/images/icons/default-cover.png"
  
  init: () ->
    log.message 'Render: init'
    @setStyle()
    
  bookshelf: (books, view, page) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty() if page is 1
    
    # TODO: Abstract the list generation (and image error handling below) into a separate function
    for book in books
      if book.id is LYT.player.book?.id?
        nowPlaying = """<img src="/images/icon/nowplaying.png" alt="" class="book-now-playing">"""
      else
        nowPlaying = ""
      
        
      el = $("""
        <li data-book-id="#{book.id}">
          <a href="#book-play?book=#{book.id}">
            <img class="ui-li-icon cover-image" src="#{@getCover(book.id)}">
            <h3>#{book.title or "&nbsp;"}</h3>
            <p>#{book.author or "&nbsp;"}</p>
            #{nowPlaying}
          </a>
          <a href="" title="Slet bog" class="remove-book"></a>     
        </li>""")
      
      el.find('a.remove-book').click (event) ->
        li = $(this).parent("li")
        id = li.attr 'data-book-id'
        log.message """Bookshelf: remove book with id #{id}"""
        LYT.bookshelf.remove id
        li.remove()
      
      list.append el
      
      
    
    # TODO: Temporary fix for missing covers
    list.find("img.cover-image").one "error", (event) -> @src = LYT.render.defaultCover    
    list.listview('refresh')
  
  bookPlayer: (book, view) ->
    view.find("#title").text book.title  
    view.find("#author").text book.author
    #view.find("#book_chapter").text section.title
    
  bookDetails: (book, view) ->
    view.find("#title").text book.title
    view.find("#author").text book.author
    view.find("#totaltime").text book.totalTime
    
  getCover: (id) ->
    "http://www.e17.dk/sites/default/files/bookcovercache/#{id}_h80.jpg"
    
  getMediaType: (mediastring) ->
    if /\bAA\b/i.test mediastring
      "Lydbog"
    else
      "Lydbog med tekst"
  
  setStyle: () ->
    log.message 'Render: setting custom style'
    $("#textarea-example, #book-text-content").css LYT.settings.get('textStyle')
  
  bookIndex: (book, view) ->  
    # Set the back button's href
    $("#index-back-button").attr "href", "#book-play?book=#{book.id}"
    
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
        
        # if book.id is LYT.player.book?.id and item.id is LYT.player.section?.id
        #   element.append """<img src="/images/icon/nowplaying.png" alt="" class="book-now-playing">"""
        
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
    list = view.find "ul"
    list.empty() if results.currentPage is 1
    
    if results.length > 0
      for item in results
        if item.id is LYT.player.book?.id?
          nowPlaying = """<img src="/images/icon/nowplaying.png" alt="" class="book-now-playing">"""
        else
          nowPlaying = ""
        list.append """
          <li id="#{item.id}">
            <a href="#book-details?book=#{item.id}">
              <img class="ui-li-icon cover-image" src="#{@getCover(item.id)}">
              <h3>#{item.title}</h3>
              <p>#{item.author} | #{@getMediaType item.media}</p>
              #{nowPlaying}
            </a>
          </li>"""
    
    # TODO: Temporary fix for missing covers
    list.find("img.cover-image").one "error", (event) -> @src = LYT.render.defaultCover
    
    # TODO: Temporary, I hope
    if results.nextPage
      $("#more-search-results").show()
    else
      $("#more-search-results").hide()
    
    list.listview('refresh')