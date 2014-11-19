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
@property (nonatomic, assign) NSUInteger end; // must only be increased

// how much we have read and stored in cache
@property (nonatomic, readonly) NSUInteger progressBytes;

// cache path is dependent on URL and start only, such that all downloaders
// with the same URL x start share a cache file.
@property (nonatomic, readonly) NSString* cachePath;

// start or continue downloading
-(void)download;

-(void)deleteCache;

// how much we have read from network but perhaps not yet stored in cache
// TODO: Not yet implemented.
@property (nonatomic, readonly) NSUInteger progressBytesFetched;

// holds the last error from downloading
@property (nonatomic, strong) NSError* error;

// set end == NSUIntegerMax to download to end of file
+(Downloader*)downloadURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;
+(Downloader*)downloadURL:(NSURL*)url;

-(instancetype)initWithURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;
-(void)taskEndWithError:(NSError*)error location:(NSURL*)location;

@end
