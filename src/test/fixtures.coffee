LYT.test or= {}
LYT.test.fixtures or= {}
LYT.test.fixtures.results or= {}

# To test a specific module, use an URL like this:
# http://your.host.somewhere/?module=<module name>
#
# Where <module name> is the name of a specific QUnit module,
# such as LYT.feature.authentication.

jQuery.getJSON('test/fixtures.json')
  .done (data) ->
    LYT.test.fixtures.data = data
  .fail (error) ->
    log.message error
