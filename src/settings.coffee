# This module sets and retrieves user specific settings
LYT.settings =

  # default settings
  data: {
    textStyle:
      'font-size': "14px"
      'background-color': "transparent"
      'color': "#000000"
      'font-family': "Helvetica"
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
  
  # Load settings if they are set in localstorage
  load: ->
    data = LYT.cache.read("lyt","settings")   
    unless data is null
      @data = data
  
  save: ->
    LYT.cache.write("lyt", "settings", @data)
    
