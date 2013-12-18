# LYT

A DAISY Online Delivery Protocol compatible book player for handheld devices.

LYT is copyright [Nota](http://nota.nu/) and distritributed under [LGPL version 3](LICENSE).


## Development
You'll need a few things, namely Node.js, CoffeeScript and Compass. [So check out these instructions](https://github.com/Notalib/LYT/wiki/Prerequisites) if you need help installing them.

Also, [please read the style guide](https://github.com/Notalib/LYT/wiki/Style-Guide).

### Building

To compile the app, issue the following from the repo's root:

    $ cake app

This will compile the CoffeeScript files to `build/javascript`, concatenate the HTML files to `build/index.html`, and compile the SASS files to `build/css`. It also syncs the contents of `assets/` with the `build/` directory.

To see what else you can build, issue `cake` with no arguments:

    $ cake

## Supported platforms

HTML5 audio playback support has proved to be extremely incosistent across
different platforms. But we believe that we've managed to support most modern
browsers (IE9+). Sadly **Firefox** support is very limited, since their mp3
implementation is only present on some platforms. We hope, however, to support
Firefox in the near future.


## Change log

All releases are available from Github using the tag format `lyt-<version>`.

### Version 2.1.0

#### Features

  * The LYT player now has two new controls that enables the user to skip
    forwards or backwards 15 seconds at a time.
  * Working playback rate changing on all platforms that natively supports it
  * A "Skip Mode" that skips all meta-content sections, such as the summary,
    flaps, dedication, etc. if the books is played for the first time
  * A new "Dyslexia" font, that should be easier for dyslecixs to read.

#### Improvements and bugfixes

  * Implemented a "command-based" architecture where the player can issue
    different commands and wait for them to resolve/reject
  * A lot of edge-cases that would leave the loader hanging has been fixed
  * Major refactoring of the internals, resulting in removal of the `Playlist`
    class, and decoupling the `Section`s from the `SMILDocument`s. This also
    meant removing *a lot* of legacy code
  * A bug where the last logged-in user's bookshelf would still be visible to
    new users
  * A `cake deploy` task, that deploys a build to an FTP server
  * A `cake lint:coffee` task that lints the source code
  * Standardized icon sizes, and sprites used to reduce latency
  * ... And a thousand other things


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
