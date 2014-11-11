//
//  SoundChunk.h
//  player
//
//  Created by Anders Borum on 11/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundChunk : NSObject
@property (nonatomic, strong) NSURL* url;

@property (nonatomic, assign) NSTimeInterval timeOffset;
@property (nonatomic, assign) NSTimeInterval timeDuration;

@property (nonatomic, assign) NSUInteger byteOffset;
@property (nonatomic, assign) NSUInteger byteLength;

-(NSMutableURLRequest*)makeRequest;

// Get the chunk that covers the given moment in time (in seconds) or nil if
// not found. We assume that chunks is sorted array of SoundChunk elements.
+(SoundChunk*)lastBeforeTime:(NSTimeInterval)time chunks:(NSArray*)chunks;

// used for debugging purposes, info is array of dictionaries such as:
//     {"byteOffset": 1741636, "timeOffset": 108.826, "byteLength": 102400, "timeDuration": 6.400 }
+(NSArray*)soundChunksForURL:(NSURL*)url info:(NSArray*)info;

@end
