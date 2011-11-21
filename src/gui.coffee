# This module handles gui callbacks and various utility functions

LYT.gui =
  
  renderBookshelf: (books, view) ->
    list = view.find("ul")
    for book in books
      log.message book
      list.append("""<li><a href="#book-play?book=#{book.id}"><h1>#{book.title}</h1><h2>#{book.author}</h2></a></li>""")
    
    list.listview('refresh')
  
  renderBookPlayer: (metadata, section, view) ->
    view.find("#title").text metadata.title.content
    if metadata.creator?   
      view.find("#author").text toSentence(item.content for item in metadata.creator)
     
    view.find("#book_chapter").text section.title
  
    
  renderBookDetails: (metadata, view) ->
    view.find("#title").text metadata.title.content
    
    if metadata.creator?    
      view.find("#author").text toSentence(item.content for item in metadata.creator)
    
    if metadata.narrator? 
      view.find("#narrator").text toSentence(item.content for item in metadata.narrator)
    
    view.find("#totaltime").text metadata.totalTime.content
    
  
  covercache: (element, id) ->
    $(element).each ->
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
      img = $(new Image()).load(->
        $("#" + id).find("img").attr "src", u
      ).error(->
      ).attr("src", u)

  covercacheOne: (element, id) ->
    u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
    img = $(new Image()).load(->
      $(element).find("img").attr "src", u
    ).error(->
    ).attr("src", u)
  
  parseMediaType: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"
  
  onBookDetailsSuccess: (data, status) ->
    $("#book-details-image").html "<img id=\"" + data.d[0].imageid + "\" class=\"nota-full\" src=\"/images/default.png\" >"
    s = "<p>Serie: " + data.d[0].series + ", del " + data.d[0].seqno + " af " + data.d[0].totalcnt + "</p>"  if data.d[0].totalcnt > 1
    $("#book-details-content").empty()
    #fixme: remove inline javascript and create new listener for playnewbook
    $("#book-details-content").append("<h2>" + data.d[0].title + "</h2>" + "<h4>" + data.d[0].author + "</h4>" + "<a href=\"javascript:PlayNewBook(" + data.d[0].imageid + ", '" + data.d[0].title.replace("'", "") + "','" + data.d[0].author + "')\" data-role=\"button\" data-inline=\"true\">Afspil</a>" + "<p>" + parse_media_name(data.d[0].media) + "</p>" + "<p>" + data.d[0].teaser + "</p>" + s).trigger "create"
    @covercache_one $("#book-details-image")

  onBookDetailsError: (msg, data) ->
    $("#book-details-image").html "<img src=\"/images/default.png\" >"
    $("#book-details-content").html "<h2>Hov!</h2>" + "<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href=\"mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller\">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>"
  
      
  #renderBookIndex: (book, view) ->
    
