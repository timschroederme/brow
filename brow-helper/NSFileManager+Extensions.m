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
    if (![self fileExistsAtPath:path]) {
        NSError *error = nil;
        [self createDirectoryAtPath:path
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error];
        if (error) result = NO;
    }
    return result;
}

-(void) hideFileExtensionOfFile:(NSString*)path
{
    NSDictionary* attributes = [NSDictionary dictionaryWithObject:
                                [NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden];
    [self setAttributes:attributes
           ofItemAtPath:path
                  error:nil];
}

@end
