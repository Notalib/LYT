//
//  BookPart.h
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface BookPart : NSObject <NSCoding>
@property (nonatomic, strong) NSURL* url;

// cache path is dependent on URL and start only, such that all downloaders
// with the same URL x start share a cache file.
@property (nonatomic, readonly) NSString* cachePath;

// when true we read mp3 in smaller bits incrementally, which is better while playing
// as data will be written to the cache often such that the audio player will not run
// out of data. When not playing it is better to read in one large swoop.
// Changing this property will cancel any current downloads for BookPart.
@property (nonatomic, assign) BOOL chunked;

// holds the last error from downloading
@property (nonatomic, strong) NSError* error;

// start and end are measured in seconds
@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;
@property (nonatomic, readonly) NSTimeInterval duration;

// BookPart should try to keep its buffer filled to this many seconds,
// which can be set to very large number to buffer entire BookPart.
@property (nonatomic, assign) NSTimeInterval bufferingPoint;

// Like bufferingPoint but for data that is already present in cache
@property (nonatomic, readonly) NSTimeInterval ensuredBufferingPoint;

// Whether bufffer is filled up to the point wanted by bufferingPoint.
// You should probably KVO observe this property.
@property (nonatomic, readonly) BOOL bufferingsSatisfied;

// whether book-part is fully downloaded
@property (nonatomic, readonly) BOOL downloaded;

// used to start downloading when it has paused because of errors
-(void)ensureDownloading;

// return BookPart that combines self and otherPart returning nil
// if join is not possible. To be joinable the url's must
// match and self must end where otherPart starts.
-(BookPart*)partCombinedWith:(BookPart*)otherPart;

-(AVPlayerItem*)makePlayerItem;

-(void)deleteCache;

@end
