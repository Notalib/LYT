module "Book"

asyncTest "Basics", 6, ->
  done = createAsyncCounter 2
  
  book = new LYT.Book 23
  book.done ->
    equal book.resources.ncc, "/DodpMobile/resources/ncc.html"
    equal book.resolveURL("dtb_0002.smil"), "/DodpMobile/resources/dtb_0002.smil"
    media = book.mediaFor()
    media.done (media) ->
      equal media.text,  "Bognr. 15000 - J. K. Rowling: Harry Potter og Fønixordenen"
      equal media.audio, "/DodpMobile/resources/dtb_0001.mp3"
      equal media.start, 0
      equal media.end,   7.735
    media.always done
  book.fail ->
    console.log "Fail", arguments
  
  book.always done
