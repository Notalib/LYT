# Requires `/controllers/player`

# Command class that encapsulates low level audio related commands inside
# a jQuery.Deferred mixin. When the deferred is resolved, the command has
# completed successfully and if the deferred is rejected, the command has
# failed.
#
# The command may notify any observers if this is deemed useful.
#
# The constructor should both instantiate and run the desired command right
# away using the internal _run() method.
#
# The method handles() should return event handlers that this command wants
# to _attach to the jPlayer element in order to execute the command.
#
# The method cancel() should cancel the command as soon as possible.
# Any command that receives a cancel() request in the "pending" state
# must try to stop the command from being executed and then reject()
# if execution is sucessfully stopped.
#
# The auxillary method status() returns the current jPlayer status.

class LYT.player.command extends jQuery.Deferred
  constructor: (@el) ->
    jQuery.extend this, jQuery.Deferred()
    
  _attach: ->
    for name, handler of @handles()
      @el.on $.jPlayer.event[name], handler

  _detach: ->
    for name, handler of @handles()
      @el.unbind $.jPlayer.event[name], handler

  _run: (callback) ->
    this.always => @_detach()
    @_attach()
    callback() if @state() is 'pending'

  cancel: -> @cancelled = true

  handles: -> {}

  status: => @el.data('jPlayer').status
