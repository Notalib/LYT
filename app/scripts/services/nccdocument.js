'use strict';

/**
 * @ngdoc service
 * @name lyt3App.NCCDocument
 * @description
 * # NCCDocument
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('NCCDocument', function () {
    // Service logic
    // ...

    var meaningOfLife = 42;

    // Public API here
    return {
      someMethod: function () {
        return meaningOfLife;
      }
    };
  });
