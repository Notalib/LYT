//
//  Book.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Book.h"
#import "BookPart.h"
#import "debug.h"

@interface Book () {
    AVAudioPlayer* player;
    BOOL delayedStart; // we have been asked to start playing but are waiting for buffering
    BOOL positionEverSet;
    
    NSTimeInterval _position;
}
@end

@implementation Book

// we have not yet decided what to do with errors and just log them to console
-(void)reportError:(NSError*)error {
    NSLog(@"%@", error);
}

#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if(flag) {
        [self playMore];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self reportError:error];
}

#pragma mark -

-(void)playUrl:(NSURL*)url atTime:(NSTimeInterval)time {
    // clean up old player
    if(![player.url isEqual:url]) {
        player.delegate = nil;
        [player stop];
        player = nil;
    }
    
    if(!url) return;
    
    if(!player) {
        NSError* error = nil;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:url fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
        player.delegate = self;

        if(!player) [self reportError:error];
    }

    DBGLog(@"Started playing %@ from %.1f", url.lastPathComponent, time);
    player.currentTime = time;
    [player play];
}

-(void)refreshLookaheadWithPosition:(NSTimeInterval)position {
    NSTimeInterval lookahead = fmax(self.bufferLookahead, 1);
    if(position + lookahead > self.bufferingPoint) {
        self.bufferingPoint = position + lookahead;
    }
    
    // schedule delayed refresh if we are playing
    if(self.isPlaying) {
        NSTimeInterval delay = fmax(10, 0.25 * self.bufferLookahead);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedRefreshLookahead) object:nil];
        [self performSelector:@selector(delayedRefreshLookahead) withObject:nil afterDelay:delay];
    }
    
    NSTimeInterval ensuredBufferingPoint = self.ensuredBufferingPoint;
    DBGLog(@"position=%.1f, ensuredBufferingPoint = %.1f", position, ensuredBufferingPoint);
    if(ensuredBufferingPoint == 0.0) {
        [self ensuredBufferingPoint];
    }
}

// after some delay we need to fetch again to keep lookaehad buffer
// filled
-(void)delayedRefreshLookahead {
    [self refreshLookaheadWithPosition:self.position];
}

-(NSTimeInterval)ensuredBufferingPoint {
    NSTimeInterval position = self.position;
    NSTimeInterval time = 0;
    for (BookPart* part in self.parts) {
        NSTimeInterval endtime = time + part.duration;
        if(endtime > position) {
            NSTimeInterval partEnsured = part.ensuredBufferingPoint;

            if(partEnsured < part.duration) {
                // we have not fully cached this needed BookPart
                return time + partEnsured;
            }
        }
        time = endtime;
    }
    
    return time;
}

-(void)setBufferLookahead:(NSTimeInterval)bufferLookahead {
    _bufferLookahead = bufferLookahead;
    [self refreshLookaheadWithPosition:self.position];
}

-(void)refreshPosition {
    positionEverSet = YES;
    NSTimeInterval position = _position;
    
    // when setting position we make sure to ask for a little extra buffer
    [self refreshLookaheadWithPosition:position];
    
    NSUInteger index = 0;
    for (BookPart* part in self.parts) {
        if(position < part.duration) {
            self.currentPart = index;
            self.positionInPart = position;
            return;
        }
        
        position -= part.duration;
        index += 1;
    }
    
    // we did not found position and set to greatest value possible (end of last file)
    BookPart* last = self.parts.lastObject;
    self.currentPart = self.parts.count - 1;
    self.positionInPart = last.duration;
}

-(void)setPosition:(NSTimeInterval)position {
    _position = position;
    [self refreshPosition];
}

-(NSTimeInterval)position {
    NSUInteger index = 0;
    NSTimeInterval time = 0;
    
    for (BookPart* part in self.parts) {
        if(index == self.currentPart) {
            return time + player.currentTime;
        }
        
        time += part.duration;
        index += 1;
    }
    
    return 0;
}

// start playing at wanted position if ready, returning whether we could
-(BOOL)playIfReady {
    if(self.currentPart >= self.parts.count) return NO;
    
    // we do not start playing unless we have more ensured buffer that play position
    BookPart* part = [self.parts objectAtIndex: self.currentPart];
    if(part.ensuredBufferingPoint <= self.positionInPart) return NO;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSURL* url = [NSURL fileURLWithPath:part.cachePath];
    [self playUrl:url atTime:0];
    
    return YES;
}

-(BOOL)isPlaying {
    return player.isPlaying;
}

-(void)play {
    if(!positionEverSet) {
        [self refreshPosition];
    }
    
    BOOL started = [self playIfReady];
    delayedStart = !started;
}

