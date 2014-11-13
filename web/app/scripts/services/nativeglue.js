'use strict';

angular.module( 'lyt3App' )
  .factory( 'Nativeglue', [ '$q', function Nativeglue( $q ) {
    var setBook = function( bookData ) {
      console.log( 'setBook', bookData, JSON.stringify( bookData ) );
      var defer = $q.defer( );

      defer.reject( 'TODO: setBook: Not implemented.' );

      return defer.promise;
    };

    var clearBook = function( bookId ) {
      console.log( 'clearBook', bookId );
      var defer = $q.defer( );

      defer.reject( 'TODO: clearBook: Not implemented.' );

      return defer.promise;
    };

    var getBooks = function( ) {
      var defer = $q.defer( );

      defer.reject( 'TODO: getBooks: Not implemented.' );

      return defer.promise;
    };

    var play = function( bookId, offset ) {
      console.log( 'play', bookId, offset );
      var defer = $q.defer( );

      defer.reject( 'TODO: play: Not implemented.' );

      return defer.promise;
    };

    var stop = function( ) {
      var defer = $q.defer( );

      defer.reject( 'TODO: stop: Not implemented.' );

      return defer.promise;
    };

    var cacheBook = function( bookId ) {
      console.log( 'cacheBook', bookId );
      var defer = $q.defer( );

      defer.reject( 'TODO: cacheBook: Not implemented.' );

      return defer.promise;
    };

    var clearBookCache = function( bookId ) {
      console.log( 'cacheBook', bookId );
      var defer = $q.defer( );

      defer.reject( 'TODO: clearBookCache: Not implemented.' );

      return defer.promise;
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
