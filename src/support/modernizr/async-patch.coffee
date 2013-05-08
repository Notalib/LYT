# -----------------------------------------------------------------
# Modernizr patch: provide asynchronous facilities
# -----------------------------------------------------------------

# TODO: this just got in:
# https://github.com/Modernizr/Modernizr/issues/622#issuecomment-17604606

# Fake asynchronous testing as in
# https://github.com/SlexAxton/Modernizr/commit/b78a2978b7b162edf37b073cdf74e629038c4a3b
# which provides the on() method for Modernizr, but until it is officially
# released, just do this.

callbacks = {}
Modernizr.on = (testName, callback) ->
  callbacks[testName] or= []
  callbacks[testName].push callback

resolveCallbacks = ->
  for testName, queue of callbacks
    if Modernizr[testName]?
      delete callbacks[testName]
      cb Modernizr[testName] for cb in queue

resolveInterval = setInterval resolveCallbacks, 100