-(void)stop {
    delayedStart = NO;
    [player stop];
}

-(void)playMore {
    self.currentPart += 1;
    self.positionInPart = 0;
    
    [self play];
    [self refreshLookaheadWithPosition:self.position];
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %@: \n%@", self.title, self.author, self.parts];
}

-(void)dealloc {
    [self playUrl:nil atTime:0];
    [self setParts:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"bufferingsSatisfied"]) {
        BookPart* part = object;
        if(part.bufferingsSatisfied) {
            if(part.bufferingPoint > 0.0) {
                //DBGLog(@"Buffering of %.1f seconds completed: %@", part.bufferingPoint, part);
            }
            
            [self cascadeBufferingPoint];
        }
    } else if([keyPath isEqualToString:@"ensuredBufferingPoint"]) {
        if(delayedStart) {
            [self play];
        }
    } else if([keyPath isEqualToString:@"error"]) {
        BookPart* part = object;
        NSError* error = part.error;
        if(error) {
            [self reportError:error];
        }
    }
}

// we turn on KVO notifications for each part of book to know buffering status
-(void)setParts:(NSArray *)parts {
    if(parts == _parts) return;
    
    for (BookPart* part in _parts) {
        [part removeObserver:self forKeyPath:@"ensuredBufferingPoint"];
        [part removeObserver:self forKeyPath:@"bufferingsSatisfied"];
        [part removeObserver:self forKeyPath:@"error"];
    }
    _parts = parts;
    for (BookPart* part in _parts) {
        [part addObserver:self forKeyPath:@"error" options:0 context:NULL];
        [part addObserver:self forKeyPath:@"bufferingsSatisfied" options:0 context:NULL];
        [part addObserver:self forKeyPath:@"ensuredBufferingPoint" options:0 context:NULL];
    }
}

+(Book*)bookFromDictionary:(NSDictionary*)dictionary baseURL:(NSURL*)baseURL {
    NSArray* partDictionaries = [dictionary objectForKey:@"playlist"];
    NSMutableArray* parts = [NSMutableArray arrayWithCapacity:partDictionaries.count];
    for (NSDictionary* dictionary in partDictionaries) {
        NSString* url = [dictionary objectForKey:@"url"];
        NSNumber* start = [dictionary objectForKey:@"start"];
        NSNumber* end = [dictionary objectForKey:@"end"];
        
        NSURL* correctedUrl = [baseURL URLByAppendingPathComponent:url.lastPathComponent];
        
        BookPart* part = [BookPart new];
        part.start = start.doubleValue;
        part.end = end.doubleValue;
        part.url = correctedUrl;
        [parts addObject:part];
    }
    
    Book* book = [Book new];
    book.title = [dictionary objectForKey:@"title"];
    book.author = [dictionary objectForKey:@"author"];
    book.parts = parts;
    return book;
}

-(void)joinParts {
    NSMutableArray* array = [NSMutableArray new];
    BookPart* last = nil;
    for (BookPart* part in self.parts) {
        BookPart* joined = [last partCombinedWith: part];
        if(joined == nil) {
            // join not possible, add last part of needed
            if(last) [array addObject:last];
            last = part;            
        } else {
            // join was possible
            last = joined;
        }
    }
    if(last) [array addObject:last];
    
    self.parts = array;
}

-(AVQueuePlayer*)makeQueuePlayer {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:self.parts.count];
    for (BookPart* part in self.parts) {
        AVPlayerItem* playerItem = [part makePlayerItem];
        [items addObject: playerItem];
    }
    
    return [AVQueuePlayer queuePlayerWithItems: items];
}

// Buffering point should be cascaded to each part of the book, but
// we stop cascade on first book that have not fully buffered to avoid
// congesting buffering the next part of the book with later parts.
// We also do not ask parts of book we have passed to buffer.
-(void)cascadeBufferingPoint {
    NSTimeInterval position = self.position;
        
    NSTimeInterval time = 0; // how long parts of book has been up to this point
    for (BookPart* part in self.parts) {
        // if part of books ends before current position, we do not care about cache,
        // as we should read the parts of the book being listened to now.
        NSTimeInterval endTime = time + part.duration;
        if(endTime >= position) {
            part.bufferingPoint = _bufferingPoint - time;
            if(!part.bufferingsSatisfied) break;
        }
        time = endTime;
    }
}

-(void)setBufferingPoint:(NSTimeInterval)bufferingPoint {
    _bufferingPoint = bufferingPoint;
    [self cascadeBufferingPoint];
}

-(void)deleteCache {
    for (BookPart* part in self.parts) {
        [part deleteCache];
    }
}

@end