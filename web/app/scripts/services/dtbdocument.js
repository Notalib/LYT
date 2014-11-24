/*global XSLTProcessor: false, $: false, jQuery: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'DtbDocument', [ '$q', '$log', '$http', 'LYTConfig', 'BookNetwork',
    function( $q, $log, $http, LYTConfig, BookNetwork ) {
      /**
       * Meta-element name attribute values to look for
       * Name attribute values for nodes that may appear 0-1 times per file
       * Names that may have variations (e.g. `ncc:format` is the deprecated form of `dc:format`) are defined a arrays.
       * C.f. [The DAISY 2.02 specification](http://www.daisy.org/z3986/specifications/daisy_202.html#h3metadef)
       * TODO: Comment out the things we'll never need to speed up the processing
       **/

      var METADATA_NAMES = {
        singular: {
          coverage: 'dc:coverage',
          date: 'dc:date',
          description: 'dc:description',
          format: [ 'dc:format', 'ncc:format' ],
          identifier: [ 'dc:identifier', 'ncc:identifier' ],
          publisher: 'dc:publisher',
          relation: 'dc:relation',
          rights: 'dc:rights',
          source: 'dc:source',
          subject: 'dc:subject',
          title: 'dc:title',
          type: 'dc:type',
          charset: 'ncc:charset',
          depth: 'ncc:depth',
          files: 'ncc:files',
          footnotes: 'ncc:footnotes',
          generator: 'ncc:generator',
          kByteSize: 'ncc:kByteSize',
          maxPageNormal: 'ncc:maxPageNormal',
          multimediaType: 'ncc:multimediaType',
          pageFront: [ 'ncc:pageFront', 'ncc:page-front' ],
          pageNormal: [ 'ncc:pageNormal', 'ncc:page-normal' ],
          pageSpecial: [ 'ncc:pageSpecial', 'ncc:page-special' ],
          prodNotes: 'ncc:prodNotes',
          producer: 'ncc:producer',
          producedDate: 'ncc:producedDate',
          revision: 'ncc:revision',
          revisionDate: 'ncc:revisionDate',
          setInfo: [ 'ncc:setInfo', 'ncc:setinfo' ],
          sidebars: 'ncc:sidebars',
          sourceDate: 'ncc:sourceDate',
          sourceEdition: 'ncc:sourceEdition',
          sourcePublisher: 'ncc:sourcePublisher',
          sourceRights: 'ncc:sourceRights',
          sourceTitle: 'ncc:sourceTitle',
          timeInThisSmil: [ 'ncc:timeInThisSmil', 'time-in-this-smil' ],
          tocItems: [ 'ncc:tocItems', 'ncc:tocitems', 'ncc:TOCitems' ],
          totalElapsedTime: [ 'ncc:totalElapsedTime', 'total-elapsed-time' ],
          totalTime: [ 'ncc:totalTime', 'ncc:totaltime' ]
        },
        // Name attribute values for nodes that may appear multiple times per file
        plural: {
          contributor: 'dc:contributor',
          creator: 'dc:creator',
          language: 'dc:language',
          narrator: 'ncc:narrator'
        }
      };

      var createHTMLDocument = ( function( ) {
        var doctype;
        if ( document.implementation && typeof document.implementation.createHTMLDocument ===
          'function' ) {
          return function( ) {
            return document.implementation.createHTMLDocument( '' );
          };
        }

        // Firefox does not support `document.implementation.createHTMLDocument()`
        // The following work-around is adapted from [this gist](http://gist.github.com/49453)
        if ( typeof XSLTProcessor !== 'undefined' && XSLTProcessor !==
          null ) {
          return function( ) {
            var doc, error, html, processor, range, template;
            processor = new XSLTProcessor( );
            template =
              '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
              '<xsl:output method="html"/>' +
              '<xsl:template match="/">' +
              '<html><head><title>HTML Document</title></head><body/></html>' +
              '</xsl:template>' +
              '</xsl:stylesheet>';

            doc = document.implementation.createDocument( '', 'foo',
              null );
            range = doc.createRange( );
            range.selectNodeContents( doc.documentElement );
            try {
              doc.documentElement.appendChild( range.createContextualFragment(
                template ) );
            } catch ( _error ) {
              error = _error;
              return null;
            }
            processor.importStylesheet( doc.documentElement.firstChild );
            html = processor.transformToDocument( doc );
            if ( !html.body ) {
              return null;
            }
            return html;
          };
        } else if ( document.implementation && typeof document.implementation
          .createDocumentType === 'function' ) {
          doctype = document.implementation.createDocumentType( 'HTML',
            '-//W3C//DTD HTML 4.01//EN',
            'http://www.w3.org/TR/html4/strict.dtd' );
          return function( ) {
            return document.implementation.createDocument( '', 'HTML',
              doctype );
          };
          // Internet Explorer 8 does not have a document.implementation.createHTMLDocument
          // We bypass this by extracting the document from an invisible iframe.
          // Caveat emptor: the documentElement attribute on the document is null.
        } else if ( document.implementation && !document.implementation.createHTMLDocument ) {
          return function( ) {
            var doc, iframe;
            iframe = $(
              '<iframe id="docContainer" src="about:blank" style="display: none; position: absolute; z-index: -1;"></iframe>'
            );
            $( 'body' )
              .append( iframe );
            doc = iframe[ 0 ].contentDocument;
            $( 'body' )
              .detach( '#docContainer' );
            return doc;
          };
        }
      } )( );

      // Internal function to convert raw text to a HTML DOM document
      var coerceToHTML = function( responseText, hideImageUrl ) {
        if ( this === undefined ) {
          $log.error( 'coerceToHTML: should be called with coerceToHTML.call( this, responseText, hideImageUrl );' );
        }

        var container, doc, e, markup, scriptTagRegex;
        $log.log( 'DTB: Coercing ' + this.url + ' into HTML' );
        try {
          // Grab everything inside the "root" `<html></html>` element
          markup = responseText.match(
            /<html[^>]*>([\s\S]+)<\/html>\s*$/i );
        } catch ( _error ) {
          e = _error;
          $log.error( 'DTB: Failed to coerce markup into HTML', e, responseText );
          return null;
        }

        if ( !markup.length ) {
          return null;
        }
        markup = markup[ 0 ].replace( /<\/?head[^>]*>/gi, '' )
          .replace( /<(span|div|p) ([^/>]*)\s+\/>/gi,
            '<$1 $2></$1>' )
          .replace( /(<img[^>]+)src=['"]([^'"]+)['"]([^>]*>)/gi,
            '$1 data-src="$2" src="' + hideImageUrl + '"$3'
          )
          .replace( /<style[^>]+[^]+<\/style>/gi, '' )
          .replace( /<link[^>]+>/gi, '' );
        scriptTagRegex =
          /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi;

        while ( scriptTagRegex.test( markup ) ) {
          markup = markup.replace( scriptTagRegex, '' );
        }

        doc = createHTMLDocument( );
        if ( !doc ) {
          // Give up if nothing was created
          return null;
        }

        // doc.documentElement is missing if doc was created by IE8
        // For some reason, we can work around the issue by appending directly
        // on doc itself (which doesn't really make sense).
        container = doc.createElement( 'div' );
        container.innerHTML = markup;

        if ( doc.documentElement ) {
          var bodyElements = doc.documentElement.getElementsByTagName(
            'body' );
          if ( bodyElements ) {
            bodyElements[ 0 ].appendChild( container );
          } else {
            doc.appendChild( container );
          }
        } else {
          doc.appendChild( container );
        }
        return jQuery( doc );
      };

      // This class serves as the parent of the `SMILDocument` and `TextContentDocument` classes.
      // It is not meant for direct instantiation - instantiate the specific subclasses.
      function DTBDocument( url, callback ) {
        /* The constructor takes 1-2 arguments (the 2nd argument is optional):
         * - url: (string) the URL to retrieve
         * - callback: (function) called when the download is complete (used by subclasses)
         *
         * `DTBDocument`.promise for the object promise object
         */
        this.url = url;
        var deferred = $q.defer( );
        this.promise = deferred.promise;

        // This instance property will hold the XML/HTML
        // document, once it's been downloaded
        this.source = null;
        var dataType = /\.x?html?$/i.test( this.url ) ? 'html' : 'xml';
        var attempts = LYTConfig.dtbDocument.attempts || 3;

        var useForceClose = !!LYTConfig.dtbDocument.useForceClose;

        // This function will be called, when a DTB document has been successfully downloaded
        var loaded = function( data ) {
          /* TODO: Now that all the documents _should be_ valid XHTML, they should be parsable
           * as XML. I.e. `coerceToHTML` shouldn't be necessary _unless_ there's a `parsererror`.
           * But for some reason, that causes a problem elsewhere in the system, so right now
           * _all_ html-type documents are forcibly sent through `coerceToHTML` even though
           * it shouldn't be necessary...
           */
          if ( dataType === 'html' || data.indexOf( 'parseerror' ) > -1 ) {
            this.source = coerceToHTML.call( this, data, this.hideImageUrl );
          } else { // TODO: Should we specify XML here?
            // Using jQuery.parseXML to avoid triggering attempt to download audio.src and other remote resources listed in the XML-files
            this.source = jQuery( jQuery.parseXML( data ) );
          }
          return resolve( );
        }.bind( this );

        // This function will be called if `load()` (below) fails
        var failed = function( data, status ) {
          // If access was denied, try silently logging in and then try again
          if ( status === 403 && attempts > 0 ) {
            $log.warn( 'DTB: Access forbidden - refreshing session' );
            BookNetwork.refreshSession( )
              .done( load )
              .catch( function( ) {
                $log.error( 'DTB: Failed to get ' + this.url + ' (status: ' + status + ')' );
                deferred.reject( status );
              } );
            return;
          }

          // If the failure was due to something else (and wasn't an explicit abort)
          // try again, if there are any attempts left
          if ( /*status !== 'abort' &&*/ attempts > 0 ) {
            $log.warn( 'DTB: Unexpected failure (' + attempts + ' attempts left)' );
            load( );
            return;
          }
          // If all else fails, give up
          $log.error( 'DTB: Failed to get ' + this.url + ' (status: ' + status + ')', arguments );
          deferred.reject( status );
        };

        var resolve = function( ) {
          if ( this.source ) {
            // log.group("DTB: Got: " + this.url, this.source);
            if ( angular.isFunction( callback ) ) {
              callback( deferred );
            }

            deferred.resolve( this );
          } else {
            deferred.reject( [ -1, 'FAILED_TO_LOAD' ] );
          }
        }.bind( this );

        // Perform the actual AJAX request to load the file
        var load = function( ) {
          var forceCloseMsg;
          --attempts;
          var urlArr = this.url.split( '?' );
          var baseURL = urlArr[0];
          var params = ( urlArr[1] || '' ).split( '&' ).reduce( function( params, str ) {
            var dArr = str.split( '=' );
            if ( dArr.length === 2 ) {
              params[ dArr[0] ] = dArr[1];
            }
            return params;
          }, {} );

          if ( useForceClose ) {
            forceCloseMsg = '[forceclose ON]';
            params.forceclose = 'true';
          } else {
            forceCloseMsg = '';
          }

          $log.log( 'DTB: Getting: ' + baseURL + ' (' + attempts + ' attempts left) ' + forceCloseMsg, 'params: ', params );
          $http
            .get( baseURL, {
              params: params
            } )
            .success( loaded )
            .error( failed );
        }.bind( this );

        load( );
      }

      // Parse and return the metadata as an array
      DTBDocument.prototype.getMetadata = function( ) {
        if ( !this.source ) {
          return {};
        }

        // Return cached metadata, if available
        if ( this._metadata ) {
          return this._metadata;
        }

        // Find the `meta` elements matching the given name-attribute values.
        // Multiple values are given as an array
        var findNodes = function( values ) {
          if ( !( values instanceof Array ) ) {
            values = [ values ];
          }

          var nodes = [ ];

          var selectors = values.map( function( value ) {
            return 'meta[name*="' + value + '"]';
          } ).join( ', ' );

          this.source.find( selectors )
            .each( function( ) {
              var node = jQuery( this );
              return nodes.push( {
                content: node.attr( 'content' ),
                scheme: node.attr( 'scheme' ) || null
              } );
            } );

          if ( nodes.length === 0 ) {
            return null;
          }

          return nodes;
        }.bind( this );

        this._metadata = Object.keys( METADATA_NAMES.singular ).reduce(
          function( metadata, name ) {
            var values = METADATA_NAMES.singular[ name ];
            var found = findNodes( values );
            if ( found ) {
              metadata[ name ] = found.shift( );
            }

            return metadata;
          }, {} );

        this._metadata = Object.keys( METADATA_NAMES.plural ).reduce(
          function( metadata, name ) {
            var values = METADATA_NAMES.plural[ name ];
            var found = findNodes( values );
            if ( found ) {
              metadata[ name ] = found;
            }

            return metadata;
          }, this._metadata );

        return this._metadata;
      };

      DTBDocument.prototype.hideImageUrl =
        'css/images/loading-spinning-bubbles.svg';

      return DTBDocument;
    }
  ] );
