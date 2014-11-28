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
    NSDateFormatter* iso8601Formatter;
}

@end

@implementation BridgeController

-(instancetype)init {
    self = [super init];
    if(self) {
        iso8601Formatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [iso8601Formatter setLocale:enUSPOSIXLocale];
        [iso8601Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        
        // enable local storage in webviews
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitStoreWebDataForBackup"];
    }
    return self;
}

// turns a string such as hej"sa into hej\"sa but does not wrap in quotes
-(NSString*)escapeJavascriptString:(NSString*)unescaped {
    NSMutableString* encoded = [NSMutableString stringWithString:unescaped];
    [encoded replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, encoded.length)];
    [encoded replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, encoded.length)];
    
    return encoded;
}

-(NSString*)javascriptEscapedJSON:(id)json {
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
    NSString* unescaped = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [self escapeJavascriptString: unescaped];
}

// Expecting javascript function on the form:
//   function notaMessage(payload) {
//     var packet = JSON.parse(payload);
//     ...
//   }
-(void)sendPacket:(NSDictionary*)packet  {
    NSString* encoded = [self javascriptEscapedJSON:packet];
    NSString* javascript = [NSString stringWithFormat:@"notaMessage(\"%@\");", encoded];
    [self.webView stringByEvaluatingJavaScriptFromString: javascript];
}

-(void)refreshBooks {
    NSArray* state = self.delegate.booksState;
    NSString* statement = [NSString stringWithFormat:@"window.lytBridge._books = JSON.parse(\"%@\");",
                           [self javascriptEscapedJSON:state]];
    [self.webView stringByEvaluatingJavaScriptFromString: statement];
}

-(void)processCommandName:(NSString*)name arguments:(NSArray*)arguments {
    DBGLog(@"%@()", name);
    //DBGLog(@"%@ (%@)", name, arguments);
    
    if([name isEqualToString:@"setBook"]) {
        id info = arguments.firstObject;
        if(info) {
            [self.delegate setBook:info];
            [self refreshBooks];
            return;
        }
    } else if([name isEqualToString:@"clearBook"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate clearBook:bookId];
            [self refreshBooks];
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
        [self refreshBooks];
        return;
    } else if([name isEqualToString:@"cacheBook"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate cacheBook:bookId];
            return;
        }
    } else if([name isEqualToString:@"cancelBookCaching"]) {
        NSString* bookId = [arguments.firstObject description];
        if([bookId isKindOfClass:[NSString class]]) {
            [self.delegate cancelBookCaching:bookId];
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

-(void)processCommands:(NSArray*)commands {
    for (NSArray* command in commands) {
        // we ignore vadly formatted command objects, that we do not know hot to handle
        if(![command isKindOfClass:[NSArray class]] || command.count != 2) continue;
        
        NSString* name = [command objectAtIndex:0];
        NSArray* payload = [command objectAtIndex:1];
        if(![name isKindOfClass:[NSString class]] || ![payload isKindOfClass:[NSArray class]]) {
            continue;
        }
        
        [self processCommandName:name arguments:payload];
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
        [self processCommands:json];
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    DBGLog(@"webViewDidFinishLoad: %@", webView.request.URL);
    [self refreshBooks];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView: %@ didFailLoadWithError: %@", webView.request.URL, error);
}

#pragma mark Events

-(void)deliverEvent:(NSString*)eventName payload:(NSArray*)parameters {
    //DBGLog(@"deliverEvent(%@): %@", eventName, parameters);
    
    NSMutableString* javascript = [NSMutableString stringWithFormat:@"lytHandleEvent(\"%@\"",
                                   [self escapeJavascriptString:eventName]];

    for (id parameter in parameters) {
        [javascript appendString:@", "];
        
        // we want to encode JSON fragments, which is easiest by just wrapping in array
        // and then removing start and end of encoding for this
        NSData* data = [NSJSONSerialization dataWithJSONObject:@[parameter] options:0 error:NULL];
        NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        // remove leading [
        json = [json stringByReplacingOccurrencesOfString:@"^\\s*\\[" withString:@""
                                                  options:NSRegularExpressionSearch range:NSMakeRange(0, json.length)];

        // remove trailing ]
        json = [json stringByReplacingOccurrencesOfString:@"\\]\\s*$" withString:@""
                                                  options:NSRegularExpressionSearch range:NSMakeRange(0, json.length)];

       [javascript appendString:json];
    }
    [javascript appendString:@");"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView stringByEvaluatingJavaScriptFromString: javascript];
    });
}

-(void)updateBook:(NSString*)bookId offset:(NSTimeInterval)offset {
    [self refreshBooks];
    [self deliverEvent:@"play-time-update" payload:@[bookId, @(offset)]];
}

-(void)endBook:(NSString*)bookId {
    [self deliverEvent:@"play-end" payload:@[bookId]];
}

-(void)stopBook:(NSString*)bookId {
    [self deliverEvent:@"play-stop" payload:@[bookId]];
}

-(void)downloadBook:(NSString*)bookId progress:(CGFloat)percent {
    [self refreshBooks];
    [self deliverEvent:@"download-progress" payload:@[bookId, @(percent)]];
}

-(void)downloadBook:(NSString*)bookId failed:(NSString*)reason {
    [self deliverEvent:@"download-failed" payload:@[bookId, reason]];
}

-(void)completedDownloadBook:(NSString*)bookId timestamp:(NSDate*)when {
    NSString* timestamp = [iso8601Formatter stringFromDate:when];
    [self deliverEvent:@"download-completed" payload:@[bookId, timestamp]];
}

-(void)connectivityChangedOnline:(BOOL)online {
    [self deliverEvent:@"connectivity-changed" payload:@[@(online)]];
}

#pragma mark -

@end
