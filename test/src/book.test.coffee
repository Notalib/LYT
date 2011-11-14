module "Book"

asyncTest "Basics", 4, ->
  done = createAsyncCounter 2
  
  book = new LYT.Book 23
  book.done ->
    media = book.mediaFor()
    media.done (media) ->
      equal media.text,  "Book #0000 - Test Author: Test Book", "First media entry's text should be the title"
      ok    media.audio.match(/dtb_0001\.mp3$/), "First media entry should point to first mp3"
      equal media.start, 0, "First media entry should start at 0 seconds"
      equal media.end,   7.68, "Frist media entry should end at 7.68 seconds"
    media.always done
  book.fail ->
    console.log "Fail", arguments
  
  book.always done
