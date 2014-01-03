# Requires `/common`
# Requires `/support/lyt/store`

# -------------------

# This module sets and retrieves user specific settings

class LYT.Settings
  # Default settings
  defaults =
    playbackRate: 1
    textPresentation: "full"
    textMode: 1
    textStyle:
      'background-color': "#fff"
      'color':            "#000000"
      'font-size':        "16px"
      'font-family':      "Helvetica, sans-serif"

  constructor: (memberID) ->
    log.message "Settings: New settings manager for member #{memberID}"
    @store = JSON.parse(LYT.store.read("settings") or "{}")

    @memberID = memberID
    if @memberID of @store
      @settings = @store[@memberID]
    else
      @settings = $.extend {}, defaults

  get: (key) ->
    @settings[key]

  set: (key, value) ->
    @settings[key] = value
    @save()

  save: ->
    @store[@memberID] = @settings
    LYT.store.write "settings", JSON.stringify @store

  reset: ->
    @settings = jQuery.extend {}, defaults
    @save()

