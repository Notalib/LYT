/*global $: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'Segment', [ '$q', '$log', 'LYTConfig', 'TextContentDocument', 'Bookmark',
    function( $q, $log, LYTConfig, TextContentDocument, Bookmark ) {
      /*
       * This class models a 'segment' of audio + transcript,
       * i.e. a single 'sound clip' and its associated text/html
       *
       * A Segment instance is a Deferred. It resolves when all
       * images contained in the transcript have been loaded (by
       * calling the `preload` method), or if there were no images
       * to load.
       *
       * A Segment instance has the following properties:
       *
       * - id:              The id of the <par> element in the SMIL document
       * - start:           The start time, in seconds, relative to the audio
       * - end:             The end time, in seconds, relative to the audio
       * - audio:           The url of the audio file (or null)
       * - text:            The text content of the HTML content (or null)
       * - type:            Type of this segment. The following two types are
       *                    currently supported:
       *                     - cartoon:  Display one large image.
       *                                 Each segment is an area that the
       *                                 player should pan and zoom to.
       *                     - standard: Displays the provided content, replacing
       *                                 any previous content.
       *
       * - document         SMILDocument for the segment
       * - documentOffset   Start offset within the SMILDocument.
       * - previous         Previous segment within the same SMILDocument
       * - next             Next segment within the same SMILDocument
       * - ready            Have the content been loaded?
       */
      function Segment( data, document, index, previous ) {
        // Properties initialized in the constructor
        this.id = data.id;
        this.index = index;
        this.start = data.start;
        this.end = data.end;
        this.canBookmark = data.canBookmark;
        this.audio = void 0;
        if ( data.audio && data.audio.src ) {
          var src = data.audio.src.toLowerCase( );
          if ( document.book.resources[ src ] ) {
            this.audio = document.book.resources[ src ];
          }
        }
        this.data = data;
        this.el = data.par;

        this.document = document;
        this.documentOffset = 0;
        this.previous = previous;
        if ( previous ) {
          previous.next = this;
          this.documentOffset = previous.documentOffset + previous.duration;
        }

        document.promise.then( function( ) {
          this.absoluteOffset = document.absoluteOffset + this.documentOffset;
        }.bind( this ) );

        this.duration = this.end - this.start;

        // Will be initialized in the load() method:
        this.text = null;
        this.smil = data.smil;
      }

      // Loads all resources
      Segment.prototype.load = function( ) {
        if ( this.loadingPromise ) {
          return this.loadingPromise;
        }

        // Set up deferred load of images
        var deferred = $q.defer( );
        var promise = deferred.promise;
        this.loadingPromise = promise;
        promise.then( function( ) {
          this.ready = true;
        }.bind( this ) );

        var url = this.url( );

        promise
          .catch( function( ) {
            $log.error( 'Segment: failed loading segment ' + url );
          } );

        $log.log( 'Segment: loading ' + url );

        // Parse transcript content
        var _ref = this.data.text.src.split( '#' );
        this.contentUrl = _ref[ 0 ];
        this.contentId = _ref[ 1 ];
        var resources = this.document.book.resources;
        var resource = resources[ this.contentUrl.toLowerCase( ) ];
        if ( !resource ) {
          $log.error( 'Segment: no absolute URL for content ' + this.contentUrl );

          deferred.reject( );
        } else {
          if ( !resource.document ) {
            resource.document = new TextContentDocument( resource.url, resources );
          }

          resource.document.promise
            .then( function( document ) {
              return parseContent( this, document );
            }.bind( this ) )
            .then( function( ) {
              deferred.resolve( this );
            }.bind( this ) )
            .catch( function( reason ) {
              reason = reason || [];

              var status = reason[0];
              var error = reason[1];

              $log.error( 'Unable to get TextContentDocument for ' + resource.url + ': ' + status + ', ' + error );

              deferred.reject( );
            } );
        }

        return this.loadingPromise;
      };

      Segment.prototype.url = function( ) {
        return '' + this.document.filename + '#' + this.id;
      };

      Segment.prototype.ready = false;

      Segment.prototype.previous = null;
      Segment.prototype.next     = null;

      // Create a Bookmark-object from the given book offset
      Segment.prototype.bookmark = function( offset ) {
        if ( !this.containsAbsoluteOffset( offset ) ) {
          $log.error( 'Can\' create Bookmark, the offset: ' + offset + ', isn\'t within the segment: ' + this.url( ) );
          return null;
        }

        return new Bookmark( {
          URI: this.url( ),
          timeOffset: this.absoluteOffsetToSmilOffset( offset )
        } );
      };

      // Is the given book offset within this Segment?
      Segment.prototype.containsAbsoluteOffset = function( offset ) {
        var startOffset = this.absoluteOffset;
        var endOffset = startOffset + this.duration;
        return startOffset <= offset && offset <= endOffset;
      };

      // Calculate to books offset fra the offset within the segment
      Segment.prototype.smilOffsetToAbsolute = function( smilOffset ) {
        if ( this.containsSmilOffset ) {
          return smilOffset + this.absoluteOffset;
        }
      };

      // Convert book offset to internal smllOffset
      Segment.prototype.absoluteOffsetToSmilOffset = function( offset ) {
        if ( this.containsAbsoluteOffset( offset ) ) {
          return offset - this.absoluteOffset;
        }
      };

      // This the smilOffset within this segment?
      Segment.prototype.containsSmilOffset = function( smilOffset ) {
        return ( this.start <= smilOffset && smilOffset <= this.end );
      };

      // Will load this segment and the next preloadCount segments
      Segment.prototype.preloadNext = function( preloadCount ) {
        if ( preloadCount === undefined ) {
          preloadCount = ( ( LYTConfig.segment || {} ).preload || {} ).queueSize || 10;
        }

        this.load( );
        if ( preloadCount === 0 ) {
          return;
        }

        return this.promise
          .then( function( segment ) {
            var next = segment.next;
            if ( next ) {
              return next.preloadNext( preloadCount - 1 );
            } else {
              var segmentSection = this.document.book.getSectionBySegment( segment );
              if ( segmentSection ) {
                var nextSection = segmentSection.next;

                if ( nextSection ) {
                  return nextSection.firstSegment( )
                    .promise.then( function( next ) {
                      return next.preloadNext( preloadCount - 1 );
                    } );
                }
              }
            }
          }.bind( this ) );
      };

      var getCanvasSize = function( image ) {
        var result = {};
        [ 'height', 'width' ].forEach( function( type ) {
          var dim = image.attr( type );
          if ( dim ) {
            result[ type ] = dim;
            return;
          }
          dim = image.attr( 'style' )
            .match( type + '\\s*:\\s*(\\d+)\\s*px' );
          if ( dim ) {
            result[ type ] = dim[ 1 ];
            return;
          }
          if ( image.parent( )
            .css( type )
            .match( /(\d+)(?:px)?/ ) ) {
            result[ type ] = dim[ 1 ];
            return;
          } else {
            var attr = type.replace( /^([a-z])/g, function( m, p1 ) {
              return 'natural' + p1.toUpperCase( );
            } );
            $log.warn( 'render.content: imageDim: no ' + type + ' attribute or css ' + type +
              ' on image. Falling back to ' + attr + ' which is not known to be cross browser' );
            result[ type ] = image[ attr ];
          }
        } );
        return result;
      };

      var getCanvasScale = function( canvasSize, imageSize ) {
        if ( canvasSize.width !== imageSize.width ) {
          try {
            return imageSize.width / canvasSize.width;
          } catch ( e ) {
            return 1;
          }
        } else {
          return 1;
        }
      };

      var loadImage = function( segment, image ) {
        $log.log( 'Segment: ' + segment.url( ) + ': loadImage: initiate preload of image ' + image.src );

        var errorHandler = function( event ) {
          clearTimeout( image.timer );
          if ( image.attempts-- > 0 ) {
            var backoff = Math.ceil( ( ( ( ( LYTConfig.segment || {} ).imagePreload || {} ).attempts || 3 ) - image.attempts + 1) * 50 );

            $log.log( 'Segment: loadImage: preloading image ' + image.src + ' failed, ' + image.attempts +
              ' attempts left. Waiting for ' + backoff + ' ms.' );

            var doLoad = function( ) {
              loadImage( segment, image );
            };

            setTimeout( doLoad, backoff );
          } else {
            $log.error( 'Segment: loadImage: unable to preload image ' + image.src );
            image.deferred.reject( [ image, event ] );
          }
        };

        var doneHandler = function( event ) {
          clearTimeout( image.timer );
          $log.log( 'Segment: loadImage: loaded image ' + image.src );
          image.deferred.resolve( image, event );
        };

        image.timer = setTimeout( errorHandler, LYTConfig.segment.imagePreload.timeout );

        var tmp = new Image( );
        $( tmp )
          .load( doneHandler )
          .error( errorHandler );
        tmp.src = image.src;
      };

      // Parse content document and extract segment data
      // Used with deferreds, so should return the segment itself or a failed
      // promise in order to reject processing.
      var parseContent = function( segment, document ) {
        var image;
        var source = document.source;
        var sourceContent = source.find( '#' + segment.contentId );
        var sourceContentParent = sourceContent.parent();
        var deferred = $q.defer( );

        if ( sourceContentParent.hasClass( 'page' ) &&
          sourceContent.is( 'div' ) && ( image = sourceContentParent.children( 'img' ) ) ) {
          segment.type = 'cartoon';

          if ( image.length !== 1 ) {
            $log.error( 'Segment: parseContent: can\'t create reliable cartoon type with multiple or zero images: ' +
              segment.url( ) );
            throw 'Segment: parseContent: unable to find exactly one image in cartoon display div';
          }

          segment.image = image.clone( )
            .wrap( '<p>' )
            .parent( )
            .html( );

          segment.div = sourceContent.clone( )
            .wrap( '<p>' )
            .parent( )
            .html( );

          segment.canvasSize = getCanvasSize( image );

          var imageData = {
            src: image.attr( 'src' ),
            element: image[ 0 ],
            attempts: LYTConfig.segment.imagePreload.attempts,
            deferred: deferred
          };

          deferred.promise
            .then( function( imageData, event ) {
              segment.canvasScale = getCanvasScale( segment.canvasSize, {
                width: event.target.width,
                height: event.target.height
              } );
            } );

          loadImage( segment, imageData );

          deferred.promise.then( function( ) {
            $log.log( 'Segment: ' + (segment.url()) + ' finished extracting text, html and loading images', segment.text, image );

            return segment;
          } );
        } else {
          segment.type = 'standard';

          deferred.resolve();
        }

        return deferred.promise;
      };

      Segment.prototype.getBookOffset = function( ) {
        if ( !this.document ) {
          return 0;
        }

        return this.document.absoluteOffset + this.documentOffset;
      };

      return Segment;
    }
  ] );
