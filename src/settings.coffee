# Setting and retrieving user settings and session states
# Should this use the cache functions?

LYT.settings =

  data: {
    # default settings
    textSize: "14px" 
    markingColor: "none-black"
    textType: "Helvetica"
    textPresentation: "full"
    readSpeed: "1.0"
    currentBook: "0"
    currentTitle: "Ingen Titel"
    currentAuthor: "John Doe"
    textMode: 1 # phrasemode = 1, All text = 2
    username: ""
    password: ""
  }
    
  get: (key) -> 
    #todo: key not found error
    return @data[key]
  
  set: (key, value) ->
    @data[key] = value
    @save()
    
  load: ->
    # Load settings if they are set in localstorage
    data = @cache.read("lyt","settings")   
    unless data is null
      @data = data
  
  save: ->
    @cache.write("lyt", "settings", @data)
    
