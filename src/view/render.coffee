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
  defaultCover = '/images/icons/default-cover.png'

  # Create a book list-item which links to the `target` page
  bookListItem = (target, book, from = "") ->
    info = []
    info.push book.author if book.author?
    info.push getMediaType(book.media) if book.media?
    info = info.join '&nbsp;&nbsp;|&nbsp;&nbsp;'
    from = "&from=#{from}" if from isnt ""

    if book.id is LYT.player.book?.id
      nowPlaying = '<div class="book-now-playing"></div>'

    title = book.title?.replace /\"/g, ""
    element = jQuery """
      <li data-book-id="#{book.id}">
        <a class="gatrack book-play-link" data-ga-action="Vælg" ga-book-id="#{book.id}" ga-book-title="#{(book.title or '').replace '"', ''}" href="##{target}?book=#{book.id + from}">
          <div class="cover-image-frame">
            <img class="ui-li-icon cover-image" role="presentation"">
          </div>
          <h3>#{book.title or "&nbsp;"}</h3>
          <p>#{info or "&nbsp;"}</p>
          #{nowPlaying or ""}
        </a>
      </li>
      """

    if String(target) is 'book-details'
      element.attr 'data-icon', 'arrow_icn'

    loadCover element.find('img.cover-image'), book.id

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
    img.attr 'src', "http://bookcover.e17.dk/#{imageid}_h200.jpg"


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
          prompt:              LYT.i18n('You are logged on as guest and hence can not remove books')
          subTitle:            LYT.i18n('')
          animate:             false
          useDialogForceFalse: true
          useModal:            true
          buttons:             {}
        parameters.buttons[LYT.i18n('OK')] =
          click: ->
          theme: 'c'
        LYT.render.showDialog($(this), parameters)
      else
        parameters =
          mode:                'bool'
          prompt:              LYT.i18n('Delete this book?')
          subTitle:            book.title
          animate:             false
          useDialogForceFalse: true
          useModal:            true
          buttons:             {}
        parameters.buttons[LYT.i18n('Remove book')] =
          click: -> LYT.bookshelf.remove(book.id).done -> list.remove()
          id:    'ok-btn'
          theme: 'c'
        parameters.buttons[LYT.i18n('Cancel')] =
          click: ->
          id:    'cancel-btn'
          theme: 'c'
        LYT.render.showDialog($(this), parameters)


  # Displays a small speech bubble notification vertOffset pixels below the
  # provided element containing the provided text for timeout milliseconds.
  # If timeout provided is zero, the bubble will display until the user clicks
  # it. Timeout defaults to 5000.
  # Returns a function that will remove the notification when called.
  bubbleNotification = (element, text, vertOffset=0, timeout) ->
    notification = $("<div class=\"bubble-notification\" role=\"alert\"><div class=\"bubble-notification-arrow\"></div><div class=\"bubble-notification-message\">#{text}</div></div>")
    # We set visibility to hidden and attach it to body in order to measure the width
    notification.css 'visibility', 'hidden'
    $('body').append notification
    notification.css 'left', element.offset().left - notification.width()/2 + element.width()/2
    notification.css 'top', element.offset().top + element.height() + vertOffset
    notification.hide()
    notification.css 'visibility', ''
    notification.fadeIn()
    remove = ->
      notification.removeAttr('role')
      notification.fadeOut ->
        notification.remove()
    if timeout == 0
      notification.on 'click', remove
    else
      setTimeout(remove, timeout or 5000)
    remove

  # ---------------------------

  # ## Public API

  bubbleNotification: bubbleNotification

  init: ->
    log.message 'Render: init'
    @setStyle()
    @setInfo()

  setStyle: ->
    log.message 'Render: setting custom style'
    # TODO: Dynamic modification of a CSS class in stead of this
    $('#textarea-example, #book-context-content, #book-plain-content').css(
      LYT.settings.get('textStyle')
    )

    # Set word highlighting if appropriate
    LYT.render.setHighlighting LYT.settings.get('wordHighlighting')

  setHighlighting: (highlight) ->
    # Set highlight on by default
    if not highlight?
      LYT.settings.set 'wordHighlighting', true
      highlight = true

    viewer = $('#book-context-content')
    if viewer.hasClass 'word-highlight'
      viewer.removeClass 'word-highlight' if not highlight
    else
      viewer.addClass 'word-highlight' if highlight

  setInfo: ->
    $('.lyt-version').html LYT.VERSION
    $('.current-year').html (new Date()).getFullYear()

  bookmarkAddedNotification: -> LYT.render.bubbleNotification $('#book-index-button'), 'Bogmærke tilføjet', 5

  bookshelf: (books, view, page, zeroAndUp) ->
    #todo: add pagination
    list = view.find('ul')
    list.empty() if page is 1 or zeroAndUp

    for book in books
      li = bookListItem 'book-player', book, 'bookshelf'
      removeLink = jQuery """<a class="remove-book" href="#">#{LYT.i18n('Remove')} #{book.title}</a>"""
      attachClickEvent removeLink, book, li
      li.append removeLink
      list.append li

    # if the list i empty -> bookshelf is empty -> show icon...
    if(list.length is 1)
      $('.bookshelf-content').css('background', 'transparent url(../images/icons/empty_bookshelf.png) no-repeat')

    list.listview('refresh')
    list.find('a').first().focus()

  loadBookshelfPage: (content, page = 1, zeroAndUp = false) ->
    process = LYT.bookshelf.load(page, zeroAndUp)
    .done (books) ->
      LYT.render.bookshelf(books, content, page, zeroAndUp)
      if books.nextPage
        $('#more-bookshelf-entries').show()
      else
        $('#more-bookshelf-entries').hide()

    .fail (error, msg) ->
      log.message "failed with error #{error} and msg #{msg}"


    LYT.loader.register 'Loading bookshelf', process

  disablePlaybackRate: ->
    # Wait with disabling until it's actually created
    $playbackRate = $('#playback-rate')
    $playbackRate.find('.message.disabled').show()
    $playbackRate
      .find('input[type="radio"]').on( 'checkboxradiocreate', ->
        $(@).checkboxradio('disable')
      ).each ->
        el = $(@)
        if el.data('mobileCheckboxradio')?
          el.checkboxradio('disable')
        else
          el.prop('disabled',true)

  hideOrShowButtons: (details) ->
    if details.state is LYT.config.book.states.pending
      $('#book-unavailable-message').show()
      $('#add-to-bookshelf-button').hide()
      $('#details-play-button').hide()
    else
      $('#book-unavailable-message').hide()
      if(LYT.session.getCredentials().username is LYT.config.service.guestLogin) #Guest login
        $('#add-to-bookshelf-button').hide()
        $('#details-play-button').hide()
      else
        $('#add-to-bookshelf-button').show()
        $('#details-play-button').show()

  clearBookPlayer: (view) ->
    @clearTextContent()
    $('#player-book-title').text ''
    $('#player-book-author').text ''
    $('#currentbook-image img').attr 'src', defaultCover
    $('#player-info h1, .player-chapter-title').hide()
    @disablePlayerNavigation()

  clearContent: (content) ->
    list = content.children 'ol, ul'
    if list.length and list.hasClass 'ui-listview'
      if list.listview('childPages').length > 0
        list.listview('childPages').remove()
        list.listview 'refresh'
      else
        list.listview().children().remove()

  enablePlayerNavigation: ->
    $('#book-play-menu').find('a').removeClass 'ui-disabled'

  disablePlayerNavigation: ->
    $('#book-play-menu').find('a').addClass 'ui-disabled'

  bookPlayer: (book, view) ->
    $('#player-book-title').text book.title
    $('#player-book-author').text book.author
    $('#player-info h1, .player-chapter-title').show()
    loadCover $('#currentbook-image img'), book.id
    @enablePlayerNavigation()

  showAnnouncements: (announcements) ->
    #for announcement in announcements
     # if announcement.text?
       # alert announcement.text #Stops processing of javascript (alert)...

    #LYT.service.markAnnouncementsAsRead(announcements)


  bookEnd: () -> LYT.render.content.renderText LYT.i18n('The end of the book')

  clearTextContent: -> LYT.render.content.renderSegment()

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
    media = $('#details-book-media span')
    media.removeClass()
    if details.media is 'AA'
      media.addClass 'ui-icon-audiobook'
    else if details.media is 'AT'
      media.addClass 'ui-icon-audiobook_text'
    media.text details.mediaString

    $('#details-book-title').text details.title
    $('#details-book-author').text details.author
    $('#details-book-description').text details.teaser
    $('#details-book-narrator').text details.speaker
    $('#details-book-totaltime').text "#{details.playtime}:00"
    $('#details-book-pubyear').text details.pubyear or ''
    $('#add-to-bookshelf-button').attr 'data-book-id', details.id
    $('#details-play-button').attr 'href', "#book-player?book=#{details.id}"
    loadCover view.find('img.cover-image'), details.id


  bookIndex: (book, view) ->
    # FIXME: We should be using asking the book for a TOC, not the NCC directly
    # since this is a sign of lack of decoupling
    @createbookIndex book.nccDocument.structure, view, book


  createbookIndex: (items, view, book, root = null) ->
    curSection = LYT.player.currentSection()
    curParentID = curSection.id.substr 0, curSection.id.search /(\.\d$)|$/

    isPlaying = (item) ->
      return unless String(book.id) is String(LYT.player.book.id)
      return unless item.ref is curSection.ref or curParentID is item.id
      return true

    sectionLink = (section, play = 'true') ->
      title = section.title?.replace("\"", "") or ""
      link = "smil=#{section.url}"
      if section.fragment
        link += "&fragment=#{section.fragment}"

      "<a class=\"gatrack\" ga-action=\"Link\" " +
      "data-ga-book-id=\"#{book.id}\" data-ga-book-title=\"#{title}\" " +
      "href=\"#book-player?book=#{book.id}&#{link}" +
      "&play=#{play}\">#{title}</a>"

    $('#index-back-button').removeAttr 'nodeid'

    if root?.title?
      $('#index-back-button').attr 'nodeid', String(root.parent)

    view.children().remove()
    list = $('<ul data-role="listview" data-split-theme="a"></ul>').hide()
    view.append list
    list.attr 'data-title', book.title
    list.attr 'data-author', book.author
    list.attr 'data-totalTime', book.totalTime
    list.attr 'id', 'NccRootElement'

    for item in items
      if item.children.length > 0
        element = jQuery '<li data-icon="arrow_icn"></li>'
        element.append sectionLink item
        element.append """<a nodeid="#{item.id}" class="create-listview subsection">underafsnit</a>"""
      else
        element = jQuery '<li data-icon="false"></li>'
        element.append sectionLink item
        element.attr 'id', item.id
        element.attr 'data-href', item.id

      if isPlaying item
        element.append """<div class="section-now-playing"></div>"""

      list.append element

    list.parent().trigger('create')
    list.show()


  bookmarks: (book, view) ->
    # Create an ordered list wrapper for the list
    view.children().remove()
    list = $('<ol data-role="listview" data-split-theme="d" data-split-icon="more_icn"></ol>').hide()
    view.append list
    list.attr 'data-title', book.title
    list.attr 'data-author', book.author
    list.attr 'data-totalTime', book.totalTime
    #list.attr 'id', 'NccRootElement'

    generateMoreItem = (bookmark, index) ->
      more = $('<a class="subsection" href="#">Mere</a>')
      more.on 'click', ->
        listItem = more.parents 'li'
        list.find('.bookmark-actions').remove()
        list.find('.bookmark-indents').remove()
        list.find('.active').removeClass('active')
        listItem.addClass 'active'
        share  = $('<div class="ui-block-a bookmark-share" title="Del" data-role="button" role="button">&nbsp;</div>')
        remove = $('<div class="ui-block-b bookmark-delete" title="Slet" data-role="button" role="button">&nbsp;</div>')
        share.on 'click', ->
          [smil, segment] = bookmark.URI.split '#'
          reference =
            book: book.id
            smil: smil
            segment: segment
            offset: bookmark.timeOffset
          jQuery.mobile.changePage LYT.router.getBookActionUrl(reference, 'share') + "&title=#{book.title}"
        remove.on 'click', ->
          book.bookmarks.splice index, 1
          book.saveBookmarks()
          LYT.render.bookmarks book, view
        actionsItem = $('<ul class="bookmark-indents"><li class="bookmark-actions"><div class="ui-grid-a"></div></li></ul>')
        actionsItem.find('div').append(share, remove)
        listItem.after actionsItem
        list.listview('refresh')
      return more

    # if book.bookmarks is empty -> display message
    if book.bookmarks.length is 0
      element = jQuery '<li></li>'
      element.append LYT.i18n('No bookmarks defined yet')
      list.append element
    else
      for bookmark, index in book.bookmarks
        element = jQuery '<li></li>'
        element.attr 'id', bookmark.id
        element.attr 'data-href', bookmark.id
        [baseUrl, id] = bookmark.URI.split('#')
        element.append """
            <a class="gatrack" data-ga-action="Link" data-ga-book-id="#{book.id}"
               href="#book-player?book=#{book.id}&smil=#{baseUrl}&segment=#{id}&offset=#{LYT.utils.formatTime bookmark.timeOffset}&play=true">
              #{bookmark.note?.text or bookmark.timeOffset}
            </a>
          """
        element.append generateMoreItem(bookmark, index)
        list.append element

    list.parent().trigger('create')
    list.show()


  searchResults: (results, view) ->
    list = view.find 'ul'
    list.empty() if results.currentPage is 1 or results.currentPage is undefined

    if results.length is 0
      list.append jQuery """"<li><h3 class="no-search-results">#{LYT.i18n('No search results')}</h3></li>"""
    else
      list.append bookListItem('book-details', result) for result in results

    if results.loadNextPage?
      $('#more-search-results').show()
    else
      $('#more-search-results').hide()

    $('#listshow-btn').show()#show button list
    list.listview('refresh')
    view.children().show()


  # TODO: Simple, rough implementation
  catalogLists: (view) ->
    list = view.find 'ul'
    list.empty()

    for key, value of LYT.predefinedSearches
      listItem = jQuery """<li id="#{key}" data-icon="arrow_icn">
                           <a href="##{value.hash}?#{value.param}=#{key}" class="ui-link-inherit">
                           <h3 class="ui-li-heading">#{LYT.i18n value.title}</h3></a></li>"""
      list.append listItem
    list.listview('refresh')
    view.children().show()

  setHeader: (page, text) ->
    header = $(page).children(':jqmData(role=header)').find('h1')
    header.text LYT.i18n text

  setPageTitle: (title) ->
    document.title = "#{title} | #{LYT.i18n('Sitename')}"

  showDidYouMean: (results, view) ->
    list = view.find 'ul'
    list.empty()

    list.append jQuery '<li data-role="list-divider" role="heading">Mente du?</li>'

    for item in results
      listItem = didYouMeanItem(item)
      listItem.find('a').click (event) ->
        $.mobile.changePage "#search?term=#{encodeURI item}" , transition: 'none'
      list.append listItem

    $('#listshow-btn').show()#show button list
    list.listview('refresh')


  profile: () ->
    if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
      $('#current-user-name').text LYT.i18n('guest')
    else
      $('#current-user-name').text LYT.session.getInfo().realname


  showDialog: (parent, parameters) ->
    LYT.loader.clear()
    parent.simpledialog parameters

    # simpleDialog does not have aria labels on the output elements, so screenreaders has
    # no chance of finding out what the dialog is saying without going into advanced
    # formular or cursor modes (usually not used by not-so-advanced users)
    #
    # Modify the created ui-simpledialog-container so that the screenreader knows this is an alert
    $('.ui-simpledialog-container').attr 'role', 'alert'
    $('.ui-simpledialog-header h4').attr 'role', 'alert'
    $('.ui-simpledialog-subtitle').attr 'role', 'alert'

  showTestTab: -> $('.test-tab').show()

  hideTestTab: -> $('.test-tab').hide()

  instrumentationGraph: ->
    $('#instrumentation').find('svg.graph-canvas').data('lyt-graph')

  showInstrumentation: (view) ->
    view.children().detach()

    fields = LYT.instrumentation.fieldInfo()

    colors = [
      'Blue'
      'BlueViolet'
      'Brown'
      'BurlyWood'
      'CadetBlue'
      'Chartreuse'
      'Chocolate'
      'Coral'
      'CornflowerBlue'
      'Crimson'
      'Cyan'
      'DarkBlue'
      'DarkCyan'
      'DarkGoldenRod'
      'DarkGreen'
      'DarkKhaki'
      'DarkMagenta'
      'DarkOliveGreen'
      'Darkorange'
      'DarkOrchid'
      'DarkRed'
    ]

    canvasHeight   = 0.25
    canvasWidth    = 1
    timelineHeight = 0.03
    timelineMargin = 0.01

    i = 0
    for key, fieldInfo of fields
      fieldInfo.color = colors[i++]
      i = i % colors.length

    mapValue = (key, value) ->
      fieldInfo = fields[key]
      # TODO string types
      scale = if key is 'delta' then canvasWidth else canvasHeight - timelineHeight - timelineMargin
      scale * if not value?
        NaN
      else if not fieldInfo.type
        NaN
      else if fieldInfo.type is 'number'
        if fieldInfo.domain.max is fieldInfo.domain.min
          0.5
        else
          result = (value - fieldInfo.domain.min) / (fieldInfo.domain.max - fieldInfo.domain.min)
          if key is 'delta' then result else 1 - result
      else if fieldInfo.type is 'boolean'
        if value then 0 else 1
      else
        NaN # Everything else

    # Chrome doesn't render the svg items if the DOM is manipulated, so
    # everything is built up as one large string
    svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" class=\"graph-canvas\" viewBox=\"0 0 #{canvasWidth} #{canvasHeight}\">"

    graph =
      fields: fields
      entries: {}

      saveEntry: (entry) ->
        @entries[entry.event.delta.toString()] = entry

      getEntry: (delta) ->
        @entries[delta.toString()]

      nextEntry: ->
        @highlight @currentEntry.next if @currentEntry.next

      previousEntry: ->
        @highlight @currentEntry.previous if @currentEntry.previous

      firstEntry: ->
        @currentEntry = @currentEntry.previous while @currentEntry.previous?
        @highlight @currentEntry

      lastEntry: ->
        @currentEntry = @currentEntry.next while @currentEntry.next?
        @highlight @currentEntry

      # Highlight an entry
      # Input: delta timestamp (as Number or String) or an entry
      highlight: (data) ->
        entry = if typeof data is 'object' then data else @getEntry data
        if entry?
          @currentEntry = entry
        else
          log.errorGroup "Render: showInstrumentation: can't highlight this: ", data
        $('#instrumentation-delta').html entry.description
        # TODO: We should do $('svg.graph-canvas').children('.delta-marker')
        #       but it doesn't work in Chrome
        # TODO: We should use addClass and removeClass, but this doesn't work
        #       in Chrome.
        $('.delta-marker').attr 'class', 'delta-marker'
        $("#delta-marker-#{entry.event.delta}").attr 'class', 'delta-marker highlight'

    makePolyLine = (key, coords) -> "<polyline id=\"line-#{key}\" class=\"graph-line\" stroke=\"#{fields[key].color}\" points=\"#{coords}\"></polyline>"

    polyLines    = {}
    polyLinesStr = ''
    circles      = ''
    deltaMarkers = ''

    lastEntry = null
    LYT.instrumentation.iterateObjects (event) ->
      entry =
        description: "delta: #{event.delta}<br/>"
        event: event
      if lastEntry
        entry.previous = lastEntry
        lastEntry.next = entry
      lastEntry = entry
      deltaMarkers += "<polyline id=\"delta-marker-#{event.delta}\" class=\"delta-marker\" stroke=\"blue\" points=\"#{mapValue 'delta', event.delta},0 #{mapValue 'delta', event.delta},1\"></polyline>"
      deltaMarkers += "<rect class=\"delta-timeline-marker\" fill=\"blue\" stroke=\"none\" width=\"0.01\" height=\"#{timelineHeight}\" x=\"#{mapValue('delta', event.delta) - 0.005}\" y=\"#{canvasHeight - timelineHeight}\"></rect>"
      for key, value of event
        continue if key is 'delta'
        entry.description += "#{key}: #{event[key]}<br/>"
        continue if fields[key].type isnt 'number'
        mappedValue = mapValue key, value
        if isNaN mappedValue
          delete polyLines[key]
        else
          polyLines[key] or= ''
          polyLines[key] += "#{mapValue 'delta', event.delta},#{mappedValue} "
          circles        += "<circle data-point=\"(delta, #{key}): (#{event.delta}, #{value})\" data-delta=\"#{event.delta}\" class=\"graph-point point-#{key}\" cx=\"#{mapValue 'delta', event.delta}\" cy=\"#{mappedValue}\" r=\"0.005\" stroke=\"none\" stroke-width=\"2\"></circle>"
      graph.saveEntry entry
      graph.currentEntry or= entry

    polyLinesStr += makePolyLine key, coords for key, coords of polyLines

    svg += "<polyline stroke=\"none\" fill=\"#CCC\" points=\"0,#{canvasHeight} #{canvasWidth},#{canvasHeight} #{canvasWidth},#{canvasHeight - timelineHeight} 0,#{canvasHeight - timelineHeight} 0,#{canvasHeight}\"></polyline>"
    svg += polyLinesStr
    svg += circles
    svg += deltaMarkers
    svg += '</svg>'
    view.append svg

    $('svg.graph-canvas').data 'lyt-graph', graph

    $('circle.graph-point').each (i, elt) ->
      element = $(elt)
      remove = null
      element.hover(
        -> remove = LYT.render.bubbleNotification $(this), $(this).attr('data-point'), 5, 0
        -> remove?()
      )

    $('circle.graph-point').click -> graph.highlight $(this).attr 'data-delta'

    graph.highlight graph.currentEntry if graph.currentEntry
