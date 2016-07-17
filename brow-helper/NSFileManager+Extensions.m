//
//  NSFileManager+Extensions.m
//  Brow
//
//  Created by Tim Schröder on 17.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "NSFileManager+Extensions.h"

@implementation NSFileManager (Extensions)

-(BOOL) createDirectory:(NSString*)path
{
    BOOL result = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) result = NO;
    }
    return result;
}

@end
