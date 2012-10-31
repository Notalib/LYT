# Requires `/common`  
# Requires `/controllers/player`  
# Requires `/models/member/settings`  
# Requires `/models/service/lists`  

# -------------------

# This module handles gui callbacks and various utility functions
#console.log 'Load LYT.render'

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
    
    if String(book.id) is String(LYT.player.getCurrentlyPlaying()?.book)
      nowPlaying = """<div class="book-now-playing"></div>"""
    
    element = jQuery """
      <li data-book-id="#{book.id}">
        <a class="gatrack book-play-link" ga-action="Vælg" ga-book-id="#{book.id}" ga-book-title="#{(book.title or '').replace '"', ''}" href="##{target}?book=#{book.id}">
          <div class="cover-image-frame">
            <img class="ui-li-icon cover-image">
          </div>
          <h3>#{book.title or "&nbsp;"}</h3>
          <p>#{info or "&nbsp;"}</p>
          #{nowPlaying or ""}
        </a>
      </li>
      """

    if String(target) is "book-details"
      element.attr "data-icon", "arrow-right"

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
  
  loadCover = (img, id) ->
    # if periodical, use periodical code (first 4 letters of id)
    imageid = if $.isNumeric(id) then id else id.substring(0, 4)
    img.attr "src", "http://bookcover.e17.dk/#{imageid}_h80.jpg"


  getMediaType = (mediastring) ->
    if /\bAA\b/i.test mediastring
      LYT.i18n('Talking book')
    else
      LYT.i18n('Talking book with text')

  attachClickEvent = (aElement, book, list) ->
    aElement.click (event) ->
      if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
        parameters =
          mode:               'bool'
          prompt:              LYT.i18n('You are logged on as guest')
          subTitle:            '...' + LYT.i18n('and hence can not remove books.')
          animate:             false
          useDialogForceFalse: true
          useModal:            true
          buttons:             {}
        parameters.buttons[LYT.i18n('OK')] =
          click: ->
          theme: 'c'
        LYT.render.showDialog($(this),parameters)
      else
        parameters =
          mode:                'bool'
          prompt:              LYT.i18n('Delete this book?')
          subTitle:            book.title
          animate:             false
          useDialogForceFalse: true
          useModal:            true
          buttons:             {}
        parameters.buttons[LYT.i18n('Remove')] =
          click: -> LYT.bookshelf.remove(book.id).done -> list.remove()
          id:    'ok-btn'
          theme: 'c'
        parameters.buttons[LYT.i18n('Cancel')] =
          click: ->
          id:    'cancel-btn'
          theme: 'c'
        LYT.render.showDialog($(this),parameters)


  # Displays a small speech bubble notification vertOffset pixels below the
  # provided element containing the provided text for timeout milliseconds.
  # If timeout provided is zero, the bubble will display until the user clicks
  # it. Timeout defaults to 2000.
  bubbleNotification = (element, text, vertOffset=0, timeout) ->
    notification = $("<div class=\"bubble-notification\"><div class=\"bubble-notification-arrow\"></div><div class=\"bubble-notification-message\">#{text}</div></div>")
    # We set visibility to hidden and attach it to body in order to measure the width
    notification.css 'visibility', 'hidden'
    $('body').append notification
    notification.css 'left', element.offset().left - notification.width()/2 + element.width()/2
    notification.css 'top', element.offset().top + element.height() + vertOffset
    notification.hide()
    notification.css 'visibility', ''
    notification.fadeIn()
    remove = -> notification.fadeOut -> notification.remove()
    if timeout == 0
      notification.on 'click', remove
    else
      setTimeout(remove, timeout or 2000)
  
  # ---------------------------
  
  # ## Public API
  
  bubbleNotification: bubbleNotification
  
  init: ->
    log.message 'Render: init'
    @setStyle()
    @setVersion()

  setStyle: ->
    log.message 'Render: setting custom style'
    # TODO: Dynamic modification of a CSS class in stead of this
    $("#textarea-example, #book-stack-content, #book-plain-content").css LYT.settings.get('textStyle')
    $('#book-player').css
      'background-color': $("#book-stack-content").css('background-color')
      
  setVersion: -> $('.lyt-version').html LYT.VERSION
  
  bookmarkAddedNotification: -> LYT.render.bubbleNotification $('#book-index-button'), "Bogmærke tilføjet", 5
  
  bookshelf: (books, view, page, zeroAndUp) ->
    #todo: add pagination
    list = view.find("ul")
    list.empty() if page is 1 or zeroAndUp

    for book in books
      target = if String(book.id) is String(LYT.player.getCurrentlyPlaying()?.book) then 'book-player' else 'book-play'
      li = bookListItem target, book
      removeLink = jQuery """<a href="" class="remove-book">#{LYT.i18n("Remove book")}</a>"""
      attachClickEvent removeLink, book, li
      li.append removeLink
      list.append li
    
    # if the list i empty -> bookshelf is empty -> show icon...
    if(list.length is 1)
      $("#bookshelf-content").css('background','transparent url(../images/icons/empty_bookshelf.png) no-repeat')
    
    list.listview('refresh')

  loadBookshelfPage: (content, page = 1, zeroAndUp = false) ->
      process = LYT.bookshelf.load(page,zeroAndUp)
      .done (books) ->
        LYT.render.bookshelf(books, content, page, zeroAndUp)
        if books.nextPage
          $("#more-bookshelf-entries").show()
        else
          $("#more-bookshelf-entries").hide()
          
      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"

        
      LYT.loader.register "Loading bookshelf", process

  hideplayBackRate: () ->
      $("#playBackRate").hide()

  hideOrShowButtons: (details) ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin) #Guest login
      $("#add-to-bookshelf-button").hide()
      $("#details-play-button").hide()
    else
      if details.state is LYT.config.book.states.pending
        $("#book-unavailable-message").show()
        $("#add-to-bookshelf-button").hide()
        $("#details-play-button").hide() 
      else  
        $("#book-unavailable-message").hide()
        $("#add-to-bookshelf-button").show()
        $("#details-play-button").show() 
  
  clearBookPlayer: (view) ->
    LYT.render.textContent null
    $("#currentbook_image img").attr "src", defaultCover
    $("#player-info h1, #player-chapter-title").hide()

  clearContent: (content) ->
    # Removes anything in content
    content.children("ol").listview('childPages').remove()
    content.children("ol").listview("refresh")
    
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


  bookEnd: () -> LYT.render.content.renderText LYT.i18n('The end of the book')
  
  textContent: (segment) ->
    return unless segment
    # Set enable or disable add bookmark button depending on we can bookmark
    if segment.canBookmark
      $('.ui-icon-bookmark-add').removeClass 'disabled'
      $('#bookmark-add-button').attr 'title', LYT.i18n('Bookmark location')
    else
      $('.ui-icon-bookmark-add').addClass 'disabled'
      $('#bookmark-add-button').attr 'title', LYT.i18n('Unable to bookmark location')
    LYT.render.content.renderSegment segment
      
  bookDetails: (details, view) ->
    $("#details-book-title").text details.title
    $("#details-book-author").text details.author
    $("#details-book-description").text details.teaser
    $("#details-book-narrator").text details.speaker
    $("#details-book-totaltime").text "#{details.playtime}:00"
    $("#details-play-button").attr "href", "#book-player?book=#{details.id}"
    loadCover view.find("img.cover-image"), details.id
    
  
  bookIndex: (book, view) ->  
    playing = LYT.player.getCurrentlyPlaying()
    isPlaying = (sectionId) ->
      return false unless playing? and String(book.id) is String(playing?.book)
      return true if String(playing.section) is String(sectionId)
      return false
    
    # Recursively builds nested ordered lists from an array of items
    mapper = (list, items) ->
      for item in items
        element = jQuery """<li data-icon="arrow-right"></li>""" 
        element.attr "id", item.id
        element.attr "data-href", item.id
        
        if item.children.length > 0
          element.append "<span>#{item.title}</span>"
        else
          element.append """
            <a class="gatrack" ga-action="Link" data-ga-book-id="#{book.id}" data-ga-book-title="#{(item.title or '').replace '"', ''}" href="#book-play?book=#{book.id}&section=#{item.url}&autoplay=true"> 
              #{item.title}
            </a>"""
        
        if isPlaying item.id
          element.append """<div class="section-now-playing"></div>"""
        
        if item.children.length > 0
          nested = jQuery "<ol></ol>"
          mapper nested, item.children
          element.append nested
        list.append element
        
    # Create an ordered list wrapper for the list
    view.children().remove()
    list = $('<ol data-role="listview"></ol>').hide()
    view.append list
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NccRootElement"
    # FIXME: We should be using the playlist here - any reference to NCC- or
    # SMIL documents from this class is not good design.
    mapper(list, book.nccDocument.structure)
    
    list.parent().trigger('create')
    list.show()
 
  
  bookmarks: (book, view) ->  
    # Create an ordered list wrapper for the list
    view.children().remove()
    list = $('<ul data-role="listview" data-split-theme="d" data-split-icon="lyt-more"></ul>').hide()
    view.append list
    list.attr "data-title", book.title
    list.attr "data-author", book.author
    list.attr "data-totalTime", book.totalTime
    list.attr "id", "NccRootElement"
    
    generateMoreItem = (bookmark, index) ->

      more = $('<a href="#">Mere</a>')
      more.on 'click', ->
        listItem = more.parents 'li'
        list.find('.bookmark-actions').remove()
        list.find('.active').removeClass('active')
        listItem.addClass 'active'
        share  = $('<div class="ui-block-a bookmark-share" title="Del">&nbsp;</div>')
        remove = $('<div class="ui-block-b bookmark-delete" title="Slet">&nbsp;</div>')
        share.on 'click', ->
          [section, segment] = bookmark.URI.split '#'
          reference =
            book:    book.id
            section: section
            segment: segment
          jQuery.mobile.changePage LYT.router.getBookActionUrl(reference, 'share') + "&title=#{book.title}"
        remove.on 'click', ->
          book.bookmarks.splice index, 1
          book.saveBookmarks()
          LYT.render.bookmarks book, view
        actionsItem = $('<li class="bookmark-actions"><div class="ui-grid-a"></div></li>')
        actionsItem.find('div').append(share, remove)
        listItem.after actionsItem
        list.listview('refresh')
      return more
    
    # if book.bookmarks is empty -> display message
    if book.bookmarks.length is 0
      element = jQuery "<li></li>"
      element.append LYT.i18n("No bookmarks defined yet")
      list.append element
    else
      for bookmark, index in book.bookmarks
        element = jQuery "<li></li>" 
        element.attr "id", bookmark.id
        element.attr "data-href", bookmark.id
        [baseUrl, id] = bookmark.URI.split('#')
        element.append """
            <a class="gatrack" ga-action="Link" data-ga-book-id="#{book.id}" data-ga-book-title="#{(bookmark.note?.text or '').replace '"', ''}" href="#book-play?book=#{book.id}&section=#{baseUrl}&segment=#{id}&offset=#{bookmark.timeOffset}&autoplay=true"> 
              #{bookmark.note.text}
            </a>
          """
        element.append generateMoreItem(bookmark, index)
        list.append element

    list.parent().trigger('create')
    list.show()
 

  searchResults: (results, view) ->
    list = view.find "ul"
    list.empty() if results.currentPage is 1 or results.currentPage is undefined

    if results.length is 0
      list.append jQuery "<li><h3 class='no-search-results'>#{LYT.i18n("No search results")}</h3></li>"
    else
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
        listItem = jQuery """<li id="#{query.id}" data-icon="arrow-right"><a href="#"><h3>#{LYT.i18n query.title}</h3></a></li>"""
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
      $("#current-user-name").text LYT.i18n('guest')
    else 
      $("#current-user-name").text LYT.session.getInfo().realname


  showDialog: (parent, parameters) ->
    LYT.loader.clear
    parent.simpledialog parameters

    # simpleDialog does not have aria labels on the output elements, so screenreaders has
    # no chance of finding out what the dialog is saying without going into advanced 
    # formular or cursor modes (usually not used by not-so-advanced users)
    #
    # Modify the created ui-simpledialog-container so that the screenreader knows this is an alert
    $(".ui-simpledialog-container").attr 'role', 'alert'
    $(".ui-simpledialog-header h4").attr 'role', 'alert'
    $(".ui-simpledialog-subtitle").attr 'role', 'alert'

  setPlayerButtonFocus: (button) ->
    $(".jp-#{button}").addClass('ui-btn-active').focus()


