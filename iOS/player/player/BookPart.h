//
//  BookPart.h
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BookPart : NSObject
@property (nonatomic, strong) NSURL* url;

// cache path is dependent on URL and start only, such that all downloaders
// with the same URL x start share a cache file.
@property (nonatomic, readonly) NSString* cachePath;

// holds the last error from downloading
@property (nonatomic, strong) NSError* error;

// start and end are measured in seconds
@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;

// BookPart should try to keep its buffer filled to this many seconds,
// whch can be set to very large number to buffer entire BookPart.
@property (nonatomic, assign) NSTimeInterval bufferingPoint;

// Whether bufffer is filled up to the point wanted by bufferingPoint.
// You should probably KVO observe this property.
@property (nonatomic, readonly) BOOL bufferingsSatisfied;

// return BookPart that combines self and otherPart returning nil
// if join is not possible. To be joinable the url's must
// match and self must end where otherPart starts.
-(BookPart*)partCombinedWith:(BookPart*)otherPart;

-(AVPlayerItem*)makePlayerItem;

-(void)deleteCache;

@end
