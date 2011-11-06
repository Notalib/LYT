@app:

  logUserOff: ->
      @settings.username = ""
      @settings.password = ""
      @SetSettings()
      
      @protocol.LogOff()


$(document).bind "mobileinit", ->
    
    @gui.setup()
    
    $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_setAccount", "UA-25712607-1" ]
        _gaq.push [ "_trackPageview", event.target.id ]      
    