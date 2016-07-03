//
//  TSBrowserConnector.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSBrowserConnector.h"
#import "Constants.h"
#import "TSLogger.h"


@implementation TSBrowserConnector

-(NSString*)appPath
{
    return nil; // Needs to be subclassed
}

-(Browser)browserName
{
    return 0; // Needs to be subclassed
}

-(BOOL)isInstalled
{
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:[self appPath]];
    return result;
}

-(NSImage*)appIcon
{
    NSString *path;
    NSImage *icon;
    path = [self appPath];
    icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    return icon;
}


@end
