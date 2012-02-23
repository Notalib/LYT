# Requires `/common`  
# Requires `/controllers/player`  
# Requires `/models/member/settings`  
# Requires `/models/service/lists`  

# -------------------

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
      nowPlaying = """<div class="book-now-playing"></div>"""
    
    element = jQuery """
    <li data-book-id="#{book.id}">
      <a href="##{target}?book=#{book.id}" class="book-play-link">
        <div class="cover-image-frame">
          <img class="ui-li-icon cover-image" src="#{defaultCover}">
        </div>
        <h3>#{book.title or "&nbsp;"}</h3>
        <p>#{info or "&nbsp;"}</p>
        #{nowPlaying or ""}
      </a>
    </li>
    """
    
    loadCover element.find("img.cover-image"), book.id
    
    return element
  
  getCoverSrc = (id) ->
    "http://www.e17.dk/sites/default/files/bookcovercache/#{id}_h80.jpg"
  
  loadCover = (img, id) ->
    img.attr "src", defaultCover
    
    cover = new Image
    cover.onload = -> img.attr "src", getCoverSrc(id)
    cover.src = getCoverSrc(id)   
  
  getMediaType = (mediastring) ->
    if /\bAA\b/i.test mediastring
      "Lydbog"
    else
      "Lydbog med tekst"

  atachClickEvent = (aElement, book, list) ->
    aElement.click (event) ->
      if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
        $(this).simpledialog({
          'mode' : 'bool',
          'prompt' : 'Du er logget på som gæst!',
          'subTitle' : '...og kan derfor ikke slette bøger.'
          'useModal': true,
          'buttons' : {
            'OK': 
              click: (event) ->
              icon: "info",
              theme: "c"
            ,  
          }
        }) 
      else
        $(this).simpledialog({
          'mode' : 'bool',
          'prompt' : 'Vil du fjerne denne bog?',
          'subTitle' : 'fjern bogen ' + book.title
          'useModal': true,
          'buttons' : {
            'OK': 
              click: (event) -> 
                LYT.bookshelf.remove(book.id).done -> list.remove()
            ,
            'Cancel': 
              click: (event)->
              icon: "delete",
              theme: "c"
            ,
            
      
          }
        })
      #alert book.id
      #LYT.bookshelf.remove(book.id).done -> list.remove()

  
  # ---------------------------
  
  # ## Public API
  
  init: ->
    log.message 'Render: init'
    @setStyle()
  
  setStyle: ->
    log.message 'Render: setting custom style'
    $("#textarea-example, #book-text-content").css LYT.settings.get('textStyle')
  
  bookshelf: (books, view, page) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty() if page is 1
    
    # TODO: Abstract the list generation (and image error handling below) into a separate function
    for book in books
      li = bookListItem "book-play", book
      removeLink = jQuery """<a href=""  title="Slet bog" class="remove-book"></a>"""
      atachClickEvent removeLink,book,li
        
      li.append removeLink
      list.append li
    
    list.listview('refresh')

  hideOrShowButtons: ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
      $("#add-to-bookshelf-button").hide()
      $("#details-play-button").hide()
    else
      $("#add-to-bookshelf-button").show()
      $("#details-play-button").show() 
  
  clearBookPlayer: (view) ->
    $("#book-text-content").empty()
    $("#currentbook_image img").attr "src", defaultCover
    $("#player-info h1, #player-chapter-title").hide()
  
  bookPlayer: (book, view) ->
    $("#player-book-title").text book.title
    $("#player-book-author").text book.author
    $("#player-info h1, #player-chapter-title").show()    
    loadCover $("#currentbook_image img"), book.id
  
  bookDetails: (details, view) -> 
    $("#details-book-title").text details.title
    $("#details-book-author").text details.author
    $("#details-book-description").text details.teaser
    $("#details-book-narrator").text details.speaker
    $("#details-book-totaltime").text "#{details.playtime}:00"
    $("#details-play-button").attr "href", "#book-play?book=#{details.id}"
    loadCover view.find("img.cover-image"), details.id
    
    
  
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
    list.empty() if results.currentPage is 1 or results.currentPage is undefined
    
    list.append bookListItem("book-details", result) for result in results
    
    if results.loadNextPage?
      $("#more-search-results").show()
    else
      $("#more-search-results").hide()
    
    list.listview('refresh')
  
  # TODO: Simple, rough implementation
  catalogLists: (callback, view) ->
    list = view.find "ul"
    list.empty()
    
    for query in LYT.lists
      do (query) ->
        listItem = jQuery """<li id=#{query.id}><a href="#"><h3>#{LYT.i18n query.title}</h3></a></li>"""
        listItem.find("a").click (event) ->
          callback query.callback()
          event.preventDefault()
          event.stopImmediatePropagation()
        list.append listItem
    
    list.listview('refresh')
    
  profile: () ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
      $("#current-user-name").text 'gæst'
    else 
      $("#current-user-name").text LYT.session.getInfo().realname
