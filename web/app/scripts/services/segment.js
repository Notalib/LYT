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
       * And the following methods (not in prototype, mixed-in in constructor):
       *
       * - preload:         Preloads transcript content (i.e. images).
       * - state:           This is the state of the `Deferred#promise` used to indicate
       *                    if the segment has been loaded yet:
       *                     - pending:  the load() method hasn't been called yet
       *                                 or the segment is currently loading.
       *                     - resolved: the segment has been loaded and can be
       *                                 displayed.
       *                     - rejected: loading the segment has failed.
       */
      function Segment( data, document, index, previous ) {
        // Set up deferred load of images
        this._deferred = $q.defer( );
        this.promise = this._deferred.promise;
        this.promise.then( function( ) {
          this.ready = true;
        }.bind( this ) );

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

        this.duration = this.end - this.start;

        // Will be initialized in the load() method:
        this.text = null;
        this.smil = data.smil;
      }

      // Loads all resources
      Segment.prototype.load = function( ) {
        // Skip if already finished
        if ( this.loading || this.loaded ) {
          return this.promise;
        }

        this.loading = true;
        this.promise
          .finally( function( ) {
            this.loading = false;
            this.loaded = true;
          }.bind( this ) )
          .catch( function( ) {
            $log.error( 'Segment: failed loading segment ' + this.url( ) );
          }.bind( this ) );

        $log.log( 'Segment: loading ' + ( this.url( ) ) );

        // Parse transcript content
        var _ref = this.data.text.src.split( '#' );
        this.contentUrl = _ref[ 0 ];
        this.contentId = _ref[ 1 ];
        var resources = this.document.book.resources;
        var resource = resources[ this.contentUrl.toLowerCase( ) ];
        if ( !resource ) {
          $log.error( 'Segment: no absolute URL for content ' + this.contentUrl );
          this._deferred.reject( );
        } else {
          if ( !resource.document ) {
            resource.document = new TextContentDocument( resource.url,
              resources );
          }

          resource.document.promise
            .then( function( document ) {
              return parseContent( this, document );
            }.bind( this ) )
            .then( function( ) {
              return this._deferred.resolve( this );
            }.bind( this ) )
            .catch( function( status, error ) {
              $log.error( 'Unable to get TextContentDocument for ' + resource.url + ': ' + status + ', ' + error );
              return this._deferred.reject( );
            }.bind( this ) );
        }
        return this.promise;
      };

      Segment.prototype.url = function( ) {
        return '' + this.document.filename + '#' + this.id;
      };

      Segment.prototype.ready = false;

      Segment.prototype.bookmark = function( audioOffset ) {
        return new Bookmark( {
          URI: this.url( ),
          timeOffset: this.smilOffset( audioOffset )
        } );
      };

      // Convert from smil offset to audio offset
      Segment.prototype.audioOffset = function( smilOffset ) {
        return this.start + smilOffset - this.documentOffset;
      };

      // Convert from audio offset to smil offset
      Segment.prototype.smilOffset = function( audioOffset ) {
        return this.documentOffset + audioOffset - this.start;
      };

      Segment.prototype.containsOffset = function( offset ) {
        return ( this.start <= offset && offset <= this.end );
      };

      // Is the given offset within this Segment?
      Segment.prototype.containsAbsoluteOffset = function( offset ) {
        var startOffset = this.document.absoluteOffset + this.documentOffset;
        var endOffset = startOffset + this.duration;
        return startOffset <= offset && offset <= endOffset;
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
            var next = segment.next,
              nextSection;
            if ( next ) {
              return next.preloadNext( preloadCount - 1 );
            } else {
              var segmentSection = this.document.book.getSectionBySegment(
                segment );
              if ( segmentSection ) {
                nextSection = segmentSection.next;
              }

              if ( nextSection ) {
                return nextSection.firstSegment( )
                  .promise.then( function( next ) {
                    return next.preloadNext( preloadCount - 1 );
                  } );
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
        var e;
        if ( canvasSize.width !== imageSize.width ) {
          try {
            return imageSize.width / canvasSize.width;
          } catch ( _error ) {
            e = _error;
            return 1;
          }
        } else {
          return 1;
        }
      };

      var loadImage = function( segment, image ) {
        $log.log( 'Segment: ' + segment.url( ) + ': loadImage: initiate preload of image ' + image.src );

        var errorHandler = function( event ) {
          var backoff, doLoad;
          clearTimeout( image.timer );
          if ( image.attempts-- > 0 ) {
            backoff = Math.ceil( ( ( ( ( LYTConfig.segment || {} ).imagePreload || {} ).attempts || 3 ) - image.attempts + 1) * 50 );
            $log.log( 'Segment: loadImage: preloading image ' + image.src + ' failed, ' + image.attempts +
              ' attempts left. Waiting for ' + backoff + ' ms.' );
            doLoad = function( ) {
              return loadImage( segment, image );
            };
            return setTimeout( doLoad, backoff );
          } else {
            $log.error( 'Segment: loadImage: unable to preload image ' + image.src );
            return image.deferred.reject( image, event );
          }
        };

        var doneHandler = function( event ) {
          clearTimeout( image.timer );
          $log.log( 'Segment: loadImage: loaded image ' + image.src );
          return image.deferred.resolve( image, event );
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
        var defered = $q.defer( );

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
            deferred: defered
          };

          defered.promise.then( function( imageData, event ) {
            segment.canvasScale = getCanvasScale( segment.canvasSize, {
              width: event.target.width,
              height: event.target.height
            } );
          } );

          loadImage( segment, imageData );

          defered.promise.then( function( ) {
            $log.log( 'Segment: ' + (segment.url()) + ' finished extracting text, html and loading images', segment.text, image );
            return segment;
          } );
        } else {
          segment.type = 'standard';

          defered.resolve();
        }

        return defered.promise;
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
