'use strict';

angular.module( 'lytTest' )
  .factory( 'mockBookService', [ '$q', 'testData', function( $q, testData ) {
    return {
      issue: function( id ) {
        var deferred = $q.defer();
        deferred.resolve( id );
        return deferred.promise;
      },
      getResources: function( id ) {
        var getContentResourcesData = testData.dodp.getContentResourcesData;

        var deferred = $q.defer();
        if ( getContentResourcesData.params.contentID === id ) {
          deferred.resolve( getContentResourcesData.resolved );
        } else {
          deferred.reject( );
        }
        return deferred.promise;
      },
      getBookmarks: function( id ) {
        var getBookmarksData = testData.dodp.getBookmarksData;

        var deferred = $q.defer();
        if ( getBookmarksData.params.contentID === id ) {
          deferred.resolve( getBookmarksData.resolved );
        } else {
          deferred.reject( );
        }
        return deferred.promise;
      },
      setBookmarks: function( ) {
        var setBookmarksData = testData.dodp.setBookmarksData;

        var deferred = $q.defer();
        deferred.resolve( setBookmarksData.resolved );

        return deferred.promise;
      }
    };
  } ] );
