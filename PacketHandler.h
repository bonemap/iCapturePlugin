//
//  PacketHandler.h
//  ReaderPlugin
//
//  Created by Residue on 10/11/12.
//
//

#import <Foundation/Foundation.h>
#import "DataFrameBuffer.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h>

#define BUFFER_SIZE (32*1024)

@interface PacketHandler : NSObject
{
    NSNetService* bonjourService;
    
    int socketID;
    dispatch_source_t socketSource;
    dispatch_queue_t socketQueue;
    
    DataFrameBuffer* dataFrameBuffer;
    UInt8 _buffer[BUFFER_SIZE];

}

- (void) setDelegate: (id<DataFrameBufferDelegate>) delegate;
- (BOOL) startWithPortNumber: (int) portNumber serviceID: (NSString*) serviceID;
- (void) stop;

@end
