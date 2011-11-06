LYT.app:
  
  logUserOff: ->
      @settings.username = ""
      @settings.password = ""
      @SetSettings()
      
      @protocol.LogOff()