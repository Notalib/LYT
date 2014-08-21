# Changelog

All releases are available from Github using the tag format lyt-&lt;version&gt;.

### Version 2.2.0

#### Major features

  * Introduced context viewer that displays the entire book content in stead
    of the old stack viewer that would sometimes skip content.
  * Proper playing of word-highlighted books.

#### Improvements and bugfixes

  * Chronological sorting of bookmarks.
  * Usability tweaks of book index.
  * A large number of bugfixes related to playback, including setting playback
    rate. Playback rate should now be supported where possible.
  * A number of navigation related bugfixes causing some buttons to misbehave.
  * Fixed a bug where the "loading" spinner wouldn't go away.

#### Development features and internal tweaks

  * Introduced server.coffee that makes it possible to run LYT locally,
    proxying DODP requests to a remote server when needed.
  * Internal cleanup of shorthand HTML elements in book content.
  * Added optional upload to server option to Cakefile.
  * jQuery Mobile upgraded to 1.3.2.
  * jQuery upgraded to 1.9.1.
  * jPlayer upgraded to 2.5.4.

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
