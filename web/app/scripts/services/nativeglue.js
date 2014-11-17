'use strict';

angular.module( 'lyt3App' )
  .factory( 'Nativeglue', [ '$window', '$rootScope', '$log', function( $window, $rootScope, $log ) {
    $window.lytTriggerEvent = function( eventName ) {
      var args = Array.prototype.slice.call( arguments, 0 );
      $rootScope.$emit( eventName, args );
    };

    var setBook = function( bookData ) {
      $log.info( 'setBook:', bookData );
      return $window.lytBridge.setBook( bookData );
    };

    var clearBook = function( bookId ) {
      $log.info( 'clearBook:', bookId );
      return $window.lytBridge.clearBook( bookId );
    };

    var getBooks = function( ) {
      $log.info( 'getBooks:' );
      return $window.lytBridge.getBooks( );
    };

    var play = function( bookId, offset ) {
      $log.info( 'play:', bookId, offset );
      return $window.lytBridge.play( bookId, offset );
    };

    var stop = function( ) {
      $log.info( 'stop:' );
      return $window.lytBridge.stop( );
    };

    var cacheBook = function( bookId ) {
      $log.info( 'cacheBook:', bookId );
      return $window.lytBridge.cacheBook( bookId );
    };

    var clearBookCache = function( bookId ) {
      $log.info( 'cacheBookCache:', bookId );
      return $window.lytBridge.clearBookCache( bookId );
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
