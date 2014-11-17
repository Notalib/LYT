//
//  BridgeController.m
//  player
//
//  Created by Anders Borum on 17/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "BridgeController.h"
#import "debug.h"

@interface BridgeController () {
    // used to make sure we do not inject javascript indefintely
    NSMutableDictionary* urlBeingLoaded;
    
    NSString* _javascriptFromBundle;
}

@end

@implementation BridgeController 

-(NSString*)javascriptFromBundle {
    if(!_javascriptFromBundle) {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"bridge.js" ofType:nil];
        NSData* data = [NSData dataWithContentsOfFile:path];
        _javascriptFromBundle = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return _javascriptFromBundle;
}

-(NSString*)javascriptEscapedJSON:(id)json {
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
    NSString* unescaped = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // we escape backslash, quote, newline and tab to fit inside regular string
    NSMutableString* encoded = [NSMutableString stringWithString:unescaped];
    [encoded replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, encoded.length)];
    
    return encoded;
}

// Expecting javascript function on the form:
//   function notaMessage(payload) {
//     var packet = JSON.parse(payload);
//     ...
//   }
-(void)sendPacket:(NSDictionary*)packet toWebView:(UIWebView*)webView {
    NSString* encoded = [self javascriptEscapedJSON:packet];
    NSString* javascript = [NSString stringWithFormat:@"notaMessage(\"%@\");", encoded];
    [webView stringByEvaluatingJavaScriptFromString: javascript];
}


-(void)refreshBooksInWebView:(UIWebView*)webView {
    NSArray* state = self.delegate.booksState;
    NSString* statement = [NSString stringWithFormat:@"window.lytBridge._books = JSON.parse(\"%@\");",
                           [self javascriptEscapedJSON:state]];
    [webView stringByEvaluatingJavaScriptFromString: statement];
}

-(void)processCommandName:(NSString*)name arguments:(NSArray*)arguments
                  webView:(UIWebView*)webView {
    DBGLog(@"%@ (%@)", name, arguments);
    
    if([name isEqualToString:@"setBook"]) {
        id info = arguments.firstObject;
        if(info) {
            [self.delegate setBook:info];
            [self refreshBooksInWebView:webView];
            return;
        }
    } else if([name isEqualToString:@"clearBook"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate clearBook:bookId];
            [self refreshBooksInWebView:webView];
            return;
        }
    } else if([name isEqualToString:@"play"]) {
        NSString* bookId = [arguments.firstObject description];
        NSNumber* offset = arguments.lastObject;
        
        if([bookId isKindOfClass:[NSString class]] && [offset isKindOfClass:[NSNumber class]]) {
            [self.delegate play:bookId offset:offset.doubleValue];
            return;
        }
    } else if([name isEqualToString:@"stop"]) {
        [self.delegate stop];
        return;
    } else if([name isEqualToString:@"cacheBook"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate cacheBook:bookId];
            return;
        }
    } else if([name isEqualToString:@"clearBookCache"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate clearBookCache:bookId];
            return;
        }
    }
    
    NSLog(@"Unable to process command: %@\n%@", name, arguments);
}

-(void)processCommands:(NSArray*)commands webView:(UIWebView*)webView {
    for (NSArray* command in commands) {
        // we ignore vadly formatted command objects, that we do not know hot to handle
        if(![command isKindOfClass:[NSArray class]] || command.count != 2) continue;
        
        NSString* name = [command objectAtIndex:0];
        NSArray* payload = [command objectAtIndex:1];
        if(![name isKindOfClass:[NSString class]] || ![payload isKindOfClass:[NSArray class]]) {
            continue;
        }
        
        [self processCommandName:name arguments:payload webView:webView];
    }
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    DBGLog(@"shouldStartLoadWithRequest: %@, type: %d", request, (int)navigationType);
    
    // handle notifications using nota: scheme
    NSString* scheme = request.URL.scheme;
    if([scheme isEqualToString:@"nota"]) {
        NSString* queue = [webView stringByEvaluatingJavaScriptFromString: @"window.lytBridge._consumeCommands();"];
        NSData* data = [queue dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        [self processCommands:json webView:webView];
        
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
                               NSString* script = [NSString stringWithFormat:@"<script>\n%@\n</script>", javascript];
                               NSString* replacement = [script stringByAppendingString:@"\n</head>"];
                               
                               // we inject javascript before end of <head> tag
                               content = [content stringByReplacingOccurrencesOfString:@"</head>" withString:replacement];
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

@end
