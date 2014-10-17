# Automatic tests with QUnit

LYT uses QUnit for semi-automatic tests in the browser.

To run the tests you need to create the file test/fixtures.json
with content in this format:

```{
  "users": {
    "standard": {
       "username": "USERNAME",
       "password": "PASSWORD"
    },
    "invalid": {
       "username": "USERNAME",
       "password": "BAD_PASSWORD"
    }
  },
  "books": {
    "standard": {
      "id": "NORMAL_BOOKID"
    },
    "cartoon": {
      "id": "CARTOON_BOOKID"
    }
  }
}```

Then you need to build as test and open your browser in http://hostname/#test
Tests results are displayed in the browser and sent via AJAX to /test/results,
if you're running server.coffee it's printed to the console.

### Writing tests:
Our test fixtures are defined in src/test/fixtures/, here you'll find book.coffe and user.coffee
Our modules are defined in src/test/modules, here you'll find authentication.test.coffee, navigation.test.coffee, and playback.test.coffee
And you'll find helper functions in src/test/utils

Testing replies heavily on promises and are chained together within a test module.

jQuery-mobile makes it hard to detect then a page has finished loaded, so use the function `$.mobile.util.waitForPage( hash )`.
If your test does something that triggers a loader, use `$.mobile.util.waitForClosedLoader()`.
Some tests requires user confirmation, like playbackRate, for this we have the function `$.mobile.util.waitForConfirmDialog( msg )`.

You can find more of these helper functions in src/test/util/mobile.util.coffee
