#!/usr/bin/env node
'use strict';

if ( process.argv.length <= 2 ) {
  console.error( 'Usage: createBookTestData.js PATH_TO_BOOK_DATA' );
  console.error( 'Go to: http://www.e17.dk/medier/37027 and download the DAISY book' );
  console.error( 'Unzip and point this script to the directory with the html-, smil- or mp3-files files' );
  process.exit(255);
}

var fs = require('fs');

var basedir = process.argv[2];
if ( !fs.existsSync(basedir) || !fs.statSync(basedir).isDirectory() ) {
  console.error( basedir + ' isn\'t a directory' );
  process.exit(255);
}

basedir = fs.realpathSync( basedir );

var templateFile = fs.realpathSync( __dirname + '/../test/mock/data/book-data.js-tmpl' );
var outputFile = __dirname + '/../test/mock/data/book-data.js';

var files = fs.readdirSync( basedir ).filter( function( fileName ) {
  var idx = fileName.lastIndexOf( '.' );
  var ext = fileName.substr( idx + 1 );

  return [ 'htm', 'html', 'smil', 'mp3' ].indexOf( ext ) > -1;
} );

if ( !files.length ) {
  console.error( 'No html-, smil- or mp3-files found in ' + basedir );
  process.exit(255);
}

var template = fs.readFileSync( templateFile, 'UTF-8' );

var output = files.reduce( function( output, fileName ) {
  var idx = fileName.lastIndexOf( '.' );
  var ext = fileName.substr( idx + 1 );
  var readContent = ['htm', 'html', 'smil' ].indexOf( ext ) > -1;
  var realPath = basedir + '/' + fileName;

  output[ fileName ] = {
    ext: ext,
    fileName: fileName,
    content: (function() {
      if ( readContent ) {
        return fs.readFileSync( realPath, 'UTF-8' );
      }
    })()
  };

  return output;
}, {} );

fs.writeFile( outputFile, template.replace( 'BOOKDATA', JSON.stringify( output ) ), function(err) {
  if ( err ) {
    throw err;
  }

  console.log( outputFile + ' created' );
});
