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
#import "BookManager.h"
#import "debug.h"

@interface ViewController () {
    NSArray* chunks;
    AVAudioPlayer* player;
    AVQueuePlayer* queuePlayer;

    BookManager* manager;
    BridgeController* bridge;
    
    Book* testBook;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController
@synthesize manager;

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
    
    bridge = [BridgeController new];
    manager = [BookManager new];
    //manager.baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20001/37027/"];
    manager.bridge = bridge;
    bridge.webView = self.webView;
    self.webView.delegate = bridge;
    [manager ready];
        
    NSURL* url = [NSURL URLWithString:@"http://test.m.e17.dk/lyt-3.0-prealpha/#/bookshelf"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

@end
