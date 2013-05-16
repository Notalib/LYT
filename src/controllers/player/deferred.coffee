# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Wrap a jQuery.Deferred() into a LYT.player.command object                   #
# ########################################################################### # 

class LYT.player.command.deferred extends LYT.player.command

  # Using def in stead of deferred due to name clash when coffeescript
  # compiles to JavaScript
  constructor: (el, def) ->
    super el, def
