$(document).bind "mobileinit", ->
  
    LYT.player.setup()
    LYT.gui.setup()
    
    $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_setAccount", "UA-25712607-1" ]
        _gaq.push [ "_trackPageview", event.target.id ]      
    