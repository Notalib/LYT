'use strict';

angular.module('lyt3App')
  .controller('ErrorCtrl', [ '$scope', function( $scope ) {
    $scope.lastError = null;

    $scope.$on( 'download-failed', function( $currentScope, bookId, reason ) {
      $scope.lastError = {
        type: 'download-failed',
        message: reason || ( 'Couldn\'t download: ' + bookId )
      };
    } );

    $scope.$on( 'play-failed', function( $currentScope, bookId, reason ) {
      $scope.lastError = {
        type: 'play-failed',
        message: reason || ( 'Play book:' +  bookId )
      };
    } );
  } ]);
