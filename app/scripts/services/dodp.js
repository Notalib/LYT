'use strict';

/**
 * @ngdoc service
 * @name lyt3App.DODP
 * @description
 * # DODP
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('DODP', [ '$sanitize', '$http', '$q', 'xmlParser', function ($sanitize, $http, $q, xmlParser) {
    var soapTemplate = '<?xml version="1.0" encoding="UTF-8"?>' +
      '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://www.daisy.org/ns/daisy-online/" xmlns:ns2="http://www.daisy.org/z3986/2005/bookmark/">' +
      '<SOAP-ENV:Body>SOAPBODY</SOAP-ENV:Body>' +
      '</SOAP-ENV:Envelope>';


    var appendToXML = function( xml, nodeName, data ) {
      var nsid = 'ns1:';
      if ( nodeName.indexOf(':') > -1 ) {
        nsid = '';
      }

      xml += '<' + nsid + nodeName + '>' + toXML( data ) + '</' + nsid + nodeName + '>';

      return xml;
    };

    var toXML = function( hash ) {
      var xml = '';
      // Handling of namespaces could be done here by initializing a string
      // containing the necessary declarations that can be inserted in append()

      // Append XML-strings by recursively calling `toXML`
      // on the data

      var type = typeof hash;
      if ( ['string','nunber','boolean'].indexOf(type) > -1 ) {
        // If the argument is a string, number or boolean,
        // then coerce it to a string and use a pseudo element
        // to handle the escaping of special chars
        xml = $sanitize(hash);
      } else if ( type === 'object' && type !== null ) {
        // If the argument is an object, go through its members
        Object.keys(hash).forEach( function(key) {
          var value = hash[key];
          if (value instanceof Array){
            value.forEach(function(item){
              xml = appendToXML(xml, key, item);
            });
          } else {
            xml = appendToXML(xml, key, value);
          }
        } );
      }

      return xml;
    };

    var createRequest = function(action, data) {
      var requestData = {};
      requestData[action] = data;

      var xmlBody = soapTemplate.replace( /SOAPBODY/, toXML(requestData) );

      return $http( {
        url: '/DodpMobile/Service.svc',
        method: 'POST',
        headers: {
          soapaction: '/' + action,
          'Content-Type': 'text/xml; charset=UTF-8'
        },
        data: xmlBody
      });
    };

    var xml2Json = function(xmlDom, json) {
      var tagName = xmlDom.tagName.replace( /^s:/, '' );
      if (xmlDom.children.length > 0) {
        json[tagName] = json[tagName] || {};
        Array.prototype.forEach.call( xmlDom.children, function(el){
          xml2Json(el,json[tagName]);
        });
      } else {
        var textContent = xmlDom.textContent;
        json[tagName] = textContent;
      }
    };

    var xmlStr2Json = function(xmlStr) {
      var xmlDOM = xmlParser.parse(xmlStr);
      var json = {};

      Array.prototype.forEach.call( xmlDOM.children[0].children, function(domEl){
        xml2Json(domEl,json);
      });

      return json;
    };

    // Public API here
    return {
      logOn: function(username,password) {
        var defer = $q.defer();
        createRequest('logOn',{
          username: username,
          password: password
        }).then(function(response){
          console.log(xmlStr2Json(response.data));
        }, function(){
          defer.reject( );
        });

        return defer.promise;
      }
    };
  }]);
