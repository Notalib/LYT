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

  didYouMeanItem = (item) ->
    element = jQuery """
    <li>
      <a href="" class="">
        <h3>#{item or "&nbsp;"}</h3>
      </a>
    </li>
    """
    return element

  
  getCoverSrc = (id) ->
    "http://bookcover.e17.dk/#{id}_h80.jpg"
  
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
          'animate': false,
          'useDialogForceFalse': true,
          'useModal': true,
          'buttons' : {
            'OK': 
              click: (event) ->
              ,
              theme: "c"
            ,  
          }
        }) 
      else
        $(this).simpledialog({
          'mode' : 'bool',
          'prompt' : 'Vil du fjerne denne bog?',
          'subTitle' : book.title,
          'animate': false,
          'useDialogForceFalse': true,
          'useModal': true,
          'buttons' : {
            'Fjern': 
              click: (event) -> 
                LYT.bookshelf.remove(book.id).done -> list.remove()
              ,
              id: "ok-btn"
              ,
              theme: "c"
            ,
            'Annuller': 
              click: (event)->
              ,
              id: "cancel-btn"
              ,
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
    $('#book-play').css
      'background-color': $("#book-text-content").css('background-color')
  
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
    
    # if the list i empty -> bookshelf is empty -> show icon...
    if(list.length is 1)
      $("#bookshelf-content").css('background','transparent url(../images/icons/empty_bookshelf.png) no-repeat')
        
    
    list.listview('refresh')

  hideplayBackRate: () ->
      $("#playBackRate").hide()


  hideOrShowButtons: (details) ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin) #Guest login
      $("#add-to-bookshelf-button").hide()
      $("#details-play-button").hide()
    else
      if details.state is LYT.config.book.states.Undervejs
        $("#add-to-bookshelf-button").hide()
        $("#details-play-button").hide() 
      else  
        $("#add-to-bookshelf-button").show()
        $("#details-play-button").show() 
  
  clearBookPlayer: (view) ->
    $("#book-text-content").empty()
    $("#currentbook_image img").attr "src", defaultCover
    $("#player-info h1, #player-chapter-title").hide()

  ClearIndex : (view) -> #called  on beforeshow event
     #remove childpages generated by jQueryMobile
     view.children("ol").listview('childPages').remove()
     view.children("ol").empty()
     view.children("ol").listview('refresh')

     

  bookPlayer: (book, view) ->
    $("#player-book-title").text book.title
    $("#player-book-author").text book.author
    $("#player-info h1, #player-chapter-title").show()
    loadCover $("#currentbook_image img"), book.id


  ShowAnnouncements: (announcements) ->
    #for announcement in announcements
     # if announcement.text?
       # alert announcement.text #Stops processing of javascript (alert)...

    #LYT.service.markAnnouncementsAsRead(announcements)


  bookEnd: () ->
    view = $("#book-text-content")
    view.html "Her slutter bogen"
  
  singleImage: (image, area) ->
    view = $("#book-text-content")
    vspace = ($(window).height() - 20)
    area or=
      width: image.naturalWidth
      height: image.naturalHeight
      tl:
        x: 0
        y: 0
      br:
        x: image.naturalWidth
        y: image.naturalHeight
    scale = 1;
    if view.width() < area.width
      scale = view.width() / area.width
    else if vspace < area.height
      scale = vspace / area.height
    # FIXME: resizing div to fit content in case div is too large
    image.width  = image.naturalWidth * scale;
    image.height = image.naturalHeight * scale;
    jQuery(image).css('position', 'relative').css('left', - area.tl.x * scale).css('top', - area.tl.y * scale)
  
  textContent: (media) ->
    view = $("#book-text-content")
    view.html media.html
    console.log media
    if(LYT.player.isIOS() or $.jPlayer.platform.android?)
      view.css('overflow-x','scroll')
    
    images = view.find("img")
    if images.length == 1
      @singleImage images[0]
    else
      images.each ->
        img = $(this)
  
        return if img.data("vspace-processed")? == "yes"
          
        img.data "vspace-processed", "yes" # Mark as already-processed
          
        vspace = ($(window).height() - 20)
        log.message "render: textContent: vspace: #{vspace}"
        
        if img.height() > vspace
          img.height(vspace)
          img.width('auto')
        
        if img.width() > view.width()
          img.width('100%')
          img.height('auto')
        
        img.click -> img.toggleClass('zoom')
      
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
            <a href="#book-play?book=#{book.id}&section=#{item.url}&autoplay=true"> 
              #{item.title}
            </a>"""
        
        if isPlaying item.id
          element.append """<div class="section-now-playing"></div>"""
        
        if item.children.length > 0
          nested = jQuery "<ol></ol>"
          mapper(nested, item.children)
          element.append nested
        list.append element
        
    # Create an uordered list wrapper for the list
    view.children("ol").listview('childPages').remove()
    list = view.children("ol").empty()
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NccRootElement"
    # FIXME: We should be using the playlist here - any reference to NCC- or
    # SMIL documents from this class is not good design.
    mapper(list, book.nccDocument.structure)
    
    list.listview('refresh')
 
  
  bookmarks: (book, view) ->  
    # Set the back button's href

    $("#index-back-button").attr "href", "#book-play?book=#{book.id}"

        
    # Create an uordered list wrapper for the list
    view.children("ol").listview('childPages').remove()
    list = view.children("ol").empty()
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NccRootElement"

    for item in book.bookmarks
      element = jQuery "<li></li>" 
      element.attr "id", item.id
      element.attr "data-href", item.id
      [baseUrl, id] = item.URI.split('#')
      element.append """
        <a href="#book-play?book=#{book.id}&section=#{baseUrl}&segment=#{id}&autoplay=true"> 
          #{item.note.text}
        </a>"""
      
      list.append element

    list.listview('refresh')
 

  searchResults: (results, view) ->
    list = view.find "ul"
    list.empty() if results.currentPage is 1 or results.currentPage is undefined
    
    list.append bookListItem("book-details", result) for result in results
    
    if results.loadNextPage?
      $("#more-search-results").show()
    else
      $("#more-search-results").hide()
    
    $('#listshow-btn').show()#show button list 
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
          LYT.var.callback = true
          event.preventDefault()
          event.stopImmediatePropagation()
        list.append listItem   
    list.listview('refresh')

  
  catalogListsDirectlink: (callback, view, param) ->
    list = view.find "ul"
    list.empty()
    
    for query in LYT.lists
      if query.id is param
        callback query.callback()
        event.preventDefault()
        event.stopImmediatePropagation()
    list.listview('refresh')

  showDidYouMean: (results, view) ->
    list = view.find "ul"
    list.empty()

    list.append jQuery """<li data-role="list-divider" role="heading">Mente du?</li>"""


    for item in results
      listItem = didYouMeanItem(item)
      listItem.find("a").click (event) ->
        $.mobile.changePage "#search?term=#{encodeURI item}" , transition: "none"
      list.append listItem  

      
    $('#listshow-btn').show()#show button list 
    list.listview('refresh')  

    
  profile: () ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
      $("#current-user-name").text 'gæst'
    else 
      $("#current-user-name").text LYT.session.getInfo().realname
