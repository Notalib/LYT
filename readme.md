# LYT

A DAISY Online Delivery Protocol compatible book player for handheld devices.

## Technologies used

Source written in [CoffeeScript](http://jashkenas.github.com/coffee-script/)  
Stylesheets written in [SASS](http://sass-lang.com/)  
Inline docs written for [Docco](http://jashkenas.github.com/docco/)  
Tests built with [QUnit](http://docs.jquery.com/QUnit)

## Change log

All releases are available from Github using the tag format lyt-&lt;version&gt;.

### Version 1.0.1

#### Major features

  * A brand new cartoon mode that displays a whole page at a time.
  * Improved standard mode that displays content as a stack.
  * Support for Dodp compatible bookmarks (including lastmark).
    This feature only works on books where par and seq elements have ids.
  * Support for Google Analytics events.
  * Splash page is displayed if the player detects that it is running in a
    browser that has been used with an older version.

#### Improvements and bug fixes

  * Linking to a specific place in a book can be done using URL parameters:
    * book (book identifier)
    * section (SMIL url from the ncc document).
    * segment (id of a par or seq element in the SMIL file).
    * offset - a floating point indicating how many seconds into the assocated
      audio file, the player should start at.
  * The player will discover if it is being used through a proxy and try to
    rewrite resource URLs accordingly (experimental).
  * Various improvements for playback on IOS.
  * Revamped player handling. The code that handles interaction with jPlayer
    is more readable and does much less user agent dependent stuff.
  * Revamped book content handling by enforcing that content dependencies
    are resolved lazily using jQuery deferred objects. Made subsequent requests
    for the same resource idempotent.
  * The player will pause if book content is missing.
  * There is a new on-screen console for developers that appears if the user
    clicks a h1 six times.
  * Added test in Cakefile that will halt with an error if any coffescript
    file contains tabs.
  * Support for logging to server has been implemented (experimental).
  * Improvements of preloading of images.
  * Cleanup: unused code removed and rewriting to minimize long dependencies.
  * Terse logging.
   

### Version 0.2

Released june 2012. Historic.

## Development
You'll need a few things [so check out these instructions](/Notalib/LYT/wiki/Prerequisites).

Also, [read the style guide](/Notalib/LYT/wiki/Style-Guide).

### Building

To compile the app, issue the following from the repo's root:

    $ cake app

This will compile the CoffeeScript files to `build/javascript`, concatenate the HTML files to `build/index.html`, and compile the SASS files to `build/css`. It also syncs the contents of `assets/` with the `build/` directory.

To see what else you can build, issue `cake` with no arguments:

    $ cake

### Test Server

To run a local webserver for testing purposes, issue the following (again from the repo's root):

    $ tools/server

This will start a (very simple) webserver that listens on http://127.0.0.1:7357, so you can check things out in a browser.

_Note:_ If you're using Windows' DOS prompt, you'll have to explicitly invoke the `coffee` command, i.e. `coffee tools/server`

The test server also serves test fixtures (i.e. simulated responses) for use with the QUnit test suite. To compile the test suite run: 

    $ cake tests
    $ tools/server

And then go to http://127.0.0.1:7357/test in your browser.

To see what else the server can do:

    $ tools/server -h

_Note: The server's proxy functionality is somewhat buggy_
