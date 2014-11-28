/*global lytBridge: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'NativeGlue', [ '$rootScope', '$log', function( $rootScope, $log ) {
    window.lytHandleEvent = function( ) {
      var args = Array.prototype.slice.call( arguments, 0 );
      $rootScope.$broadcast.apply( $rootScope, args );

      if ( !$rootScope.$$phase ) {
        $rootScope.$apply( );
      }

      // $log.debug.apply( $log, args );
    };

    var setBook = function( bookData ) {
      $log.info( 'setBook:', bookData );
      return lytBridge.setBook( JSON.stringify( bookData ) );
    };

    var clearBook = function( bookId ) {
      $log.info( 'clearBook:', bookId );
      return lytBridge.clearBook( bookId );
    };

    var getBooks = function( ) {
      $log.info( 'getBooks:' );
      var res = lytBridge.getBooks( );
      if ( angular.isString( res ) ) {
        res = JSON.parse( res );
      }

      return res;
    };

    var play = function( bookId, offset ) {
      $log.info( 'play:', bookId, offset );
      return lytBridge.play( bookId, offset );
    };

    var stop = function( ) {
      $log.info( 'stop:' );
      return lytBridge.stop( );
    };

    var cacheBook = function( bookId ) {
      $log.info( 'cacheBook:', bookId );
      return lytBridge.cacheBook( bookId );
    };

    var clearBookCache = function( bookId ) {
      $log.info( 'clearBookCache:', bookId );
      return lytBridge.clearBookCache( bookId );
    };

    var cancelBookCaching = function( bookId ) {
      $log.info( 'cancelBookCaching:', bookId );
      return lytBridge.cancelBookCaching( bookId );
    };

    return {
      setBook: setBook,
      clearBook: clearBook,
      getBooks: getBooks,
      play: play,
      stop: stop,
      cacheBook: cacheBook,
      clearBookCache: clearBookCache,
      cancelBookCaching: cancelBookCaching
    };
  } ] );
