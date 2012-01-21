# LYT

Source written in [CoffeeScript](http://jashkenas.github.com/coffee-script/)  
Stylesheets written in [SASS](http://sass-lang.com/)  
Inline docs written for [Docco](http://jashkenas.github.com/docco/)  
Tests built with [QUnit](http://docs.jquery.com/QUnit)

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
