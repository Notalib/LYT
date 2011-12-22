# This module handles gui callbacks and various utility functions

LYT.render =
  
  defaultCover: "/images/icons/default-cover.png"
  
  init: () ->
    log.message 'Render: init'
    @setStyle()
  
  
  # Create a book list-item which links to the `target` page
  bookListItem: (target, book) ->
    info = []
    info.push book.author if book.author?
    info.push @getMediaType(book.media) if book.media?
    info = info.join "&nbsp;&nbsp;|&nbsp;&nbsp;"
    
    if book.id is LYT.player.book?.id?
      nowPlaying = """<img src="/images/icon/nowplaying.png" alt="" class="book-now-playing" alt="">"""
    
    element = jQuery """
    <li data-book-id="#{book.id}">
      <a href="##{target}?book=#{book.id}">
        <img class="ui-li-icon cover-image" src="#{LYT.render.defaultCover}">
        <h3>#{book.title or "&nbsp;"}</h3>
        <p>#{info or "&nbsp;"}</p>
        #{nowPlaying or ""}
      </a>
    </li>
    """
    
    # Attempt to get the book's cover image
    cover = new Image
    cover.onload = -> element.find("img.cover-image").attr "src", @src
    cover.src = @getCover book.id
    
    return element
  
  
  bookshelf: (books, view, page) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty() if page is 1
    
    # TODO: Abstract the list generation (and image error handling below) into a separate function
    for book in books
      li = @bookListItem "book-play", book
      removeLink = jQuery """<a href="" title="Slet bog" class="remove-book"></a>"""
      removeLink.click (event) ->
        LYT.bookshelf.remove(book.id).done -> li.remove()
      
      li.append removeLink
      list.append li
    
    list.listview('refresh')
  
  bookPlayer: (book, view) ->
    view.find("#title").text book.title  
    view.find("#author").text book.author
    #view.find("#book_chapter").text section.title
    
  bookDetails: (details, view) ->
    view.find("#title").text details.title
    view.find("#author").text details.author
    view.find("#description").text details.description
    # TODO: totalTime isn't available in getContentMetadata
    # view.find("#totaltime").text details.totalTime
    
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
    
    list.append @bookListItem("book-details", result) for result in results
    
    if results.nextPage
      $("#more-search-results").show()
    else
      $("#more-search-results").hide()
    
    list.listview('refresh')
  
