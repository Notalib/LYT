# This module handles gui callbacks and various utility functions





LYT.render = do ->
  
  # ## Privileged API
  
  # Default book cover image
  defaultCover = "/images/icons/default-cover.png"
  
  # Create a book list-item which links to the `target` page
  bookListItem = (target, book) ->
    info = []
    info.push book.author if book.author?
    info.push getMediaType(book.media) if book.media?
    info = info.join "&nbsp;&nbsp;|&nbsp;&nbsp;"
    
    playing = LYT.player.getCurrentlyPlaying()
    
    if String(book.id) is String(playing?.book)
      nowPlaying = """<img src="/images/icons/nowplaying.png" alt="" class="book-now-playing" alt="">"""
    
    element = jQuery """
    <li data-book-id="#{book.id}">
      <a href="##{target}?book=#{book.id}" class="book-play-link">
        <img class="ui-li-icon cover-image" src="#{defaultCover}">
        <h3>#{book.title or "&nbsp;"}</h3>
        <p>#{info or "&nbsp;"}</p>
        #{nowPlaying or ""}
      </a>
    </li>
    """
    
    loadCover element.find("img.cover-image").attr book.id
    
    return element
  
  getCoverSrc = (id) ->
    "http://www.e17.dk/sites/default/files/bookcovercache/#{id}_h80.jpg"
  
  loadCover = (img, id) ->
    img.attr "src", LYT.render.defaultCover   
    cover = new Image
    cover.src = getCoverSrc id
    cover.onload = -> img.attr "src", @src
  
  getMediaType = (mediastring) ->
    if /\bAA\b/i.test mediastring
      "Lydbog"
    else
      "Lydbog med tekst"
   
  # ## Public API
  
  setStyle = ->
    log.message 'Render: setting custom style'
    $("#textarea-example, #book-text-content").css LYT.settings.get('textStyle')
  
  init: ->
    log.message 'Render: init'
    setStyle()
  
  setStyle: setStyle
  
  bookshelf: (books, view, page) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty() if page is 1
    
    # TODO: Abstract the list generation (and image error handling below) into a separate function
    for book in books
      li = bookListItem "book-play", book
      removeLink = jQuery """<a href="" title="Slet bog" class="remove-book"></a>"""
      removeLink.click (event) ->
        LYT.bookshelf.remove(book.id).done -> li.remove()
      
      li.append removeLink
      list.append li
    
    list.listview('refresh')
  
  
  bookPlayer: (book, view) ->
    view.find("#title").text book.title  
    view.find("#author").text book.author
    loadCover view.find("#currentbook_image img"), book.id
    #view.find("#book_chapter").text section.title
  
  
  bookDetails: (details, view) ->
    view.find("#title").text details.title
    view.find("#author").text details.author
    view.find("#description").text details.description
    loadCover view.find("img.cover-image"), details.id
    # TODO: totalTime isn't available in getContentMetadata
    # view.find("#totaltime").text details.totalTime
    
  
  bookIndex: (book, view) ->  
    # Set the back button's href
    $("#index-back-button").attr "href", "#book-play?book=#{book.id}"
    
    playing = LYT.player.getCurrentlyPlaying()
    isPlaying = (sectionId) ->
      return false unless playing? and String(book.id) is String(playing?.book)
      return true if String(playing.section) is String(sectionId)
      return true if playing.section.indexOf("#{sectionId}.") is 0
      return false
    
    # Recursively builds nested ordered lists from an array of items
    mapper = (list, items) ->
      for item in items
        element = jQuery "<li></li>" 
        element.attr "id", item.id
        element.attr "data-href", item.id
        
        if item.children.length > 0
          element.append "<span>#{item.title}</span>"
        else
          element.append """
            <a href="#book-play?book=#{book.id}&section=#{item.id}"> 
              #{item.title}
            </a>"""
        
        if isPlaying item.id
          element.append """<img src="/images/icons/nowplaying.png" alt="" class="book-now-playing">"""
        
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
    
    list.append bookListItem("book-details", result) for result in results
    
    if results.nextPage
      $("#more-search-results").show()
    else
      $("#more-search-results").hide()
    
    list.listview('refresh')
  
