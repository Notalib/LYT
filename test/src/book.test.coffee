module "Book"

asyncTest "Basics", 5, ->
  done = createAsyncCounter 2
  
  book = new LYT.Book 23
  book.done ->
    equal book.nccDocument.url, "/DodpMobile/resources/ncc.html"
    
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
