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
#import "debug.h"

@interface ViewController () {
    NSArray* chunks;
    AVAudioPlayer* player;
    AVQueuePlayer* queuePlayer;
    
    Book* book;
    
    // used to make sure we do not inject javascript indefintely
    NSMutableDictionary* urlBeingLoaded;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

// Expecting javascript function on the form:
//   function notaMessage(payload) {
//     var packet = JSON.parse(payload);
//     ...
//   }
-(void)sendPacket:(NSDictionary*)packet {
    NSData* data = [NSJSONSerialization dataWithJSONObject: packet options:0 error:NULL];
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // we escape backslash, quote, newline and tab to fit inside regular string
    NSMutableString* encoded = [NSMutableString stringWithString:json];
    [encoded replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, encoded.length)];
    
    NSString* javascript = [NSString stringWithFormat:@"notaMessage(\"%@\");", encoded];
    [self.webView stringByEvaluatingJavaScriptFromString: javascript];
}

-(NSString*)javascriptFromBundle {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"bridge.js" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    DBGLog(@"shouldStartLoadWithRequest: %@, type: %d", request, (int)navigationType);

    // handle notifications using nota: scheme
    NSString* scheme = request.URL.scheme;
    if([scheme isEqualToString:@"nota"]) {
        NSString* payload = [request.URL.fragment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData* data = [payload dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSLog(@"%@:\n%@", request.URL, json == nil ? error : json);
        
        NSDictionary* packet = @{@"alert" : @"Hello world"};
        [self sendPacket:packet];
        
        return NO;
    }
    
    // inject javascript into request, by loading it ourselves, taking care not to keep doing this
    if([urlBeingLoaded objectForKey:request.URL.absoluteString]) return YES;
    if(!urlBeingLoaded) urlBeingLoaded = [NSMutableDictionary new];
    [urlBeingLoaded setObject:request.URL forKey:request.URL.absoluteString];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        //[urlBeingLoaded removeObjectForKey:request.URL.absoluteString];
                               
        NSString* content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString* javascript = self.javascriptFromBundle;
        NSString* script = [NSString stringWithFormat:@"<script>%@</script>", javascript];

        // we inject javascript before end of <head> tag
        content = [content stringByReplacingOccurrencesOfString:@"</head>"
                                                     withString:[script stringByAppendingString:@"\n</head>"]];
        [webView loadHTMLString:content baseURL:request.URL];
    }];
    return NO;
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    DBGLog(@"webViewDidFinishLoad: %@", webView.request.URL);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView: %@ didFailLoadWithError: %@", webView.request.URL, error);
}

#pragma mark -

-(void)loadTestBook {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"37027.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
    NSURL* baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20014/37027/"];
    book = [Book bookFromDictionary:json baseURL:baseURL];
    [book joinParts];
}

-(void)testPlay {
    queuePlayer = [book makeQueuePlayer];
    [queuePlayer play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"play error: %@", queuePlayer.error);
    });
}

-(void)testDownload {
    [book deleteCache];
    book.bufferLookahead = 300;
    [book play];
}

-(void)loadBookshelf {
    NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/#bookshelf?guest=true"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self loadTestBook];
    //[self testPlay];
    [self testDownload];
    
    //NSURL* url = [NSURL URLWithString:@"http://m.e17.dk/#login"];
    NSURL* url = [NSURL URLWithString:@"http://vps.algoritmer.dk/nota.html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
