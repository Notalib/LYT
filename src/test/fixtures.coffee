LYT.test or= {}
LYT.test.fixtures or= {}

# To test a specific module, use an URL like this:
# http://your.host.somewhere/?module=<module name>
#
# Where <module name> is the name of a specific QUnit module,
# such as LYT.feature.authentication.

jQuery.ajax('test/fixtures.json')
  .done (data) ->
    LYT.test.fixtures.data = data
  .fail (error) ->
    console.log error
