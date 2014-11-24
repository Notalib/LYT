/*global jQuery: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'Section', [ '$q', '$log', function( $q, $log ) {
    function Section( heading, book ) {
      this.book = book;

      // Wrap the heading in a jQuery object
      heading = jQuery( heading );

      // Get the basic attributes
      this.ref = heading.attr( 'id' );
      this[ 'class' ] = heading.attr( 'class' );

      // Get the anchor element of the heading, and its attributes
      var anchor = heading.find( 'a:first' );
      this.title = anchor.text( ).trim( );

      // The [NCC](http://www.daisy.org/z3986/specifications/daisy20.php#5.0%20NAVIGATION%20CONTROL%20CENTER%20%28NCC%29)
      // standard dictates that all references should point to a specific par or
      // seq id in the SMIL file. Since the section class represents the entire
      // SMIL file, we remove the id reference from the url.
      var _ref = ( anchor.attr( 'href' ) || '' ).split( '#' );
      this.url = _ref[ 0 ];
      this.fragment = _ref[ 1 ];

      // We get some weird uris from IE8 due to missing documentElement substituted with iframe contentDocument.
      // Here we trim away everything before the filename.
      if ( this.url.lastIndexOf( '/' ) !== -1 ) {
        this.url = this.url.substr( this.url.lastIndexOf( '/' ) + 1 );
      }

      // Create an array to collect any sub-headings
      this.children = [ ];
      this.document = null;

      // If this is a "meta-content" section (listed in src/config/config.coffee)
      // this property will be set to true
      this.metaContent = false;
    }

    Section.prototype.load = function( ) {
      if ( this.loadingPromise ) {
        return this.loadingPromise;
      }

      var deferred = $q.defer( );
      var promise = deferred.promise;
      this.loadingPromise = promise;

      $log.log( 'Section: loading(\'' + this.url + '\')' );
      // trim away everything after the filename.
      var file = ( this.url.replace( /#.*$/, '' ) ).toLowerCase( );
      if ( !this.book.resources[ file ] ) {
        $log.error( 'Section: load: url not found in resources: ' + file );
        deferred.reject( );
        return this.loadingPromise;
      }

      this.book.getSMIL( file )
        .then( function( document ) {
          this.loaded = true;
          this.document = document;

          deferred.resolve( this );
        }.bind( this ) )
        .catch( function( ) {
          $log.error( 'Section: Failed to load SMIL-file ' + file );

          deferred.reject( );
        } );

      return this.loadingPromise;
    };

    Section.prototype.getAudioUrls = function( ) {
      if ( !this.document ) {
        return [ ];
      }

      var resources = this.resources;
      return this.document.getAudioReferences( ).reduce( function( urls, file ) {
        file = file.toLowerCase( );
        if ( resources[ file ] && resources[ file ].url ) {
          urls.push( resources[ file ].url );
        }

        return urls;
      }, [ ], this );
    };

    // Since segments are sub-components of this class, we ensure that loading
    // is complete before returning them.

    // Helper function for segment getters
    // Return a promise that ensures that resources for both this object
    // and the segment are loaded.
    var getSegment = function( section, getter ) {
      var deferred = $q.defer( );

      this.load( )
        .catch( function( error ) {
          deferred.reject( error );
        } )
        .then( function( section ) {
          if ( !section || !section.document || !section.document.segments ) {
            deferred.reject( );
            throw 'Section: _getSegment: Invalid section loaded';
          }

          var segment = getter( section.document.segments );
          if ( segment ) {
            segment.load( )
              .then( function( ) {
                deferred.resolve( segment );
              } )
              .catch( function( error ) {
                deferred.reject( error );
              } );
          } else {
            // TODO: We should change the call convention to just resolve with null
            //       if no segment is found.
            deferred.reject( 'Segment not found' );
          }
        } );

      return deferred.promise;
    };

    Section.prototype.firstSegment = function( ) {
      return getSegment( this, function( segments ) {
        return segments[ 0 ];
      } );
    };

    Section.prototype.lastSegment = function( ) {
      return getSegment( this, function( segments ) {
        return segments[ segments.length - 1 ];
      } );
    };

    // Flattens the structure from this section and "downwards"
    Section.prototype.flatten = function( ) {
      return this.children.reduce( function( flat, child ) {
        return flat.concat( child.flatten( ) );
      }, [ this ] );
    };

    return Section;
  } ] );
