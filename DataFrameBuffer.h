//
//  DataFrameBuffer.h
//  Reader
//
//  Created by Residue on 19/11/12.
//  Copyright (c) 2012 Residue. All rights reserved.
//

// a COMPOSITE pattern

#import <Foundation/Foundation.h>
#import "DataFrame.h"

typedef enum {
    EQUAL, NEXTNUMBER, BIGGER, SMALLER
} ModuloComparatorType;

ModuloComparatorType compareUInt8(UInt8 a, UInt8 b);

@class DataFrameBuffer;

@protocol DataFrameBufferDelegate

- (void) receivedFrame: (NSData*) data;

@end

@interface DataFrameBuffer : NSObject {
    DataFrame* _current;
    DataFrame* _next;
    NSUInteger _packetSize;
    NSUInteger _packetCount;
    id<DataFrameBufferDelegate> _delegate;
}

@property (retain, nonatomic) id<DataFrameBufferDelegate> delegate;

- (id) initWithPacketCount: (NSUInteger) count
                packetSize: (NSUInteger) size;

- (void) addPacket: (UInt8*) packet
      packetPosition: (NSUInteger) number
           frameID: (UInt8) frameID;

@end
