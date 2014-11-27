'use strict';

angular.module('lyt3App')
  .directive('displayErrors', function( ) {
    return {
      templateUrl: 'views/display-errors.html',
      restrict: 'E'
    };
  });
