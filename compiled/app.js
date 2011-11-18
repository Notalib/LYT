(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  LYT.app = {
    next: "bookshelf",
    PlayNewBook: function(id, title, author) {
      $.mobile.showPageLoadingMsg();
      LYT.Pause();
      this.settings.currentBook = id.toString();
      this.settings.currentTitle = title;
      this.settings.currentAuthor = author;
      this.SetSettings();
      $("#currentbook_image").find("img").attr("src", "/images/default.png").trigger("create");
      $("#currentbook_image").find("img").attr("id", this.settings.currentBook).trigger("create");
      $("#book_title").text(title);
      $("#book_author").text(author);
      $("#book_chapter").text(0);
      $("#book_time").text(0);
      $.mobile.showPageLoadingMsg();
      return Play();
    },
    eventSystemLoggedOn: function(loggedOn, id) {
      if (id !== -1) {
        LYT.settings.set('username', id);
      }
      if (loggedOn) {
        return $.mobile.changePage(this.next);
      } else {
        $.mobile.hidePageLoadingMsg();
        return $.mobile.changePage("#login");
      }
    },
    eventSystemNotLoggedIn: function(where) {
      this.goto = where;
      if (this.settings.username !== "" && this.settings.password !== "") {
        if (console) {
          console.log("GUI: Event system not logged in, logger på i baggrunden");
        }
        return LYT.protocol.LogOn(LYT.settings.get('username'), LYT.settings.get('password'));
      } else {
        return $.mobile.changePage("#login");
      }
    },
    eventSystemForceLogin: function(response) {
      alert(response);
      $.mobile.hidePageLoadingMsg();
      return $.mobile.changePage("#login");
    },
    eventSystemGotBook: function(bookTree) {
      $.mobile.hidePageLoadingMsg();
      $("#book-play #book-text-content").html(window.globals.text_window);
      GetTextAndSound(PLAYLIST[0]);
      $("#book_index_content").empty();
      $("#book_index_content").append(bookTree);
      return $.mobile.changePage("#book-play");
    },
    eventSystemGotBookShelf: __bind(function(bookShelf) {
      var aBookShelf, addMore, nowPlaying;
      this.goto = "";
      this.full_bookshelf = bookShelf;
      console.log(this.full_bookshelf);
      $("#bookshelf-content").empty();
      aBookShelf = "";
      nowPlaying = "";
      addMore = "";
      $(bookShelf).find("contentItem:lt(" + this.bookshelf_showitems + ")").each(__bind(function() {
        var author, delimiter, title;
        delimiter = $(this).text().indexOf("$");
        author = $(this).text().substring(0, delimiter);
        title = $(this).text().substring(delimiter + 1);
        if ($(this).attr("id") === this.settings.currentBook) {
          return nowPlaying = "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\" ><a href=\"javascript:playCurrent();\"><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + " | afspiller nu</p></a></li>";
        } else {
          return aBookShelf += "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\"><a href='javascript:PlayNewBook(" + $(this).attr("id") + ", \" " + title.replace("'", "") + " \" , \" " + author + " \")'><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + "</p></a><a href=\"javascript:if(confirm('Fjern " + title.replace("'", "") + " fra din boghylde?')){ReturnContent(" + $(this).attr("id") + ");}\" >Fjern fra boghylde</a></li>";
        }
      }, this));
      if ($(this.full_bookshelf).find("contentList").attr("totalItems") > this.bookshelf_showitems) {
        addMore = "<li id=\"bookshelf-end \"><a href=\"javascript:addBooks()\">Hent flere bøger på min boghylde</p></li>";
      }
      $.mobile.changePage("#bookshelf");
      $("#bookshelf-content").append("<ul data-split-icon=\"delete\" data-split-theme=\"d\" data-role=\"listview\" id=\"bookshelf-list\">" + nowPlaying + aBookShelf + addMore + "</ul>").trigger("create");
      return this.covercache($("#bookshelf-list").html());
    }, this),
    addBooks: function() {
      this.bookshelf_showitems += 5;
      return this.eventSystemGotBookShelf(this.full_bookshelf);
    },
    eventSystemPause: function(aType) {
      $("#button-play").find("img").attr("src", "/images/play.png").trigger("create");
      if (aType === Player.Type.user) {
        ;
      } else {
        return aType === Player.Type.system;
      }
    },
    eventSystemPlay: function(aType) {
      $("#button-play").find("img").attr("src", "/images/pause.png").trigger("create");
      if (aType === Player.Type.user) {
        ;
      } else {
        return aType === Player.Type.system;
      }
    },
    eventSystemTime: function(t) {
      var current_percentage, total_secs, tt;
      total_secs = void 0;
      current_percentage = void 0;
      if ($("#NccRootElement").attr("totaltime") != null) {
        tt = $("#NccRootElement").attr("totaltime");
        if (tt.length === 8) {
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60) + parseInt(tt.substr(6, 2));
        }
        if (tt.length === 7) {
          total_secs = tt.substr(0, 1) * 3600 + (tt.substr(2, 2) * 60) + parseInt(tt.substr(5, 2));
        }
        if (tt.length === 5) {
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60);
        }
      }
      current_percentage = Math.round(t / total_secs * 98);
      $("#current_time").text(SecToTime(t));
      $("#total_time").text($("#NccRootElement").attr("totaltime"));
      return $("#timeline_progress_left").css("width", current_percentage + "%");
    },
    eventSystemTextChanged: function(textBefore, currentText, textAfter, chapter) {
      try {
        window.globals.text_window.innerHTML = "";
        if (chapter === "" || !(chapter != null)) {
          chapter = "Kapitel";
        }
        if (chapter.length > 14) {
          chapter = chapter.substring(0, 14) + "...";
        }
        $("#book_chapter").text(chapter);
        if (currentText.nodeType !== undefined) {
          window.globals.text_window.appendChild(document.importNode(currentText, true));
          $("#book-text-content").find("img").each(function() {
            var img, oldimage, rep_src;
            rep_src = $(this).attr("src").replace(/\\/g, "\\\\");
            oldimage = $(this);
            return img = $(new Image()).load(function() {
              var position;
              $(oldimage).replaceWith($(this));
              $(oldimage).attr("src", $(this).attr("src"));
              $(this).css("max-width", "100%");
              position = $(this).position();
              return $.mobile.silentScroll(position.top);
            }).error(function() {}).attr("src", rep_src);
          });
          return $("#book-text-content h1 a, #book-text-content h2 a").css("color", this.settings.markingColor.substring(this.settings.markingColor.indexOf("-", 0) + 1)).trigger("create");
        } else {
          ;
        }
      } catch (e) {
        return alert(e);
      }
    },
    showIndex: function() {
      return $.mobile.changePage("#book_index");
    },
    playCurrent: function() {
      if (isPlayerAlive()) {
        return $.mobile.changePage("#book-play");
      } else {
        return this.PlayNewBook(this.settings.currentBook, this.settings.currentTitle, this.settings.currentAuthor);
      }
    },
    gotoPage: function() {
      if (console) {
        console.log("GUI: gotoPage - " + this.goto);
      }
      switch (this.goto) {
        case "bookshelf":
          window.fileInterface.GetBookShelf();
          return this.goto = "";
        default:
          if ($(".ui-page-active").attr("id") === "login") {
            return window.fileInterface.GetBookShelf();
          }
      }
    },
    logUserOff: function() {
      LYT.settings.set('username', "");
      LYT.settings.set('password', "");
      return LYT.protocol.LogOff();
    }
  };
}).call(this);
