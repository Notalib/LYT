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
    
    // key is taskIdentifier and value is Downloader
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

-(NSURLSessionDownloadTask*)taskForStartedRequest:(NSURLRequest*)request
                                    forDownloader:(Downloader*)downloader {
    
    NSURLSessionDownloadTask* task = [sharedSession downloadTaskWithRequest: request];
    NSNumber* taskIdentifier = [NSNumber numberWithUnsignedInteger: task.taskIdentifier];
    [taskDownloaders setObject:downloader forKey:taskIdentifier];
    [task resume];
    return task;
}

-(void)endTask:(NSURLSessionTask*)task error:(NSError*)error location:(NSURL*)location {
    NSNumber* taskIdentifier = [NSNumber numberWithUnsignedInteger: task.taskIdentifier];
    Downloader* downloader = [taskDownloaders objectForKey:taskIdentifier];
    [downloader task:task endedWithError: error location:location];
    [taskDownloaders removeObjectForKey:taskIdentifier];
}

// cancel any task for the given downloader, without calling taskEndWithError:location:
-(void)cancelTask:(NSURLSessionTask*)task {
    NSNumber* taskIdentifier = [NSNumber numberWithUnsignedInteger: task.taskIdentifier];
    [taskDownloaders removeObjectForKey:taskIdentifier];
    [task cancel];
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

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                     didResumeAtOffset:(int64_t)fileOffset
                                    expectedTotalBytes:(int64_t)expectedTotalBytes {
    DBGLog(@"downloadTask: %@ didResumeAtOffset: %ld expectedTotalBytes: %ld",
           downloadTask.currentRequest.URL, (long)fileOffset, (long)expectedTotalBytes);
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

// not retained because held by downloader delegate
@property (nonatomic, weak) NSURLSessionTask* currentTask;

@end

@implementation Downloader
@synthesize progressBytes;

#define SessionConfigurationidentifier @"nu.nota.player.bgd-transfer"

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if([theKey isEqualToString:@"progressBytes"]) return NO;
    return [super automaticallyNotifiesObserversForKey:theKey];
}

static void (^backgroundSessionCompletionHandler)(void) = nil;

+(void)registerBackgroundSession:(NSString *)identifier
               completionHandler:(void (^)(void))completionHandler {
    if([identifier isEqualToString:SessionConfigurationidentifier]) {
        backgroundSessionCompletionHandler = [completionHandler copy];
    }
}

+(void)processBackgroundSessionCompletionHandler {
    void (^handler)(void) = backgroundSessionCompletionHandler;
    backgroundSessionCompletionHandler = nil;
    
    if(handler) {
        handler();
    }
}

+(DownloadDelegate*)sharedDelegate {
    if(!sharedDelegate) {
        sharedDelegate = [DownloadDelegate new];
        
        NSString* identifier = SessionConfigurationidentifier;
        if([NSURLSessionConfiguration respondsToSelector:@selector(backgroundSessionConfigurationWithIdentifier:)]) {
            sharedConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: identifier];
        } else {
            sharedConfig = [NSURLSessionConfiguration backgroundSessionConfiguration: identifier];
        }
        
        sharedConfig.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        
        sharedSession = [NSURLSession sessionWithConfiguration:sharedConfig
                                                      delegate:sharedDelegate delegateQueue:nil];
    }
    return sharedDelegate;
}



// cache path is dependent on URL and start only, such that all downloaders with the same URL x start
// share a cache file, furthermore care is taken to allow user-id to change without changing cache
// filename since anonymous (guest) users sometimes get a new user-id when they change network or
// some time has passed.
// URLs have the form:
//      http://m.e17.dk/DodpFiles/20005/37027/01_Michael_Kamp_Bunker_.mp3
//                                 UID   BID           PART
// where UID is user-id and BID is book-id. We want to make sure cache-filename is unchanged for
// fixed BID and PART.
-(NSString*)cachePath {
    NSString* cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;

    // we take the last two path components er entire path if there are less than two.
    NSArray* components = self.url.pathComponents;
    if(components.count > 2) {
        components = [components subarrayWithRange:NSMakeRange(components.count - 2, 2)];
    }
    NSString* basename = [components componentsJoinedByString:@"/"];
    NSString* stub = [basename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    stub = [stub stringByReplacingOccurrencesOfString:@"/" withString:@"-"];

    NSString* filename = [NSString stringWithFormat:@"%@-%ld", stub, (long)self.start];
    return [cacheDir stringByAppendingPathComponent:filename];
}

-(void)deleteCache {
    _end = self.start;
    [self cancelCurrentTask];
    
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

-(void)download {
    [self downloadNextChunk];
}

-(void)downloadNextChunk {
    // make sure we are only loading one chunk at a time
    if(isLoading) return;
    
    NSUInteger byteOffset = self.start + progressBytes;
    if(byteOffset >= self.end) return;
    NSUInteger bytesToRead = self.end - byteOffset;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
    
    NSString* range = [NSString stringWithFormat:@"bytes=%ld-%ld",
                       (long)byteOffset, (long)(byteOffset + bytesToRead)];
    [request addValue:range forHTTPHeaderField:@"Range"];
    
    isLoading = YES;
    self.currentTask = [[Downloader sharedDelegate] taskForStartedRequest:request
                                                            forDownloader:self];
    
    DBGLog(@"Downloading bytes %ld-%ld from %@", (long)byteOffset, (long)(byteOffset + bytesToRead),
           self.url.lastPathComponent);
}

-(void)cancelDownload {
    [self cancelCurrentTask];
}

-(void)cancelCurrentTask {
    if(self.currentTask) {
        [[Downloader sharedDelegate] cancelTask:self.currentTask];
    }
    isLoading = NO;
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

-(void)task:(NSURLSessionTask*)task endedWithError:(NSError*)error location:(NSURL*)location {
    if(self.currentTask != task) {
        DBGLog(@"Non-current task=%@ ended, this is weird", task.currentRequest.URL);
    } else {
        self.currentTask = nil;
    }
    
    self.error = error;
    
    if(!error && location) {
        isLoading = NO;
        NSData* data = [NSData dataWithContentsOfURL:location];
        BOOL ok = [self appendData:data toFile:self.cachePath];
        if(ok) {
            [self willChangeValueForKey:@"progressBytes"];
            progressBytes += data.length;
            [self didChangeValueForKey:@"progressBytes"];

            DBGLog(@"%ld bytes written to %@ for a total of %ld", (long)data.length, self.cachePath,
                  (long)progressBytes);
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
    return downloader;
}

+(Downloader*)downloadURL:(NSURL*)url {
    return [Downloader downloadURL:url start:0 end:NSIntegerMax];
}

@end
