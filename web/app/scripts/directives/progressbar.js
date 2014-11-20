'use strict';

angular.module('lyt3App')
  .directive('progressbar', function() {
    return {
      templateUrl: '/views/progressbar.html',
      restrict: 'E',
      link: function(/*scope, element, attrs*/) {
      }
    };
  });
