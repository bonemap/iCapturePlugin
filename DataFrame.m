//
//  DataFrame.m
//  Reader
//
//  Created by Residue on 19/11/12.
//  Copyright (c) 2012 Residue. All rights reserved.
//

#import "DataFrame.h"

@implementation DataFrame

- (id) initWithPacketCount: (NSUInteger) count
                packetSize: (NSUInteger) size
                   frameID: (UInt8) frameID {

    if ((self = [super init]) != nil) {
        _packetCount = count;
        _packetSize = size;
        _frameID = frameID;
        
        // create zero'd NSData of correct length
        _packets = [[NSMutableData dataWithLength: count * size] retain];
        packetsPtr = (UInt8*) _packets.bytes;
        _completedPackets = [[NSMutableArray arrayWithCapacity:count] retain];
        for (int i = 0; i < count; ++i) {
            [_completedPackets addObject: [NSNumber numberWithBool:NO]];
        }
    }
    return self;
}

- (BOOL) completed {
    @synchronized (self) {
//        printf("completed test: %s\n", [[_completedPackets description] UTF8String]);
//        NSMutableString* completedString = [NSMutableString new];
//        
//        for (NSNumber* number in _completedPackets) {
//            [completedString appendFormat:@"%d", number.boolValue];
//        }
//        
//        [[SharedFileLogger new] addMessage:@"\tcompleted test: %s\n",
//         [completedString UTF8String]];
//        
//        [completedString release];

        for (NSNumber* number in _completedPackets) {
            if (number.boolValue == NO) return NO;
        }
        return YES;
    }
}

- (void) addPacket: (UInt8*) packet
        atPosition: (NSUInteger) position {
    @synchronized (self) {
        if (position < _completedPackets.count) {
            NSNumber* number = [_completedPackets objectAtIndex:position];
            if (number.boolValue == NO) {
                [_completedPackets replaceObjectAtIndex:position withObject: [NSNumber numberWithBool:YES]];
                memcpy(packetsPtr + _packetSize*position, packet, _packetSize);
            }
        }
    }
}

- (NSData*) data {
    @synchronized (self) {
        return _packets;
    }
}

- (UInt8) frameID {
    @synchronized (self) {
        return _frameID;
    }
}

- (void)dealloc {
    
    [_packets release];
    [_completedPackets release];
    
    
    [super dealloc];
}

@end
