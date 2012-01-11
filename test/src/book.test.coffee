# Requires `/models/book/book`

module "Book"

asyncTest "Basics", 4, ->
  done = createAsyncCounter 1
  
  book = new LYT.Book 23
  book.done ->
    equal book.id, 23, "Book's ID should be 23"
    equal book.author, "Test Author", "Book's author should be 'Book Author'"
    equal book.title, "Test Book", "Book's title should be 'Test Book'"
    equal book.totalTime, "10:19:56", "Book's total time should be '10:19:56'"
    
  book.fail ->
    console.log "Fail", arguments
  
  book.always done
