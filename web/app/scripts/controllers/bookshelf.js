'use strict';

angular.module('lyt3App')
  .controller('BookshelfCtrl', [ '$scope', 'BookService', function ($scope, BookService) {
    $scope.books = [];

    BookService.logOn( 'guest', 'guest' ).then(
      function( ) {
        BookService.getBookshelf( ).then( function( list ) {
          var offset = list.firstItem;
          if ( list.items ) {
            list.items.forEach( function( item, idx ) {
              $scope.books[idx + offset] = item;
            } );
          }
        } );
      },
      function( ) {
        console.log( 'logOn: rejected', arguments );
      }
    );

  } ]);
