//
//  BookPart.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "BookPart.h"
#import "Downloader.h"

@interface BookPart () {
    NSUInteger byteOffset;
}

@property (nonatomic, strong) Downloader* downloader;

@end

@implementation BookPart

// Determine the byte-offset of last chunk including the givem time-offset
//
// DEBUG: This is a mockup implementation that just looks in local json files
-(void)determineOffset:(NSTimeInterval)timeOffset callback:(void (^)(NSUInteger byteOffset, NSError* error))block {
    
    NSString* filename = [self.url.lastPathComponent stringByDeletingPathExtension];
    NSString* path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    NSError* error = nil;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(!json) {
        NSLog(@"Unable to decode json: %@\n%@", error,
              [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        block(0, error);
        return;
    }
    
    for (NSDictionary* part in json) {
        NSNumber* byteOffsetNumber = [part objectForKey:@"byteOffset"];
        NSNumber* timeOffsetNumber = [part objectForKey:@"timeOffset"];
        NSNumber* timeDurationNumber = [part objectForKey:@"timeDuration"];

        if(timeOffsetNumber.doubleValue >= timeOffset) break;
        if(timeOffsetNumber.doubleValue + timeDurationNumber.doubleValue > timeOffset) {
            block(byteOffsetNumber.unsignedIntegerValue, nil);
            return;
        }
    }
    
    block(0, nil);
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %.3f-%.3f", self.url.lastPathComponent, self.start, self.end];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"progressBytes"]) {
        [self downloadMore];
    } else if([keyPath isEqualToString:@"error"]) {
        
    }
}

-(void)setDownloader:(Downloader *)downloader {
    if(downloader == _downloader) return;
    
    [_downloader removeObserver:self forKeyPath:@"progressBytes"];
    [_downloader removeObserver:self forKeyPath:@"error"];
    _downloader = downloader;
    [_downloader addObserver:self forKeyPath:@"error" options:0 context:NULL];
    [_downloader addObserver:self forKeyPath:@"progressBytes" options:0 context:NULL];
}

-(void)setBufferingPoint:(NSTimeInterval)bufferingPoint {
    _bufferingPoint = bufferingPoint;
    
    [self determineOffset:bufferingPoint callback:^(NSUInteger theByteOffset, NSError* error) {
        if(!error) {
            byteOffset = theByteOffset;
            [self downloadMore];
        }
    }];
}

-(void)downloadMore {
    if(self.downloader.progressBytes >= byteOffset) return;
    
    NSUInteger bytesRemaining = byteOffset - self.downloader.progressBytes;
    if(bytesRemaining > ChunkSize) {
        bytesRemaining = ChunkSize;
    }
    
    NSUInteger end = self.downloader.progressBytes + bytesRemaining;
    self.downloader = [Downloader downloadURL:self.url start:0 end:end];
}

-(BookPart*)partCombinedWith:(BookPart*)otherPart {
    // url's must match
    if(![self.url isEqual:otherPart.url]) return nil;
    
    // they must lie end-to-end
    if(self.end != otherPart.start) return nil;
    
    // join is allowed
    BookPart* joined = [BookPart new];
    joined.url = self.url;
    joined.start = self.start;
    joined.end = otherPart.end;
    return joined;
}

-(AVPlayerItem*)makePlayerItem {
    AVAsset* asset = [AVAsset assetWithURL:self.url];
    return [[AVPlayerItem alloc] initWithAsset:asset];
}

-(void)deleteCache {
    self.downloader = [Downloader downloadURL:self.url start:0 end:0];
    [self.downloader deleteCache];
}

-(void)dealloc {
    [self setDownloader: nil];
}

@end
