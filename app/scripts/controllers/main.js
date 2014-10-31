'use strict';

/**
 * @ngdoc function
 * @name lyt3App.controller:MainCtrl
 * @description
 * # MainCtrl
 * Controller of the lyt3App
 */
angular.module('lyt3App')
  .controller('MainCtrl', function ($scope, DODP) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });
