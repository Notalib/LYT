# LYT

Source written in [CoffeeScript](http://jashkenas.github.com/coffee-script/)  
Inline docs written for [Docco](http://jashkenas.github.com/docco/)  
Tests run with [QUnit](http://docs.jquery.com/QUnit)


## Development

First, [read the style guide](/Notalib/LYT/wiki/Style-Guide).

To compile the CoffeeScript source files, issue the following from the repo's root:

    $ cake src

The compiled `.js` files will end up in `build/javascript`

To compile (concatenate, really) the HTML files, use:

    $ cake html

This also copies the contents of `assets/` into the `build/` directory, and the contents of `css/` into `build/css`

To see what else you can build, issue `cake` with no arguments:

    $ cake

To run a local webserver for testing purposes, issue the following (again from the repo's root):

    $ tools/testserver

This will start a webserver that listens on (localhost:7357)[http://127.0.0.1:7357], so you can check things out in a browser.
