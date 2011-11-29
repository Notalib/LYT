# This module serves as a router to the rest of the application and contains url entrypoints and event listeners

$(document).ready ->
  LYT.player.setup()

$(document).bind "mobileinit", ->
  
  $(LYT.service).bind "logon:rejected", () ->
    $.mobile.changePage "#login"
  
  $(LYT.service).bind "error:rpc", () ->
    #$.mobile.changePage "#login"  
  
  $(document).bind "pagebeforechange", (e, data) ->
      # Intercept and parse urls with a query string
      # As done here http://jquerymobile.com/test/docs/pages/page-dynamic.html
      if typeof data.toPage is "string"
        u = $.mobile.path.parseUrl(data.toPage)
        if u.hash.search(/^#book-details/) isnt -1
          LYT.app.bookDetails u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-play/) isnt -1
          LYT.app.bookPlayer u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-index/) isnt -1
          log.message "Main: changepage"
          LYT.app.bookIndex u, data.options
          e.preventDefault()

  $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->

        $.mobile.showPageLoadingMsg()
        $("#password").blur()

        LYT.service.logOn($("#username").val(), $("#password").val())
          .done ->
            $.mobile.changePage "#bookshelf"

          .fail ->
            log.message "log on failure"

        event.preventDefault()
        event.stopPropagation()

  $("#bookshelf").live "pagebeforeshow", (event) ->
    LYT.app.bookshelf()
    
  $('#search').live "pagebeforeshow", (event) ->
    $("#search-form").submit ->
      $('#searchterm').blur()
      $.mobile.showPageLoadingMsg()
      $('#searchresult').empty()
      $.ajax
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        url: "/CatalogSearch/search.asmx/SearchFreetext",
        type: "POST"
        data: '{term:"' + $('#searchterm').val() + '"}'
        success: (data, status) -> 
          if data.d[0].resultstatus!="NORESULTS"
            s = '<li><h3>' + data.d[0].totalcount + ' resultat(er)</h3></li>'
            for item in data.d
              s += """
               <li id="#{item.imageid}">
                 <a href="#book-details">
                   <img class="ui-li-icon" src="/images/default.png">
                     <h3>#{item.title}</h3>
                       <p>#{item.author}|#{LYT.gui.parseMediaType item.media}</p>
                 </a>
               </li>"""
          else
            s += '<li><h3>Ingen resultater</h3></li>'
          $('#searchresult').html(s)
        error: onSearchError
        complete: onSearchComplete

    onSearchError = (msg, data)->
      $("#searchresult").text("Error thrown: " + msg.status);

    onSearchComplete = ->
      $('#searchresult').listview('refresh');
      $('#searchresult').find('a:first').css 'padding-left','40px'
      $.mobile.hidePageLoadingMsg();
      LYT.gui.covercache($('#searchresult').html())
        
    $("#searchterm").autocomplete
	    source: (request, response) ->
	      $.ajax
	        url: "/CatalogSearch/search.asmx/SearchAutocomplete"
	        data: '{term:"' + $('#searchterm').val() + '"}'
	        dataType: "json"
	        type: "POST"
	        contentType: "application/json; charset=utf-8"
	        dataFilter: (data) -> data
	        success: (data) ->
	          response($.map(data.d, (item)-> value: item.keywords))
	          list = $('.ui-autocomplete').find('li').each ->
                  $(@).removeAttr 'class'  
                  $(@).attr 'class', 'ui-icon-searchfield'
                  $(@).removeAttr 'role'
                  $(@).html '<h3>' + $(@).find('a').text() + '</h3>'
              if list.length==1 and $(list).find('h3:first').text().length==0
                $(list).html '<h3>Ingen forslag</h3>'
              $('#searchresult').html(list).listview('refresh')
		    error: (XMLHttpRequest, textStatus, errorThrown) ->
	          log.message textStatus
	        minLength: 2
    $("#searchresult li").live "click", (event) -> $("#searchterm").val($(@).text())
    #$("#searchterm").val $(@).text()
    
    $("#searchterm").live "autocompleteclose", (event, ui) -> 
      $("#search-form").submit()
    
  $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#textsize").find("input").val LYT.settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textType')

        $("#textarea-example").css "font-family", LYT.settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('markingColor')

        $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            LYT.settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", LYT.settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", LYT.settings.get('textSize') + "px"

        $("#text-types input").change ->
            LYT.settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", LYT.settings.get('textType')
            $("#book-text-content").css "font-family", LYT.settings.get('textType')

        $("#marking-color input").change ->
            LYT.settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)

  $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_trackPageview", event.target.id ]