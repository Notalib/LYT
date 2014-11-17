'use strict';

angular.module( 'lyt3App' )
  .factory( 'Bookmark', function( ) {

    // This class represents a bookmark in a book - either set explicit by user
    // or as a lastmark.
    //
    // Caveat emptor: Since a bookmark refers to a SMIL par (or seq) element,
    // the attribute timeOffset is a SMIL offset, not an audio offset.
    function Bookmark(data) {
      ['note', 'URI', 'timeOffset'].forEach( function( key ) {
        this[key] = data[key];
      }, this );
    }

    return Bookmark;
  } );
