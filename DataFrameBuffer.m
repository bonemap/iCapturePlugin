//
//  DataFrameBuffer.m
//  Reader
//
//  Created by Residue on 19/11/12.
//  Copyright (c) 2012 Residue. All rights reserved.
//

#import "DataFrameBuffer.h"

ModuloComparatorType compareUInt8(UInt8 a, UInt8 b) {
    UInt8 normalisedB = b - a; // reduce to test in range: 129...255 0 1 2...128
    if (normalisedB == 0) return EQUAL;
    if (normalisedB == 1) return NEXTNUMBER;
    if (normalisedB >= 2 & normalisedB <= 128) return BIGGER;
    return SMALLER;
}


@implementation DataFrameBuffer

@synthesize delegate=_delegate;

- (id) initWithPacketCount: (NSUInteger) count
                packetSize: (NSUInteger) size {
    
    if ((self = [super init]) != nil) {
        _packetSize = size;
        _packetCount = count;

        _current = nil;
        _next = nil;
    }
    DEBUG_MESSAGE(@"\tDataFrameBuffer created\n")
    
    return self;
}

- (void) addPacket: (UInt8*) packet
      packetPosition: (NSUInteger) number
           frameID: (UInt8) frameID {

//    [[SharedFileLogger new] addMessage:@"\tDataFrameBuffer addPacket Processing"
//     " packetPosition: %d frameID: %d\n", number, frameID];
    if (_current == nil) {
//        [[SharedFileLogger new] addMessage:@"\t\tcurrent nil, so creating new one\n"];
        _current = [[DataFrame alloc] initWithPacketCount:_packetCount
                                               packetSize:_packetSize
                                                  frameID:frameID];
        [_current addPacket:packet
                 atPosition:number];
    } else {
//        [[SharedFileLogger new] addMessage:@"\t\tchecking current ID: %d with %d\n",
//         _current.frameID, frameID];
        switch (compareUInt8(_current.frameID, frameID)) {
            case EQUAL:
//                [[SharedFileLogger new] addMessage:@"\t\tEQUAL so adding packet\n"];
                
                // store packets for the current frame
                [_current addPacket:packet atPosition:number];
                if (_current.completed) {
//                    [[SharedFileLogger new] addMessage:@"\t\t\tcurrent complete!\n"];
                    
                    // use the frame
                    NSData* data = _current.data;
                    [self.delegate receivedFrame: data];
                    
                    [_current release];
                    _current = _next; // already has frameID + 1 ! :)
                    _next = nil;
                }
                break;
            case NEXTNUMBER:
                DEBUG_MESSAGE(@"\t\tNEXTNUMBER so save into next"
                 "current %d next %d\n", _current.frameID, _next.frameID)
                // store packets from the next frame if we get them
                if (_next == nil) {
//                    [[SharedFileLogger new] addMessage:@"\t\t\tnext nil, so creating\n"];
                    _next = [[DataFrame alloc] initWithPacketCount:_packetCount packetSize:_packetSize frameID:frameID];
                }
                [_next addPacket:packet atPosition:number];
                if (_next.completed) {
//                    [[SharedFileLogger new] addMessage:@"\t\t\tnext completed!\n"];
                    
                    // use the frame
                    NSData* data = _next.data;
                    [self.delegate receivedFrame: data];
                    
                    // we did not complete the current, so discard it
                    [_current release];
                    [_next release];
                    _current = nil;
                    _next = nil;
                }
                break;
            case SMALLER:
                DEBUG_MESSAGE(@"\t\tSMALLER so ignoring\n")
                // ignore older frames...
                break;
            case BIGGER:
                DEBUG_MESSAGE(@"\t\tBIGGER so dropping current & next"
                 "current %d new %d\n", _current.frameID, frameID)
                // reset current and next - we must have lost a few frames...
                [_current release];
                [_next release];
                _current = [[DataFrame alloc] initWithPacketCount:_packetCount packetSize:_packetSize frameID:frameID];
                [_current addPacket:packet atPosition:number];
//                [[SharedFileLogger new] addMessage:@"\t\tcreated new current, added packet\n"];
                _next = nil;
                break;
        }
    }
}

- (void)dealloc {
    
    self.delegate = nil;
    [_current release];
    [_next release];
    [super dealloc];
}

@end
