//
//  SoundChunk.m
//  player
//
//  Created by Anders Borum on 11/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "SoundChunk.h"

@implementation SoundChunk

-(NSMutableURLRequest*)makeRequest {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
    
    NSString* contentRange = [NSString stringWithFormat:@"bytes=%ld-%ld", (long)self.byteOffset,
                              (long)(self.byteOffset + self.byteLength)];
    [request addValue:contentRange forHTTPHeaderField:@"Range"];
    return request;
}

+(SoundChunk*)lastBeforeTime:(NSTimeInterval)time chunks:(NSArray*)chunks {
    SoundChunk* best = nil;
    for (SoundChunk* chunk in chunks) {
        if(chunk.timeOffset <= time) best = chunk;
        if(chunk.timeOffset >= time) break;
    }
    return best;
}

+(NSArray*)soundChunksForURL:(NSURL*)url info:(NSArray*)infos {
    NSMutableArray* chunks = [NSMutableArray arrayWithCapacity:infos.count];
    for (NSDictionary* info in infos) {
        NSNumber* byteOffset = info[@"byteOffset"];
        NSNumber* timeOffset = info[@"timeOffset"];
        NSNumber* byteLength = info[@"byteLength"];
        NSNumber* timeDuration = info[@"timeDuration"];
        
        SoundChunk* chunk = [SoundChunk new];
        chunk.url = url;
        chunk.timeOffset = timeOffset.doubleValue;
        chunk.timeDuration = timeDuration.doubleValue;
        chunk.byteOffset = byteOffset.unsignedIntegerValue;
        chunk.byteLength = byteLength.unsignedIntegerValue;
        
        [chunks addObject:chunk];
    }
    return chunks;
}

@end
