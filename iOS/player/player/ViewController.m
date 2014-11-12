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

@interface ViewController () {
    NSArray* chunks;
    AVAudioPlayer* player;
    AVQueuePlayer* queuePlayer;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"shouldStartLoadWithRequest: %@, type: %d", request, (int)navigationType);
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad: %@", webView.request.URL);
    
    if([webView.request.URL.fragment isEqualToString:@"login"]) {
        /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self loadBookshelf];
        });*/
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView: %@ didFailLoadWithError: %@", webView.request.URL, error);
}

#pragma mark -

-(void)loadTestData {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"3_Grantret.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20017/36016/3_Grantret.mp3"];
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    chunks = [SoundChunk soundChunksForURL:url info:json];
    
    NSTimeInterval when = 175;
    SoundChunk* chunk = [SoundChunk lastBeforeTime:when chunks: chunks];
    
    NSURLRequest* request = [chunk makeRequest];
    NSLog(@"request = %@\n%@", request.URL, request.allHTTPHeaderFields);
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        NSLog(@"response = %@", response);
                               
        player = [[AVAudioPlayer alloc] initWithData:data error:NULL];
        //[player play];
        [player playAtTime: player.deviceCurrentTime + when - chunk.timeOffset];
    }];
}

-(void)testPlay {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"37027.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
    NSURL* baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20020/37027/"];
    Book* book = [Book bookFromDictionary:json baseURL:baseURL];
    [book joinParts];
    
    queuePlayer = [book makeQueuePlayer];
    [queuePlayer play];
}

-(void)loadBookshelf {
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/#bookshelf?guest=true"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //[self loadTestData];
    [self testPlay];
    
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/#login"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
