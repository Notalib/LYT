# Requires `/controllers/player`
# ------------------------------

# ########################################################################### #
# Abstract base class that encapsulates low level audio commands              #
# ########################################################################### #

# This class encapsulates low level audio related commands inside a
# jQuery.Deferred mixin. When the deferred is resolved, the command has
# completed successfully and if the deferred is rejected, the command has
# failed.
#
# To implement an audio command, inherit from this class and override _run()
# and handles().
#
# The constructor should both instantiate the command object and run the desired
# command right away using the internal _run() method.
#
# The method handles() should return event handlers that this command wants
# to _attach to the jPlayer element in order to execute the command.
#
# The method cancel() should cancel the command as soon as possible.
# Any command that receives a cancel() request in the "pending" state
# must try to stop the command from being executed and then reject()
# if execution is successfully stopped.
#
# The auxillary method status() returns the current jPlayer status.
#
# The command may notify any observers if this is deemed useful using notify().

nextId = 1

class LYT.player.command extends jQuery.Deferred

  constructor: (@el, deferred) ->
    jQuery.extend this, (deferred or jQuery.Deferred())
    @id = nextId++
    # Filter out progress events after cancel()
    progress = @progress
    @progress = => progress.apply this, arguments unless @cancelled

  _attach: ->
    @_attached or= []
    for name, handler of @handles()
      event = $.jPlayer.event[name]
      @_attached.push
        event: event
        handler: handler
      @el.bind event, handler

  # Assymmetric because if we call @handles() again, we may get new references
  # to the same handlers, which can't be unbound below.
  _detach: ->
    for binding in @_attached
      @el.unbind binding.event, binding.handler

  _run: (callback) ->
    @always => @_detach()
    @_attach()
    callback() if callback and @state() is 'pending'

  cancel: -> @cancelled = true

  handles: -> {}

  status: => @el.data('jPlayer').status
