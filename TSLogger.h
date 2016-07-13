//
//  TSLogger.h
//  Brow
//
//  Created by Tim Schröder on 29.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef TSLog
#define TSLog( s, ... ) \
if ([[TSLogger sharedLogger] isLoggingEnabled] == YES) {\
NSLog( @"%@", [NSString stringWithFormat:(s), ##__VA_ARGS__]); \
} 
#endif


@interface TSLogger : NSObject

+ (TSLogger *)sharedLogger;
-(BOOL)isLoggingEnabled;


@end
