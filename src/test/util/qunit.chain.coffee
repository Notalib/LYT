# Easier syntax for deferred chains used in testing with QUnit
 
QUnit.Chain = (deferred) ->
  self = -> self.deferred

  _then = (callbacks...) ->
    callbacks = callbacks[0] if Array.isArray callbacks[0]
    callbacks.filter (cb) -> throw "Invalid parameter: #{cb}" unless typeof cb is 'function'
    self.deferred = self.deferred.then.apply self.deferred, callbacks
    return self

  always = (callback) -> _then [callback, callback]

  assert = (text, cb) ->
    if not cb
      cb = (ok) -> ok
    _then [
      -> ok cb(true),  "Chain assertion: #{text}"
      -> ok cb(false), "Chain assertion: #{text}"
    ]

  self.deferred = deferred
  self.then = _then
  self.always = always
  self.assert = assert

  return self

# Self test section

QUnit.module 'LYT.test.util.Chain'
asyncTest 'Chain', ->
  promise = $.Deferred().resolve()
  QUnit.Chain promise
    .assert 'Done here'
    .always -> ok true, 'Always called in resolved state'
    .then -> $.Deferred().reject()      # Flip from resolved to rejected
    .always -> ok true, 'Always called in rejected state'
    .assert 'Failed', (ok) -> not ok 
    .then [
      -> $.Deferred().reject();         # Flip back from rejected to resolved
      -> $.Deferred().resolve();        # ...and flip from resolved to rejected
    ]
    .assert 'Resolved here'
    .always -> QUnit.start()
