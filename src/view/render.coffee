# Requires `/common`
# Requires `/controllers/player`
# Requires `/models/member/settings`

# -------------------

# This module handles gui callbacks and various utility functions
#console.log 'Load LYT.render'

LYT.render = do ->

  # ## Privileged API

  setupSettingsPopup = () ->
    popup = $(
      "<div class='settings-popup' role='alert'>" +
        "<div class='settings-popup-arrow'></div>" +
        "<div class='settings-popup-message'>" +
          "<div data-role='fieldcontain'>" +
            "<fieldset data-role='controlgroup' id='font-size' data-type='horizontal'>" +
              "<legend>Tekststørrelse</legend>" +
              "<button id='fontsize_dec_button'>a</button>" +
              "<button id='fontsize_inc_button'>A</button>" +
            "</fieldset>" +
          "</div>" +

      "<div data-role='fieldcontain'>" +
        "<fieldset data-role='controlgroup' id='font-family'>" +
          "<legend>Skrifttype</legend>" +
          "<input type='radio' name='font-family' id='font-family-1' value='Georgia, serif'/>" +
          "<label class='gatrack' style='font-family:Georgia, serif;' for='font-family-1' title='Klassisk skrifttype'>Klassisk</label>" +

          "<input type='radio' name='font-family' id='font-family-2' value='Helvetica, sans-serif'/>" +
          "<label class='gatrack' style='font-family:Helvetica, sans-serif;' for='font-family-2' title='Moderne skrifttype'>Moderne</label>" +
          "<input type='radio' name='font-family' id='font-family-3' value='Dyslexic, sans-serif'/>" +
          "<label class='gatrack' style='font-family:Dyslexic, sans-serif;' for='font-family-3' title='Dyslexia skrifttype'>OpenDyslexic</label>" +

        "</fieldset>" +
      "</div>" +

      "<div data-role='fieldcontain'>" +
        "<fieldset data-role='controlgroup' id='marking-color'>" +
          "<legend>Farver</legend>" +
          "<input type='radio' name='marking-color' id='radio-choice-g' value='#fff;#000000'/>" +
          "<label class='gatrack' for='radio-choice-g' title='Sort på hvid'>Sort på hvid</label>" +
          "<input type='radio' name='marking-color' id='radio-choice-h' value='#000000;#FFF800'/>" +
          "<label class='gatrack' for='radio-choice-h' title='Gul på sort'>Gul på sort</label>" +

          "<input type='radio' name='marking-color' id='radio-choice-i' value='#FFF800;#000000'/>" +
          "<label class='gatrack' for='radio-choice-i' title='Sort på gul'>Sort på gul</label>" +

          "<input type='radio' name='marking-color' id='radio-choice-j' value='#ffffff;#0000ff'/>" +
          "<label class='gatrack' for='radio-choice-j' title='Blå på hvid'>Blå på hvid</label>" +
        "</fieldset>" +
      "</div>" +

      "<div id='playback-rate' data-role='fieldcontain'>" +
        "<fieldset data-role='controlgroup' data-type='horizontal'>" +
          "<legend>Afspilningshastighed</legend>" +
          "<input type='radio' name='playback-rate' id='playback-rate-1' value='0.5'/>" +
          "<label class='gatrack' for='playback-rate-1' aria-label='Langsomst'>" +
            "<span style='font-size:16px'>&#188;</span>" +
          "</label>" +

          "<input type='radio' name='playback-rate' id='playback-rate-2' value='0.8'/>" +
          "<label class='gatrack' for='playback-rate-2' aria-label='Langsommere'>" +
            "<span style='font-size:16px'>&#189;</span>" +
          "</label>" +

          "<input type='radio' name='playback-rate' id='playback-rate-3' value='1'/>" +
          "<label class='gatrack' for='playback-rate-3' aria-label='Normalt'>" +
            "<span style='font-size:16px'><b>1</b></span>" +
          "</label>" +

          "<input type='radio' name='playback-rate' id='playback-rate-4' value='1.5'/>" +
          "<label class='gatrack' for='playback-rate-4' aria-label='Hurtigere'>" +
            "<span style='font-size:16px'>2</span>" +
          "</label>" +

          "<input type='radio' name='playback-rate' id='playback-rate-5' value='2'/>" +
          "<label class='gatrack' for='playback-rate-5' aria-label='Hurtigst'>" +
            "<span style='font-size:16px'>3</span>" +
          "</label>" +
        "</fieldset>" +

        "<p style='display:none' class='message disabled'>Denne browser understøtter ikke variabel afspilningshastighed.</p>" +
      "</div>" +

        "</div></div>"
    )

    $('body').append popup
    popup.trigger 'create'

    # Setup color icons
    labels = $('label[for=radio-choice-g], label[for=radio-choice-h],' +
      'label[for=radio-choice-i], label[for=radio-choice-j]', popup)

    icons = ['black-white', 'yellow-black', 'black-yellow', 'blue-white']
    labels.each (index) ->
      $(@).find('.ui-btn-inner').append(
        "<span class='ui-icon ui-icon-" + icons[index] + " settings-color-icon'>&nbsp;</span>"
      )


    arrow = $('.settings-popup-arrow', popup)

    element = $('#settings-button')
    elOffset = element.offset()
    elWidth = element.width()
    elHeight = element.height()
    wWidth = $(window).width()

    # -7 is half the arrow width
    arrow.css 'right', wWidth - elOffset.left - elWidth / 2 - 7

    popup.css 'right', 0
    popup.css 'top', element.offset().top + element.height()

    popup.hide()

  closeSettingsPopup = () ->
    popup = $('div.settings-popup')
    if !popup.length then popup = setupSettingsPopup()
    popup.fadeOut()

  openSettingsPopup = () ->
    popup = $('div.settings-popup')
    if !popup.length then popup = setupSettingsPopup()
    popup.fadeIn()

  updateSettingsPopup = (style) ->
    popup = $('div.settings-popup')
    popup.find("input").each ->
      el = $(this)
      name = el.attr 'name'
      val = el.val()

      # Setting the GUI
      switch name
        when 'font-size', 'font-family'
          el.attr("checked", val is style[name]).checkboxradio("refresh")
        when 'marking-color'
          colors = val.split(';')
          if style['background-color'] is colors[0] and style['color'] is colors[1]
            el.attr("checked", true).checkboxradio("refresh")
          else
            el.attr("checked", false).checkboxradio("refresh")
        when 'playback-rate'
          isThis = Number(val) is LYT.settings.get 'playbackRate'
          el.attr("checked", isThis).checkboxradio("refresh")
        when 'word-highlighting'
          el.prop("checked", LYT.settings.get("wordHighlighting"))
            .checkboxradio("refresh")




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

  setSelectSectionEvent = (list) ->
    # event for opening a section/bookmark in a given book
    list.on 'click', '.section-link', (e) ->
      # A section/bookmark link was clicked, skip to that section in the book
      el = $(e.target)
      book = "#{el.data 'book'}"

      # Not the same book, just return
      unless book and book is LYT.player.book?.id
        log.message "LYT.render: setSelectSectionEvent: not the current book #{book} isn't #{LYT.player.book?.id}"
        return

      smilReference = el.data 'smil'
      if fragment = el.data 'fragment'
        smilReference += "##{fragment}"

      if segment = el.data 'segment'
        smilReference += "##{segment}"

      if offset = el.data 'offset'
        offset = LYT.utils.parseTime(offset)
      else
        offset = null

      # TODO: Workout why LYT.player.load won't respect play == true from here
      progress = LYT.player.load LYT.player.book?.id, smilReference, offset, true
      progress.done ->
        # TODO: For some reason LYT.player.load() won't respect play === true from this event
        # I assume it has something to do with the bookPlayer controller.
        LYT.player.stop().then ->
          LYT.player.play()

  # ---------------------------

  # ## Public API

  bubbleNotification: bubbleNotification

  setupSettingsPopup: setupSettingsPopup
  openSettingsPopup: openSettingsPopup
  closeSettingsPopup: closeSettingsPopup
  updateSettingsPopup: updateSettingsPopup

  init: ->
    log.message 'Render: init'
    @setStyle()
    @setInfo()

  setStyle: ->
    log.message 'Render: setting custom style'
    textStyle = LYT.settings.get 'textStyle'
    # TODO: Dynamic modification of a CSS class in stead of this
    $('#textarea-example, #book-context-content, #book-plain-content').css textStyle

    # Update settings view
    updateSettingsPopup textStyle

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

  bookmarkAddedNotification: -> LYT.render.bubbleNotification $('#bookmark-add-button'), 'Bogmærke tilføjet', 5

  disablePlaybackRate: ->
    # Wait with disabling until it's actually created
    $playbackRate = $('#playback-rate')
    $playbackRate.find('.message.disabled').show()
    $playbackRate
      .find('input[type="radio"]').on( 'checkboxradiocreate', ->
        $(this).checkboxradio('disable')
      ).each ->
        el = $(this)
        if el.data('mobileCheckboxradio')?
          el.checkboxradio('disable')
        else
          el.prop('disabled',true)

  clearBookPlayer: ->
    @clearTextContent()
    $('#player-book-title').text ''
    $('#player-book-author').text ''
    $('.player-book-info h1 .player-book-title-author, .player-chapter-title').hide()
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
    $('#book-play-menu').find('a').add('#book-index-button,#bookmark-add-button').removeClass 'ui-disabled'

  disablePlayerNavigation: ->
    $('#book-play-menu').find('a').add('#book-index-button,#bookmark-add-button').addClass 'ui-disabled'

  isPlayerNavigationEnabled: ->
    $.makeArray($('#book-play-menu').find('a').add('#book-index-button,#bookmark-add-button')).some (el) ->
      !$(el).hasClass 'ui-disabled'

  bookPlayer: (book, view) ->
    $('#player-book-title').text book.title
    $('#player-book-author').text book.author
    $('.player-book-info h1 .player-book-title-author, .player-chapter-title').show()
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

  bookIndex: (book) ->
    # FIXME: We should be using asking the book for a TOC, not the NCC directly
    # since this is a sign of lack of decoupling
    @createbookIndex book.nccDocument.structure, book

  activeIndexSection: (section) ->
    list = $('#toc-list')
    list.find('.section-now-playing').remove()

    sectionEl = $("a[data-fragment='#{section.fragment}']", list)
    sectionEl.parent().append """<div class="section-now-playing"></div>"""

  createbookIndex: (items, book) ->
    list = $('#toc-list')
    if list.data('book') is book.id
      return

    curSection = LYT.player.currentSection()
    curParentID = curSection.id.substr 0, curSection.id.search /(\.\d$)|$/

    isPlaying = (item) ->
      return unless String(book.id) is String(LYT.player.book.id)
      return unless item.ref is curSection.ref or curParentID is item.id
      return true

    sectionLink = (section) ->
      title = section.title?.replace("\"", "") or ""

      """
      <a
        class="gatrack section-link"
        ga-action="Link"
        data-book="#{book.id}"
        data-smil="#{section.url}"
        data-fragment="#{section.fragment}"
        data-ga-book-id="#{book.id}"
        data-ga-book-title="#{title}"
        href="#book-player?book=#{book.id}">
          #{title}
      </a>
      """

    renderList = (items, list) ->
      for item in items
        li = jQuery '<li></li>'
        content = jQuery '<div class="listitem-content"></div>'
        content.append sectionLink item

        if isPlaying item
          content.append """<div class="section-now-playing"></div>"""

        li.append content

        if item.children.length > 0
          li.append renderList item.children, $('<ul></ul>')

        list.append li

      return list

    list.data 'book', book.id
    list.children().remove()

    renderList items, list
    setSelectSectionEvent list


  bookmarks: (book, rerender) ->
    list = $('#bookmark-list')
    if list.data('book') is book.id and not rerender
      return

    list.data 'book', book.id
    list.children().remove()

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
            <a
              class="gatrack section-link"
               data-ga-action="Link"
               data-ga-book-id="#{book.id}"
               data-book="#{book.id}"
               data-smil="#{baseUrl}"
               data-segment="#{id}"
               data-offset="#{LYT.utils.formatTime bookmark.timeOffset}"
               href="#book-player?book=#{book.id}">
              #{bookmark.note?.text or bookmark.timeOffset}
            </a>
          """
        list.append element

    setSelectSectionEvent list

  setHeader: (page, text) ->
    header = $(page).children(':jqmData(role=header)').find('h1')
    header.text LYT.i18n text

  setPageTitle: (title) ->
    document.title = "#{title} | #{LYT.i18n('Sitename')}"

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
