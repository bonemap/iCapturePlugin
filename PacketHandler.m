//
//  PacketHandler.m
//  ReaderPlugin
//
//  Created by Residue on 10/11/12.
//
//

#import "PacketHandler.h"
#import <AppKit/AppKit.h>

@implementation PacketHandler

- (id) init {
    self = [super init];
    if (self == nil) return nil;
    
    dataFrameBuffer = [[DataFrameBuffer alloc] initWithPacketCount:64/16 packetSize:(512*16 - 2)];
    socketID = -1;
    
    DEBUG_MESSAGE(@"PacketHandler created\n")
    
    return self;
}

- (void) setDelegate: (id<DataFrameBufferDelegate>) delegate {
    dataFrameBuffer.delegate = delegate;
}

- (BOOL) startWithPortNumber: (int) portNumber serviceID: (NSString*) serviceID {
    
    if (bonjourService != nil) return NO;
    
    socketID = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (socketID < 0) {
        return NO;
    }
    
    struct sockaddr_in addr;
    
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(portNumber);
    
    if (bind(socketID, (struct sockaddr *) &addr, sizeof(addr)) == -1) {
        return NO;
    }
    
    socketQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    socketSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                                          socketID, 0, socketQueue);
    dispatch_source_set_event_handler(socketSource, ^() {
        @autoreleasepool {
            //        [[SharedFileLogger new] addMessage:@"GCD event handler called\n"];
            memset(_buffer, 0, BUFFER_SIZE);
            ssize_t bytes = read(socketID, _buffer, BUFFER_SIZE);
            if (bytes < 0) return;
            
            //printf("received %ld bytes\n", bytes);
            //        [[SharedFileLogger new] addMessage:@"\treceived: %ld bytes\n", bytes];
            
            
            if (bytes == 512*16) {
                
                // NOTE: the data format being received is
                // 1 BYTE: frameID, 1 BYTE: packet position, 510 BYTES: raw data
                // so, if we need a larger than UInt8 number of positions,
                // this will change the data format...
                
                UInt8* packet = _buffer + 2; // assuming packet size 510 bytes
                UInt8 frameID = _buffer[0];
                UInt8 position = _buffer[1];
                //printf("adding packet data ID: %d, pos: %d\n", frameID, position);
                
                [dataFrameBuffer addPacket:packet packetPosition:position frameID:frameID];
            } else {
                DEBUG_MESSAGE(@"\tinvalid received: %ld bytes\n", bytes)
            }
            //        [[SharedFileLogger new] addMessage:@"GCD event handler done\n"];
        }
    });
    
    dispatch_resume(socketSource);
    
    bonjourService.delegate = nil;
    [bonjourService release];
    bonjourService = [[NSNetService alloc] initWithDomain:@"local."
                                                     type:@"_bonemap._udp."
                                                     name:serviceID
                                                     port:portNumber];
    [bonjourService publish];
    
    return YES;
}

- (void) stop {
    if (bonjourService == nil) return;
    
    [bonjourService stop];
    bonjourService.delegate = nil;
    [bonjourService release];
    bonjourService = nil;
    
    dispatch_source_cancel(socketSource);
    dispatch_release(socketSource);
    
    [dataFrameBuffer release];
    
    if (socketID > -1) {
        close(socketID);
    }
    socketID = -1;
}

- (void)dealloc {
    
    [self stop];
    [super dealloc];
}

@end
