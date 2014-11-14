//
//  DownloaderSession.m
//  player
//
//  Created by Anders Borum on 13/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "Downloader.h"
#import "debug.h"

@interface DownloadDelegate : NSObject <NSURLSessionDelegate> {
    // key is [keyForURL: start:] and value is Downloader
    NSMutableDictionary* downloaders;
    
    // key is taskIdentifier amnd value is Downloader
    NSMutableDictionary* taskDownloaders;
}

-(Downloader*)ensureDownloaderForURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;

@end

static NSURLSessionConfiguration* sharedConfig = nil;
static NSURLSession* sharedSession = nil;
static DownloadDelegate* sharedDelegate = nil;

@implementation DownloadDelegate

-(instancetype)init {
    self = [super init];
    if(self) {
        downloaders = [NSMutableDictionary new];
        taskDownloaders = [NSMutableDictionary new];
    }
    return self;
}

-(NSString*)keyForURL:(NSURL*)url start:(NSUInteger)start {
    return [NSString stringWithFormat:@"%@-%ld", url.absoluteString, (long)start];
}

-(void)startRequest:(NSURLRequest*)request forDownloader:(Downloader*)downloader {
    
    NSURLSessionDownloadTask* task = [sharedSession downloadTaskWithRequest: request];
    NSNumber* taskIdentifier = [NSNumber numberWithUnsignedInteger: task.taskIdentifier];
    [taskDownloaders setObject:downloader forKey:taskIdentifier];
    [task resume];
}

-(void)endTask:(NSURLSessionTask*)task error:(NSError*)error location:(NSURL*)location {
    NSNumber* taskIdentifier = [NSNumber numberWithUnsignedInteger: task.taskIdentifier];
    Downloader* downloader = [taskDownloaders objectForKey:taskIdentifier];
    [downloader taskEndWithError: error location:location];
    [taskDownloaders removeObjectForKey:taskIdentifier];
}

-(Downloader*)ensureDownloaderForURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end {
    NSString* key = [self keyForURL:url start:start];
    Downloader* downloader = [downloaders objectForKey:key];
    if(!downloader) {
        downloader = [[Downloader alloc] initWithURL: url start:start end:end];
        [downloaders setObject:downloader forKey:key];
    } else {
        if(downloader.end < end) {
            downloader.end = end;
        }
    }
    return downloader;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    //DBGLog(@"URLSession:task: %@ didCompleteWithError: %@", task.currentRequest.URL, error);
    [self endTask:task error:error location:nil];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    //DBGLog(@"URLSession: dataTask: %@ didReceiveData: %ld bytes",
    //      dataTask.currentRequest.URL, (long)data.length);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    //DBGLog(@"URLSession:downloadTask: %@ didFinishDownloadingToURL: %@",
    //      downloadTask.currentRequest.URL, location);
    
    [self endTask:downloadTask error:nil location:location];
}

@end

@interface Downloader () {
    NSUInteger progressBytes; // how much we have read and stored in cache
    BOOL isLoading;
}

@end

@implementation Downloader
@synthesize progressBytes;

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if([theKey isEqualToString:@"progressBytes"]) return NO;
    return [super automaticallyNotifiesObserversForKey:theKey];
}

+(DownloadDelegate*)sharedDelegate {
    if(!sharedDelegate) {
        sharedDelegate = [DownloadDelegate new];
        
        NSString* identifier = @"nu.nota.player.bgd-transfer";
        sharedConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: identifier];
        sharedConfig.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        
        sharedSession = [NSURLSession sessionWithConfiguration:sharedConfig delegate:sharedDelegate delegateQueue:nil];
    }
    return sharedDelegate;
}

// cache path is dependent on URL and start only, such that all downloaders with the same URL x start
// share a cache file.
-(NSString*)cachePath {
    NSString* cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString* stub = [self.url.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* filename = [NSString stringWithFormat:@"%lx-%@-%ld", (unsigned long)self.url.hash,
                          stub, (long)self.start];
    return [cacheDir stringByAppendingPathComponent:filename];
}

-(void)deleteCache {
    [[NSFileManager defaultManager] removeItemAtPath:self.cachePath error:NULL];
    
    [self willChangeValueForKey:@"progressBytes"];
    progressBytes = 0;
    [self didChangeValueForKey:@"progressBytes"];
}

// check how much is already cached for the given
-(void)checkForContent {
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.cachePath error:NULL];
    NSNumber* fileSize = [attributes objectForKey:NSFileSize];
    
    [self willChangeValueForKey:@"progressBytes"];
    progressBytes = fileSize.unsignedIntegerValue;
    [self didChangeValueForKey:@"progressBytes"];
}

-(void)downloadNextChunk {
    // make sure we are only loading one chunk at a time
    if(isLoading) return;
    
    NSUInteger byteOffset = self.start + progressBytes;
    if(byteOffset >= self.end) return;
    NSUInteger bytesToRead = self.end - byteOffset;
    if(bytesToRead >= ChunkSize) bytesToRead = ChunkSize;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
    
    NSString* range = [NSString stringWithFormat:@"bytes=%ld-%ld",
                       (long)byteOffset, (long)(byteOffset + bytesToRead)];
    [request addValue:range forHTTPHeaderField:@"Range"];
    
    isLoading = YES;
    [[Downloader sharedDelegate] startRequest:request forDownloader:self];
}

- (BOOL)appendData:(NSData*)data toFile:(NSString*)path {
    BOOL result = YES;
    NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if ( !fh ) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    if ( !fh ) return NO;
    @try {
        [fh seekToEndOfFile];
        [fh writeData: data];
    }
    @catch (NSException * e) {
        result = NO;
    }
    [fh closeFile];
    return result;
}

-(void)taskEndWithError:(NSError*)error location:(NSURL*)location {
    self.error = error;
    
    if(!error && location) {
        isLoading = NO;
        NSData* data = [NSData dataWithContentsOfURL:location];
        BOOL ok = [self appendData:data toFile:self.cachePath];
        if(ok) {
            [self willChangeValueForKey:@"progressBytes"];
            progressBytes += data.length;
            [self didChangeValueForKey:@"progressBytes"];

            //NSLog(@"%ld bytes written to %@ for a total of %ld", (long)data.length, self.cachePath,
            //      (long)progressBytes);
            [self downloadNextChunk];
        }
    } else {
        isLoading = NO;
    }
}

-(instancetype)initWithURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end {
    self = [super init];
    if(self) {
        _url = url;
        _start = start;
        _end = end;
        
        [self checkForContent];
    }
    return self;
}

+(Downloader*)downloadURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end {
    Downloader* downloader = [[Downloader sharedDelegate] ensureDownloaderForURL:url start:start end:end];
    [downloader downloadNextChunk];
    
    return downloader;
}

+(Downloader*)downloadURL:(NSURL*)url {
    return [Downloader downloadURL:url start:0 end:NSUIntegerMax];
}

@end
