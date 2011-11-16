# This module sets and retrieves user specific settings

LYT.settings =

  data: {
    # default settings
    textSize: "14px"   
    markingColor: "none-black" # todod split into two variables
    textType: "Helvetica"
    textPresentation: "full"
    readSpeed: "1.0"
    textMode: 1 # phrasemode = 1, All text = 2
  }
    
  get: (key) -> 
    #todo: key not found error
    return @data[key]
  
  set: (key, value) ->
    @data[key] = value
    @save()
    
  load: ->
    # Load settings if they are set in localstorage
    data = LYT.cache.read("lyt","settings")   
    unless data is null
      @data = data
  
  save: ->
    LYT.cache.write("lyt", "settings", @data)
    
