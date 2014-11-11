//
//  ViewController.m
//  player
//
//  Created by Anders Borum on 11/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"

@interface ViewController () {
    NSArray* chunks;
    AVAudioPlayer* player;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"shouldStartLoadWithRequest: %@, type: %d", request, navigationType);
    return YES;
}

#pragma mark -

-(NSMutableURLRequest*)requestForURL:(NSURL*)url chunk:(NSDictionary*)chunk {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    NSNumber* timeOffset = [chunk objectForKey:@"byteOffset"];
    NSNumber* byteLength = [chunk objectForKey:@"byteLength"];
    
    NSString* contentRange = [NSString stringWithFormat:@"bytes=%ld-%ld", timeOffset.longValue,
                              timeOffset.longValue + byteLength.longValue];
    [request addValue:contentRange forHTTPHeaderField:@"Range"];
    return request;
}

-(NSDictionary*)chunkBeforeTime:(NSTimeInterval)time {
    NSDictionary* best = nil;
    for (NSDictionary* chunk in chunks) {
        NSNumber* timeOffset = [chunk objectForKey:@"timeOffset"];
        if(timeOffset.doubleValue > time) break;
        if(timeOffset && timeOffset.doubleValue < time) {
            best = chunk;
        }
    }
    return best;
}

-(NSDictionary*)chunkAfterTime:(NSTimeInterval)time {
    for (NSDictionary* chunk in chunks) {
        NSNumber* timeOffset = [chunk objectForKey:@"timeOffset"];
        if(timeOffset && timeOffset.doubleValue >= time) {
            return chunk;
        }
    }
    return nil;
}

-(void)loadTestData {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"3_Grantret.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    
    NSError* error = NULL;
   chunks = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSLog(@"chunks = %@", chunks == nil ? error : chunks);
    
    NSTimeInterval when = 100;
    NSDictionary* chunk = [self chunkBeforeTime:when];
    NSLog(@"chunk before %f: %@", when, chunk);
    NSLog(@"chunk after %f: %@", when, [self chunkAfterTime:when]);
    
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20017/36016/3_Grantret.mp3"];
    NSURLRequest* request = [self requestForURL:url chunk:chunk];
    NSLog(@"request = %@\n%@", request.URL, request.allHTTPHeaderFields);
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        NSLog(@"response = %@", response);
                               
        player = [[AVAudioPlayer alloc] initWithData:data error:NULL];
        [player play];
    }];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self loadTestData];
    
    NSURL* url = [NSURL URLWithString:@"http://vps.algoritmer.dk/player.html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    //[self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
