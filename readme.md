# LYT

A DAISY Online Delivery Protocol compatible book player for handheld devices.

# License and copyright

LYT is copyright [Nota](http://nota.nu/) and distritributed under [LGPL version 3](LICENSE).

## Technologies used

Source written in [CoffeeScript](http://jashkenas.github.com/coffee-script/)
Stylesheets written in [SASS](http://sass-lang.com/)
Inline docs written for [Docco](http://jashkenas.github.com/docco/)
Tests built with [QUnit](http://docs.jquery.com/QUnit)

## Change log

All releases are available from Github using the tag format lyt-&lt;version&gt;.


### Version 1.2.5-nvb

This version didn't have it version bumped in LYT.VERSION.

#### Improvements and bugfixes

  * Updated Cakefile to support Coffeescript 1.6.1.
  * Fixed issue that caused the player to stop when changing to a new audio
    stream on IOS (sporadic).


### Version 1.2.4

#### Improvements and bugfixes

  * Implemented source maps (experimental).
  * Fixed scoping issue that got triggered by using minify.


### Version 1.2.3

#### Improvements and bugfixes

  * Fixed bookmark related bug that caused the player to crash if attempting to
    play a book that doesn't support bookmarks by having id attributes on all
    par and seq elements in the SMIL resources.
  * Extensive instrumentation.


### Version 1.2.2

#### Improvements and bugfixes

  * Fixed bug that caused the player to lock up when redirecting from E17
    (and possibly other websites).


### Version 1.2.1

#### Improvements and bugfixes

  * Made it possible to disable HTML validation when building.
  * Updated test script.
  * Fixed several bookmark related bugs.
  * Fixed issue #511: bookmarks breaks when upgrading from version 1.1.4
    to 1.2.0. See commit 8ff265e1727e07d86bfd865f54cccb9a389248d0 for further
    information.
  * The player does not start playing automatically any longer (version 1.2.0
    did).
  * An IE8 specific bug that caused search to fail.
  * Disabled use of Modernizr.playbackrate. Setting playback rate is now
    enabled on all platforms - even when it isn't supported by the browser.
    (On platforms without playback rate support, setting playback rate has no
    effect.)


### Version 1.2.0

#### Major features

  * Keyboard shortcut navigation for most common tasks:
    play, pause, skip forward, skip backward, help and add bookmark.
  * Player handles more complex SMIL files now.
  * It is possible to change playback rate on supported platforms.
  * A large number of usability improvements for normal users as well as
    users of JAWS and other similar screen readers.

#### Improvements and bugfixes

  * Redirect to support page if platform unsupported.
  * Improved display of book index.
  * Navigation bug found when switching between search result pages.
  * Playback bug found in Chrome 24.
  * A number of HTML validation errors.
  * Various playback related bugs.
  * Fixed a number of bugs where event listeners handling the same event were
    bound several times.
  * Validating the finished HTML is now a step in the build process.
  * Instrumentation and developer console enabled when using the -d build flag.
  * In-player unit test framework set up.
  * Removed usage of global variables in a number of places.
  * Removed a large number of unused variables, functions and data structures.
  * Introduced a new class for bookmarks that uses SMIL offsets.


### Version 1.1.4

  * Updated text on support pages and in various other places.
  * Highlighting current book content paragraph.
  * Added predefined comic search.
  * Minor bugfixes.

Versions 1.1.1, 1.1.2 and 1.1.3 were never released.

### Version 1.1.0

#### Major features

  * IE8 support (limited to basic functions).
  * Added single sign on method for integration with external authorization server.
  * Better support of JAWS 10 to 13 and other screen readers.
  * Better highlighting of current paragraph in stack player.
  * Dynamic resizing of book content.
  * Upgraded to use jQuery 1.8.2, jQuery Mobile 1.2 and jQuery UI 1.9.0.
  * Upgraded to jQuery Mobile router 0.93.
  * Using Modernizr for non-JavaScript fallback.
  * Logging is now disabled by default.
  * More build options:
    * Development mode (enables logging).
    * Concatenate JavaScript.
    * Minify JavaScript.

#### Improvements and bug fixes

  * Added predefined comic search.
  * Numerous UI tweaks.
  * Bugfixes related to bookmarks, search and adding items to bookshelf.
  * Cleaned up screen.scss and added formatting notes.
  * Add home screen icons for IOS.
  * Make it possible to link to most pages and log the user in if necessary.
  * Removed hard wired Danish strings from coffeescript source.
  * Rewrote search related pages to handle some glitches and better clarity.


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

Also, [read the style guide](/Notalib/coffeescript-style-guide).

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
