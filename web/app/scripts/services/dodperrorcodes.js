'use strict';

angular.module( 'lyt3App' )
  .factory( 'DODPErrorCodes', function( ) {

    var RPC_UNEXPECTED_RESPONSE_ERROR = {};
    var RPC_GENERAL_ERROR = {};
    var RPC_TIMEOUT_ERROR = {};
    var RPC_ABORT_ERROR = {};
    var RPC_PARSER_ERROR = {};
    var RPC_HTTP_ERROR = {};

    var DODPfaultCodes = {
      DODP_INTERNAL_ERROR: /\binternalServerError/i,
      DODP_NO_SESSION_ERROR: /\bnoActiveSession/i,
      DODP_UNSUPPORTED_OP_ERROR: /\boperationNotSupported/i,
      DODP_INVALID_OP_ERROR: /\binvalidOperation/i,
      DODP_INVALID_PARAM_ERROR: /\binvalidParameter/i
    };

    var DODP_UNKNOWN_ERROR = {};

    return {
      get RPC_UNEXPECTED_RESPONSE_ERROR( ) {
        return RPC_UNEXPECTED_RESPONSE_ERROR;
      },
      get RPC_GENERAL_ERROR( ) {
        return RPC_GENERAL_ERROR;
      },
      get RPC_TIMEOUT_ERROR( ) {
        return RPC_TIMEOUT_ERROR;
      },
      get RPC_ABORT_ERROR( ) {
        return RPC_ABORT_ERROR;
      },
      get RPC_PARSER_ERROR( ) {
        return RPC_PARSER_ERROR;
      },
      get RPC_HTTP_ERROR( ) {
        return RPC_HTTP_ERROR;
      },
      get DODP_INTERNAL_ERROR( ) {
        return DODPfaultCodes.DODP_INTERNAL_ERROR;
      },
      get DODP_NO_SESSION_ERROR( ) {
        return DODPfaultCodes.DODP_NO_SESSION_ERROR;
      },
      get DODP_UNSUPPORTED_OP_ERROR( ) {
        return DODPfaultCodes.DODP_UNSUPPORTED_OP_ERROR;
      },
      get DODP_INVALID_OP_ERROR( ) {
        return DODPfaultCodes.DODP_INVALID_OP_ERROR;
      },
      get DODP_INVALID_PARAM_ERROR( ) {
        return DODPfaultCodes.DODP_INVALID_PARAM_ERROR;
      },
      get DODP_UNKNOWN_ERROR( ) {
        return DODP_UNKNOWN_ERROR;
      },
      identifyDODPError: function( code ) {
        var match;

        Object.keys( DODPfaultCodes ).some( function( key ) {
          var signature = DODPfaultCodes[ key ];
          if ( signature.test( code ) ) {
            match = DODPfaultCodes[ key ];
            return true;
          }
        } );

        if ( !match ) {
          match = DODP_UNKNOWN_ERROR;
        }
        return match;
      }
    };
  } );
