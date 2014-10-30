'use strict';

/**
 * @ngdoc function
 * @name lyt3App.controller:AboutCtrl
 * @description
 * # AboutCtrl
 * Controller of the lyt3App
 */
angular.module('lyt3App')
  .controller('AboutCtrl', function ($scope) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });
