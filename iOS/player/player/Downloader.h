//
//  DownloaderSession.h
//  player
//
//  Created by Anders Borum on 13/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ChunkSize (1024 * 128) 

@interface Downloader : NSObject <NSURLSessionDelegate>
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSUInteger start;
@property (nonatomic, assign) NSUInteger end; 

// how much we have read and stored in cache, and nice to key-value-observe
@property (nonatomic, readonly) NSUInteger progressBytes;

// holds the last error from downloading
@property (nonatomic, strong) NSError* error;

// should be called from application:handleEventsForBackgroundURLSession:completionHandler:
+(void)registerBackgroundSession:(NSString *)identifier
               completionHandler:(void (^)(void))completionHandler;

// Called when ready to accept session events regarding background transfers.
// Can be called safely if there has been set no callback or multiple times,
// without the callback being called more than the first time.
// Should be called from the main thread.
+(void)processBackgroundSessionCompletionHandler;

// cache path is dependent on URL and start only, such that all downloaders
// with the same URL x start share a cache file.
@property (nonatomic, readonly) NSString* cachePath;

// start or continue downloading
-(void)download;

// can be called safely even when there is no download
-(void)cancelDownload;

// delete all cached files for this download
-(void)deleteCache;

// Instance with identical url and start should be shared when calling this multiple times.
// set end == NSIntegerMax to download to end of file.
+(Downloader*)downloadURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;
+(Downloader*)downloadURL:(NSURL*)url;

-(instancetype)initWithURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;

// called when task ends either in error (non-nil error) or success (non-nil location)
-(void)task:(NSURLSessionTask*)task endedWithError:(NSError*)error
                                          location:(NSURL*)cacheFileLocation;

@end
