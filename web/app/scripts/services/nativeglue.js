/*global lytBridge: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'NativeGlue', [ '$rootScope', '$log', '$location', function( $rootScope, $log, $location ) {
    window.lytTriggerEvent = function( eventName ) {
      var args = Array.prototype.slice.call( arguments, 0 );
      $rootScope.$emit( eventName, args );
    };

    $rootScope.$on( 'play-time-update', function( $currentScope, bookId/*, offset */ ) {
      var bookPath = '/book-player/' + bookId;
      if ( $location.path( ) !== bookPath ) {
        $location.path( bookPath );
      }
    } );

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
      return lytBridge.getBooks( );
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
      $log.info( 'cacheBookCache:', bookId );
      return lytBridge.clearBookCache( bookId );
    };

    return {
      setBook: setBook,
      clearBook: clearBook,
      getBooks: getBooks,
      play: play,
      stop: stop,
      cacheBook: cacheBook,
      clearBookCache: clearBookCache
    };
  } ] );
