//
//  DownloaderSession.h
//  player
//
//  Created by Anders Borum on 13/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ChunkSize (1024 * 64) 

@interface Downloader : NSObject <NSURLSessionDelegate>
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSUInteger start;
@property (nonatomic, assign) NSUInteger end; // must only be increased

// set end == NSUIntegerMax to download to end of file
+(Downloader*)downloadURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;
+(Downloader*)downloadURL:(NSURL*)url;

-(instancetype)initWithURL:(NSURL*)url start:(NSUInteger)start end:(NSUInteger)end;
-(void)taskEndWithError:(NSError*)error location:(NSURL*)location;

@end
