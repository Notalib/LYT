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
    // ending position in bytes where we stop loading
    NSUInteger byteOffset;
}

@property (nonatomic, strong) Downloader* downloader;

@end

@implementation BookPart

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if([theKey isEqualToString:@"bufferingsSatisfied"]) return NO;
    if([theKey isEqualToString:@"bufferingPoint"]) return NO;
    if([theKey isEqualToString:@"ensuredBufferingPoint"]) return NO;
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
    NSArray* json = data == nil ? nil : [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self downloadMore];
        });
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
    NSTimeInterval bufferingPoint = fmax(0, fmin(wantedBufferingPoint, self.end));
    if(_bufferingPoint == bufferingPoint) {
        [self downloadMore];
        return;
    }
    
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

// update buffering values, returning whether we are done reading
-(BOOL)checkBufferingPoint {
    // we can set buffering point when we are all done with chunk,
    // since we then have mapping between seconds and bytes (all byes has all seconds)
    if(self.downloader.progressBytes >= byteOffset) {
        if(_ensuredBufferingPoint != self.bufferingPoint) {
            [self willChangeValueForKey:@"ensuredBufferingPoint"];
            _ensuredBufferingPoint = self.bufferingPoint;
            [self didChangeValueForKey:@"ensuredBufferingPoint"];
        }
    } else {
        // we estimate how far we are in time, be assuming byte/second ratio is constant
        double ratio = (double)self.downloader.progressBytes / (double)byteOffset;
        NSTimeInterval secs = floor(ratio * self.duration); // we round down to be a little conservative
        if(secs > _ensuredBufferingPoint) {
            [self willChangeValueForKey:@"ensuredBufferingPoint"];
            _ensuredBufferingPoint = secs;
            [self didChangeValueForKey:@"ensuredBufferingPoint"];
        }
    }
    
    self.bufferingsSatisfied = self.downloader.progressBytes >= byteOffset;
    return self.bufferingsSatisfied;
}

-(void)setChunked:(BOOL)chunked {
    if(_chunked == chunked) return;
    
    _chunked = chunked;
    [self.downloader cancelDownload];
}

-(void)downloadMore {
    //DBGLog(@"%@: bytes = %ld, wantedBytes=%ld", self,
    //       (long)self.downloader.progressBytes, (long)(byteOffset));

    if([self checkBufferingPoint]) return;
    
    NSUInteger bytesToRead = byteOffset - self.downloader.progressBytes;
    if(self.chunked && bytesToRead > ChunkSize) {
        bytesToRead = ChunkSize;
    }
    
    NSUInteger end = self.downloader.progressBytes + bytesToRead;
    self.downloader = [Downloader downloadURL:self.url start:0 end:end];
    [self.downloader download];
    
    // downloader might already by satisfied by reading from cache,
    // and we want to know this right now
    [self checkBufferingPoint];
}

-(void)ensureDownloading {
    [self downloadMore];
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
    _ensuredBufferingPoint = self.bufferingPoint = 0;
    byteOffset = 0;
    [self.downloader deleteCache];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if(self.url) [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeDouble:self.start forKey:@"start"];
    [aCoder encodeDouble:self.end forKey:@"end"];
    [aCoder encodeDouble:self.bufferingPoint forKey:@"buffering"];
    [aCoder encodeBool:self.chunked forKey:@"chunked"];
    [aCoder encodeInteger:byteOffset forKey:@"byteOffset"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        self.url = [aDecoder decodeObjectForKey:@"url"];
        self.start = [aDecoder decodeDoubleForKey:@"start"];
        self.end = [aDecoder decodeDoubleForKey:@"end"];
        self.chunked = [aDecoder decodeBoolForKey:@"chunked"];
        byteOffset = [aDecoder decodeIntegerForKey:@"byteOffset"];
        
        // we set buffering as the last one, as this has consequences and will
        // make BookPart read from cache or network.
        self.bufferingPoint = [aDecoder decodeDoubleForKey:@"buffering"];
    }
    return self;
}

-(void)dealloc {
    [self setDownloader: nil];
}

-(NSTimeInterval)duration {
    return self.end - self.start;
}

-(BOOL)downloaded {
    return self.bufferingsSatisfied && self.bufferingPoint >= self.duration;
}

@end
