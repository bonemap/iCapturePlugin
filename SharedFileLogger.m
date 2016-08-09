//
//  FileLogger.m
//  NerveCenterPlugin
//
//  Created by Residue on 24/11/12.
//
//

#import "SharedFileLogger.h"

static SharedFileLogger* __sharedInstance = nil;

@implementation SharedFileLogger

- (id) init {
    
    if (__sharedInstance == nil) {
        __sharedInstance = [[SharedFileLogger alloc] initSharedInstance];
    }
    return __sharedInstance;
}

- (id) initSharedInstance {
    
    self = [super init];
    if (self != nil) {
        _messages = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [_messages release];
    [super dealloc];
}

- (void) addMessage: (NSString*) format, ... {
    va_list args;
    va_start(args, format);
    
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    
    NSDateFormatter* dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"hh:mm:ss";
    NSString* dateString = [dateFormater stringFromDate:[NSDate date]];
    NSString* timestampedMessage = [NSString stringWithFormat:@"%@: %@",
                                    dateString, message];
    
    if (_messages.count > 1000) {
        [_messages removeObjectAtIndex:0];
    }
    [_messages addObject:timestampedMessage];

    NSMutableString* strings = [NSMutableString new];
    for (NSString* string in _messages) {
        [strings appendString:string];
    }
    
    [strings writeToFile:@"/tmp/nerve.txt"
                         atomically:NO
                           encoding:NSUTF8StringEncoding
                              error:NULL];
    
//    fprintf(file, "%s: %s",[dateString UTF8String], [message UTF8String]);
//    fflush(file);
    
    
    [strings release];
    [dateFormater release];
    [message release];
    
    va_end(args);
}

@end
