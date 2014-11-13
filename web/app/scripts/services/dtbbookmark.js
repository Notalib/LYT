'use strict';

/**
 * @ngdoc service
 * @name lyt3App.DtbBookmark
 * @description
 * # DtbBookmark
 * Factory in the lyt3App.
 */
angular.module( 'lyt3App' )
  .factory( 'DtbBookmark', function( ) {
    // Service logic
    // ...

    var meaningOfLife = 42;

    // Public API here
    return {
      someMethod: function( ) {
        return meaningOfLife;
      }
    };
  } );
