//
//  DataFrame.h
//  Reader
//
//  Created by Residue on 19/11/12.
//  Copyright (c) 2012 Residue. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataFrame : NSObject {

    NSUInteger _packetCount;
    NSUInteger _packetSize;
    UInt8 _frameID;
    
    NSMutableData* _packets;
    UInt8* packetsPtr;
    NSMutableArray* _completedPackets;
}

- (id) initWithPacketCount: (NSUInteger) count
                packetSize: (NSUInteger) size
                   frameID: (UInt8) frameID;

@property (readonly) BOOL completed;
@property (retain, readonly) NSData* data;
@property (readonly) UInt8 frameID;

- (void) addPacket: (UInt8*) packet atPosition: (NSUInteger) position;

@end
