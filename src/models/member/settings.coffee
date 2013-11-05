# Requires `/common`
# Requires `/support/lyt/cache`

# -------------------

# This module sets and retrieves user specific settings

LYT.settings = do ->

  # Default settings
  # TODO: How much of this is actually used?
  defaults =
    playbackRate: 1
    textPresentation: "full"
    textMode: 1
    textStyle:
      'background-color': "#fff"
      'color':            "#000000"
      'font-size':        "16px"
      'font-family':      "Helvetica, sans-serif"

  # Load settings if they are set in localstorage
  settings = jQuery.extend {}, defaults, LYT.cache.read("lyt", "settings") or {}

  # Save the settings in local storage
  save = ->
    LYT.cache.write "lyt", "settings", settings

  # Emit a "value changed" event
  emit = (key, newValue, previousValue)->
    event = jQuery.Event "changed"
    event.key           = key
    event.newValue      = newValue
    event.previousValue = previousValue
    jQuery(LYT.settings).trigger event

  # ## Public API

  get: (key) ->
    # TODO: key not found error
    settings[key]

  set: (key, value) ->
    prev = settings[key]
    if value isnt prev
      settings[key] = value
      save()
      emit key, value, prev

  save: save

  reset: ->
    settings = jQuery.extend {}, defaults
    save()


