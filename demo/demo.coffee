# Attach submit listener on page load
$ -> $("#input").submit (event) ->
  # Stop the submit event from propagating
  if event
    event.preventDefault?()
    event.stopPropagation?()
  
  # Get the form values
  username = $("#username").val()
  password = $("#password").val()
  bookid   = parseInt $("#book_id").val(), 10
  
  # Clear the `#output` 
  $("#output").text ""
  
  
  # Complain about missing book IDs
  if !bookid
    error("Invalid book ID");
    # Return false to _really_ avoid form submisson
    return false
  
  # Lock the form
  lockForm()
  
  # Do the log-on dance!
  LYT.service.logOn(username, password)
  .done ->
    # Load the book if successful
    printMsg "Logged in"
    loadBook bookid
  
  .fail ->
    # Complain otherwise
    error "Failed to log on"
  
  # Return false to _really_ avoid form submisson
  return false

# --------------------

# ## Utils

# Prints to `#output`
printMsg = (message) ->
  $("#output").text "#{$("#output").text()}#{message}\n"


# Stops everything and prints an error to `#output`
error = (message) ->
  highlightSection()
  stopClock()
  printMsg "ERROR: #{message}"
  unlockForm()


# Locks the form fields
lockForm = ->
  $("#input input").each ->
    $(this).attr "disabled", "disabled"


# Unlocks the form fields
unlockForm = ->
  $("#input input").each ->
    $(this).removeAttr "disabled"

# --------------------

# ## UI

# Prints the basic metadata on the page
printMetadata = (book) ->
  metadata = book.nccDocument.getMetadata()
  $("#title").text book.title
  $("#total").text book.totalTime
  $("#author").text book.author


# Creates a set of nested ordered lists for the book's structure
printStructure = (book) ->
  
  # Recursive helper function
  map = (list, parent) ->
    # Make an ordered list
    html = $ "<ol/>"
    
    for item in list
      # Make a list item element for each section
      li = $ "<li/>"
      html.append li
      li.html """<a href="#">#{item.title}</a>"""
      li.attr "id", item.id
      
      # Attach click handler
      li.click (event) ->
        playSection @id
        event.stopPropagation?()
        event.preventDefault?()
        false
      
      # Recursively make lists for sub-sections
      li.append map(item.children) if item.children?
    
    # Return the ordered list element
    html
  
  # Display the list
  $("#structure").empty().append map(book.nccDocument.structure)


# Highlights a given section in the section list
highlightSection = (id) ->
  $("li").removeClass "highlighted"
  $("li##{id}").first().addClass "highlighted" if id


# --------------------

# ## Playback

# Define stuff inside a closure, just to keep it separate
do ->
  # Current section ID
  currentSection = null
  
  # Current section's time offset (realtive to the book)
  sectionOffset  = null
  
  # Time-stuff for playback
  startTime = null
  timer     = null
  
  # The Book instance
  book = null
  
  lastContent = null
  
  # Loads a book by its ID  
  # _Globally accessible function (i.e. attached to `window`)_
  window.loadBook = (bookid) ->
    book = new LYT.Book bookid
    book.done ->
      printMsg "Book #{bookid} loaded"
      # Show the playback UI
      $("#book").show();
      printMetadata book
      printStructure book
      playSection null
    
    book.fail -> error "Failed to load book"
  
  # Helper function
  getSeconds = -> ((new Date()).getTime() / 1000) >>> 0
  
  # Starts loading content (the `section` arg is optional)
  window.playSection = (section) ->
    # Stop the timer, in case it's playing
    stopClock()
    
    # Setup some variables
    sectionOffset  = null
    currentSection = section
    startTime = getSeconds()
    
    # Reset the time counter
    $("#time").text formatTime(0)
    
    # Start the timer
    restartClock()
  
  # Pauses the playback clock
  window.stopClock = -> clearInterval timer
  
  # Starts/restarts the clock running
  restartClock = ->
    timer = setInterval update, 250
  
  # Updates the displayed transcript, ticks the clock, etc.
  update = ->
    # Get the elapsed time (relative to the current section)
    time = getSeconds() - startTime
    
    # Show the elapsed time (will be overridden later, when the section loads)
    $("#time").text formatTime(time)
    
    # Get the media for the current section at the current point in time
    book.mediaFor(currentSection, time)
    .done (media) ->
      if media?
        # When some media is successfully loaded...  
        # Set the section's absolute time-offset, if it hasn't been done already
        sectionOffset = media.absoluteOffset unless sectionOffset?
        
        # Set the time
        $("#time").text formatTime(time + sectionOffset)
        
        # Highlight the playing section (this really only needs
        # to be done once, but there's no harm in doing it 4 times
        # per second, is there?)
        highlightSection media.section
        
        # Show the html if it's different
        if media.html isnt lastContent
          lastContent = media.html
          $("#transcript").html media.html or ""
        
        # Show the audio URL and the text's in- and out-marks
        $("#audio").text "MP3: #{media.audio or ""} from #{formatTime media.start} to #{formatTime media.end}"
        
      else
        # If no media was found, then it's the end of the section, so...
        # Highlight nothing
        highlightSection()
        
        # Stop the clock
        stopClock()
        
        # Clear the text and the audio
        lastContent = null
        $("#transcript").text ""
        $("#audio").text ""
        
        # Explain
        printMsg "End of section/book"
        
        # Unlock the form fields
        unlockForm()
    
    # If the media-loading failed...
    .fail -> error "Failed to find any media for the given section/offset"
  

