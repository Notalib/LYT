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
#import "debug.h"

@interface BookPart () {
    NSUInteger byteOffset;
}

@property (nonatomic, strong) Downloader* downloader;

@end

@implementation BookPart

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if([theKey isEqualToString:@"bufferingsSatisfied"]) return NO;
    if([theKey isEqualToString:@"bufferingPoint"]) return NO;
    return [super automaticallyNotifiesObserversForKey:theKey];
}

// Determine the ending byte-offset of last chunk including the given time-offset
//
// DEBUG: This is a mockup implementation that just looks in local json files
-(void)determineOffset:(NSTimeInterval)timeOffset
              callback:(void (^)(NSUInteger byteOffset, NSError* error))block {
    
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
    
    NSDictionary* last = nil;
    for (NSDictionary* part in json) {
        NSNumber* timeOffsetNumber = [part objectForKey:@"timeOffset"];
        if(timeOffsetNumber.doubleValue >= timeOffset) break;
        
        last = part;
    }
    
    if(last) {
        NSNumber* byteOffsetNumber = [last objectForKey:@"byteOffset"];
        NSNumber* byteLengthNumber = [last objectForKey:@"byteLength"];
        NSUInteger endOffset = byteOffsetNumber.unsignedIntegerValue +
                               byteLengthNumber.unsignedIntegerValue;
        
        block(endOffset, nil);
    } else {
        NSString* message = [NSString stringWithFormat:@"Unable to find timeOffset=%f in %@", timeOffset, self];
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey: message};
        NSError* error = [NSError errorWithDomain:@"DEBUG" code:0 userInfo:userInfo];
        block(0, error);
    }
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %.3f-%.3f", self.url.lastPathComponent, self.start, self.end];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"progressBytes"]) {
        [self downloadMore];
    } else if([keyPath isEqualToString:@"error"]) {
        Downloader* d = object;
        self.error = d.error;
    }
}

-(void)setBufferingsSatisfied:(BOOL)bufferingsSatisfied {
    if(_bufferingsSatisfied == bufferingsSatisfied) return;
    
    [self willChangeValueForKey:@"bufferingsSatisfied"];
    _bufferingsSatisfied = bufferingsSatisfied;
    [self didChangeValueForKey:@"bufferingsSatisfied"];
}

-(void)setDownloader:(Downloader *)downloader {
    if(downloader == _downloader) return;
    
    [_downloader removeObserver:self forKeyPath:@"progressBytes"];
    [_downloader removeObserver:self forKeyPath:@"error"];
    _downloader = downloader;
    [_downloader addObserver:self forKeyPath:@"error" options:0 context:NULL];
    [_downloader addObserver:self forKeyPath:@"progressBytes" options:0 context:NULL];
}

-(void)setBufferingPoint:(NSTimeInterval)wantedBufferingPoint {
    NSTimeInterval bufferingPoint = fmin(wantedBufferingPoint, self.end);
    if(_bufferingPoint == bufferingPoint) return;
    
    [self willChangeValueForKey:@"bufferingPoint"];
    _bufferingPoint = bufferingPoint;
    [self didChangeValueForKey:@"bufferingPoint"];
    
    self.bufferingsSatisfied = NO;
    [self determineOffset:bufferingPoint callback:^(NSUInteger theByteOffset, NSError* error) {
        if(!error) {
            byteOffset = theByteOffset;
            [self downloadMore];
        }
    }];
}

-(void)downloadMore {
    //DBGLog(@"%@: bytes = %ld, wantedBytes=%ld", self,
    //       (long)self.downloader.progressBytes, (long)(byteOffset));
    
    self.bufferingsSatisfied = self.downloader.progressBytes >= byteOffset;
    if(self.bufferingsSatisfied) return;
    
    NSUInteger bytesToRead = byteOffset - self.downloader.progressBytes;
    if(bytesToRead > ChunkSize) {
        bytesToRead = ChunkSize;
    }
    
    NSUInteger end = self.downloader.progressBytes + bytesToRead;
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

-(NSString*)cachePath {
    return self.downloader.cachePath;
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
