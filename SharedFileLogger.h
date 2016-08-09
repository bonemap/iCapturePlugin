//
//  FileLogger.h
//  NerveCenterPlugin
//
//  Created by Residue on 24/11/12.
//
//

// This is based on the MONOSTATE pattern!

@interface SharedFileLogger : NSObject {
@private NSMutableArray* _messages;
}

- (void) addMessage: (NSString*) format, ...;

@end
