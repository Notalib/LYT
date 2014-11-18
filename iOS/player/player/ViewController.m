//
//  ViewController.m
//  player
//
//  Created by Anders Borum on 11/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "SoundChunk.h"
#import "Book.h"
#import "BookPart.h"
#import "BridgeController.h"
#import "debug.h"

@interface ViewController () {
    NSArray* chunks;
    AVAudioPlayer* player;
    AVQueuePlayer* queuePlayer;

    BridgeController* bridge;
    
    Book* testBook;
    
    NSMutableDictionary* booksById;
    NSMutableSet* booksDownloading; // books we are downloading in their entirety
    NSString* currentBookId; // the playing book is always current, but the current book might not be playing
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

#pragma mark LytDeviceProtocol

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"error"]) {
        Book* book = object;
        NSError* error = book.error;
        if(error) {
            NSString* message = error.localizedDescription;
            if([error.domain isEqualToString:NSURLErrorDomain]) {
                if(error.code == kCFURLErrorUserAuthenticationRequired) {
                    message = NSLocalizedString(@"Authentication required", nil);
                }
            }
            
            [bridge downloadBook: book.identifier failed:message];
        }
    } else if([keyPath isEqualToString:@"isPlaying"]) {
        Book* book = object;
        
        // book must have ended and be very close to end
        if(!book.isPlaying && book.position >= book.duration - 1.0) {
            [bridge endBook: book.identifier];
        }
    }
}

-(void)sendBookUpdate {
    Book* book = self.currentBook;
    if(book) {
        [bridge updateBook:book.identifier offset:book.position];
    }
    
    // we schedule update while book is playing
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendBookUpdate) object:nil];
    if(book.isPlaying) {
        [self performSelector:@selector(sendBookUpdate) withObject:nil afterDelay:0.1];
    }
}

-(void)sendDownloadUpdates {
    for (Book* book in booksDownloading.allObjects) {
        if(book.downloaded) {
            [bridge completedDownloadBook:book.identifier timestamp:[NSDate date]];
        } else {
            CGFloat progress = book.ensuredBufferingPoint / book.duration;
            CGFloat percent = 100.0 * progress;
            [bridge downloadBook:book.identifier progress:percent];
        }
        
        // stop following book not either playing or downloading
        if(!book.downloading && !book.isPlaying) {
            [booksDownloading removeObject:book];
        }
    }
    
    // schedule on one second if there is anything still downloading
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDownloadUpdates) object:nil];
    if(booksDownloading.count > 0) {
        [self performSelector:@selector(sendDownloadUpdates) withObject:nil afterDelay:1];
    }
}

-(NSArray*)booksState {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:booksById.count];
    for (Book* book in booksById.allValues) {
        NSDictionary* info = @{@"id": book.identifier, @"offset": @(book.position),
                               @"downloaded": @(book.downloaded)};
        [array addObject:info];
    }
    return array;
}

-(Book*)currentBook {
    if(currentBookId == nil) return nil;
    return [booksById objectForKey:currentBookId];
}

-(void)setBook:(id)bookData {
    NSURL* baseURL = nil;//[NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20012/37027/"];
    NSDictionary* dict = nil;
    if([bookData isKindOfClass:[NSDictionary class]]) {
        dict = (NSDictionary*)bookData;
    } else if([bookData isKindOfClass:[NSString class]]) {
        // book-data can be double-wrapped as JSON
        NSString* string = (NSString*)bookData;
        NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if(![dict isKindOfClass:[NSDictionary class]]) dict = nil;
    }
    
    if(!dict) return;
    
    Book* book = [Book bookFromDictionary:dict baseURL:baseURL];
    [book joinParts];
    //[book deleteCache];
    book.bufferLookahead = 20;
    
    NSString* key = book.identifier;
    if(key) {
        [self clearBook:key];
        [booksById setObject:book forKey:key];
        
        [book addObserver:self forKeyPath:@"isPlaying" options:0 context:NULL];
        [book addObserver:self forKeyPath:@"error" options:0 context:NULL];
    }
}

-(void)clearBook:(NSString*)bookId {
    if(bookId) {
        Book* book = [booksById objectForKey:bookId];
        [book removeObserver:self forKeyPath:@"isPlaying"];
        [book removeObserver:self forKeyPath:@"error"];
        
        [book stop];
        [book deleteCache];
        [booksById removeObjectForKey:bookId];
    }
}

-(void)clearAllBooks {
    for (Book* book in booksById.allValues) {
        [self clearBook:book.identifier];
    }
}

-(void)play:(NSString*)bookId offset:(NSTimeInterval)offset {
    Book* oldBook = self.currentBook;
    if(![oldBook.identifier isEqualToString:bookId]) {
        [oldBook stop];
    }
    
    Book* book = [booksById objectForKey:bookId];
    currentBookId = book.identifier; // if bookId was not valid, book.identifier will be nil, which is wanted behaviour
    if(offset >= 0.0) {
        // negative offsets mean current position
        book.position = offset;
    }
    [book play];
    [self sendBookUpdate];
    [self sendDownloadUpdates];
}

-(void)stop {
    Book* oldBook = self.currentBook;
    [oldBook stop];
}

-(void)cacheBook:(NSString*)bookId {
    Book* book = [booksById objectForKey:bookId];
    book.bufferLookahead = 999999;
    
    if(!booksDownloading) {
        booksDownloading = [NSMutableSet new];
    }
    [booksDownloading addObject:book];
    [self sendDownloadUpdates];
}

-(void)clearBookCache:(NSString*)bookId {
    Book* book = [booksById objectForKey:bookId];
    if(book) {
        [booksDownloading removeObject:book];
        [book deleteCache];
    }
}

#pragma mark -

-(void)loadTestBook {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"37027.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
    NSURL* baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20014/37027/"];
    testBook = [Book bookFromDictionary:json baseURL:baseURL];
    [testBook joinParts];
}

-(void)testPlay {
    queuePlayer = [testBook makeQueuePlayer];
    [queuePlayer play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"play error: %@", queuePlayer.error);
    });
}

-(void)testDownload {
    [testBook deleteCache];
    testBook.bufferLookahead = 300;
    [testBook play];
}

-(void)loadBookshelf {
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/#bookshelf?guest=true"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    booksById = [NSMutableDictionary new];
    bridge = [BridgeController new];
    bridge.delegate = self;
    bridge.webView = self.webView;
    self.webView.delegate = bridge;
        
    // NSURL* url = [NSURL URLWithString:@"http://vps.algoritmer.dk/nota.html"];
    NSURL* url = [NSURL URLWithString:@"http://test.m.e17.dk/msn/lyt-3.0/"];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

@end
