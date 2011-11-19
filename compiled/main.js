(function() {
  $(document).bind("mobileinit", function() {
    var renderBookDetails;
    LYT.player.setup();
    renderBookDetails = function(urlObj, options) {
      var $page, book, bookId, pageSelector;
      bookId = urlObj.hash.replace(/.*book=/, "");
      pageSelector = urlObj.hash.replace(/\?.*$/, "");
      log.message("Rendering book details for book with id " + bookId);
      book = new LYT.Book(bookId);
      book.done(function(book) {
        var metadata;
        LYT.player.loadBook(book);
        metadata = book.nccDocument.getMetadata();
        log.message(metadata.title.content);
        log.message(metadata.totalTime.content);
        return $.mobile.changePage("#book-play");
      });
      book.fail(function() {});
      $page = $(pageSelector);
      $page.page();
      options.dataUrl = urlObj.href;
      return $.mobile.changePage($page, options);
    };
    $(document).bind("pagebeforechange", function(e, data) {
      var u;
      if (typeof data.toPage === "string") {
        u = $.mobile.path.parseUrl(data.toPage);
        if (u.hash.search(/^#book-details/) !== -1) {
          renderBookDetails(u, data.options);
          return e.preventDefault();
        } else if (u.hash.search(/^#book-play/) !== -1) {
          renderBookPlay(u, data.options);
          return e.preventDefault();
        } else if (u.hash.search(/^#book-index/) !== -1) {
          renderBookIndex(u, data.options);
          return e.preventDefault();
        }
      }
    });
    $("#login").live("pagebeforeshow", function(event) {
      return $("#login-form").submit(function(event) {
        $.mobile.showPageLoadingMsg();
        $("#password").blur();
        LYT.service.logOn($("#username").val(), $("#password").val()).done(function() {
          return log.message("log on success!");
        }).fail(function() {
          return log.message("log on failure!");
        });
        event.preventDefault();
        return event.stopPropagation();
      });
    });
    $("#book_index").live("pagebeforeshow", function(event) {
      $("#book_index_content").trigger("create");
      return $("li[xhref]").bind("click", function(event) {
        $.mobile.showPageLoadingMsg();
        if (($(window).width() - event.pageX > 40) || (typeof $(this).find("a").attr("href") === "undefined")) {
          if ($(this).find("a").attr("href")) {
            event.preventDefault();
            event.stopPropagation();
            return event.stopImmediatePropagation();
          } else {
            event.stopImmediatePropagation();
            return $.mobile.changePage($(this).find("a").attr("href"));
          }
        }
      });
    });
    $("#book-play").live("pagebeforeshow", function(event) {
      LYT.gui.covercache_one($("#book-middle-menu"));
      $("#book-text-content").css("background", LYT.settings.get('markingColor').substring(LYT.settings.get('markingColor').indexOf("-", 0)));
      $("#book-text-content").css("color", LYT.settings.get('markingColor').substring(LYT.settings.get('markingColor').indexOf("-", 0) + 1));
      $("#book-text-content").css("font-size", LYT.settings.get('textSize') + "px");
      $("#book-text-content").css("font-family", LYT.settings.get('textType'));
      $("#bookshelf [data-role=header]").trigger("create");
      $("#book-play").bind("swiperight", function() {
        return LYT.player.nextPart();
      });
      return $("#book-play").bind("swipeleft", function() {
        return LYT.player.previousPart();
      });
    });
    $("#bookshelf").live("pagebeforeshow", function(event) {
      return $.mobile.hidePageLoadingMsg();
    });
    $("#settings").live("pagebeforecreate", function(event) {
      var initialize;
      initialize = true;
      $("#textarea-example").css("font-size", LYT.settings.get('textSize') + "px");
      $("#textsize").find("input").val(LYT.settings.get('textSize'));
      $("#textsize_2").find("input").each(function() {
        if ($(this).attr("value") === LYT.settings.get('textSize')) {
          return $(this).attr("checked", true);
        }
      });
      $("#text-types").find("input").each(function() {
        if ($(this).attr("value") === LYT.settings.get('textType')) {
          return $(this).attr("checked", true);
        }
      });
      $("#textarea-example").css("font-family", LYT.settings.get('textType'));
      $("#marking-color").find("input").each(function() {
        if ($(this).attr("value") === LYT.settings.get('markingColor')) {
          return $(this).attr("checked", true);
        }
      });
      $("#textarea-example").css("background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0)));
      $("#textarea-example").css("color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1));
      $("#textsize_2 input").change(function() {
        LYT.settings.set('textSize', $(this).attr("value"));
        $("#textarea-example").css("font-size", LYT.settings.get('textSize') + "px");
        return $("#book-text-content").css("font-size", LYT.settings.get('textSize') + "px");
      });
      $("#text-types input").change(function() {
        LYT.settings.set('textType', $(this).attr("value"));
        $("#textarea-example").css("font-family", LYT.settings.get('textType'));
        return $("#book-text-content").css("font-family", LYT.settings.get('textType'));
      });
      return $("#marking-color input").change(function() {
        LYT.settings.set('markingColor', $(this).attr("value"));
        $("#textarea-example").css("background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0)));
        $("#textarea-example").css("color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1));
        $("#book-text-content").css("background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0)));
        return $("#book-text-content").css("color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1));
      });
    });
    return $("[data-role=page]").live("pageshow", function(event, ui) {
      return _gaq.push(["_trackPageview", event.target.id]);
    });
  });
}).call(this);
