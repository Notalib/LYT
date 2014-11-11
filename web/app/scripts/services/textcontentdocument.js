/*global jQuery: false, $: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'TextContentDocument', [ 'DtbDocument',
    function( DtbDocument ) {
      // Private method for resolving URLs
      var resolveURLs = function( source, resources, isCartoon ) {
        // Resolve images
        return source.find( '*[data-src]' )
          .each( function( index, item ) {
            var url;
            item = jQuery( item );
            if ( item.data( 'resolved' ) ) {
              return;
            }
            url = item.attr( 'data-src' )
              .replace( /^\//, '' );
            var newUrl = resources[ url ].url;
            item.data( 'resolved', 'yes' );
            if ( isCartoon ) {
              item.attr( 'src', newUrl.url );
              return item.removeAttr( 'data-src' );
            } else {
              item.attr( 'data-src', newUrl.url );
              return item.addClass( 'loader-icon' );
            }
          } );
      };

      function TextContentDocument( url, resources, callback ) {
        DtbDocument.call( this, url, ( function( _this ) {
          return function() {
            resolveURLs( _this.source, resources, _this.isCartoon() );
            if ( typeof callback === 'function' ) {
              return callback();
            }
          };
        } )( this ) );
      }

      TextContentDocument.prototype = Object.create( DtbDocument.prototype );

      TextContentDocument.prototype.isCartoon = function() {
        var pages;
        if ( this._isCartoon === undefined ) {
          pages = this.source.find( '.page' )
            .toArray();
          this._isCartoon = pages.length !== 0 && pages.every( function( page ) {
            return $( page )
              .children( 'img' )
              .length === 1;
          } );
        }
        return this._isCartoon;
      };

      return TextContentDocument;
    }
  ] );
