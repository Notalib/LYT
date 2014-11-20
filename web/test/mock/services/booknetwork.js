'use strict';

angular.module( 'lytTest' )
  .factory( 'mockBookService', [ '$q', 'testData', function( $q, testData ) {
    return {
      issue: function( id ) {
        var defered = $q.defer();
        defered.resolve( id );
        return defered.promise;
      },
      getResources: function( id ) {
        var getContentResourcesData = testData.dodp.getContentResourcesData;

        var defered = $q.defer();
        if ( getContentResourcesData.params.contentID === id ) {
          defered.resolve( getContentResourcesData.resolved );
        } else {
          defered.reject( );
        }
        return defered.promise;
      },
      getBookmarks: function( id ) {
        var getBookmarksData = testData.dodp.getBookmarksData;

        var defered = $q.defer();
        if ( getBookmarksData.params.contentID === id ) {
          defered.resolve( getBookmarksData.resolved );
        } else {
          defered.reject( );
        }
        return defered.promise;
      }
    };
  } ] );
