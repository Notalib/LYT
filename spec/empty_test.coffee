vows   = require('vows')
assert = require('assert')

vows
  .describe('Skipping')
  .addBatch
    'When skipping backward':
      topic: null

      'it is null': (topic) ->
        assert.isNull topic

.export(module)
