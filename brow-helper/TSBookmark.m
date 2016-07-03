//
//  TSBookmark.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSBookmark.h"
#import "Constants.h"

@implementation TSBookmark

@synthesize idNo, parent, title, URL, browser, children, isFolder, icon;

-(id)init
{
    if (self=[super init]) {
        children = [NSMutableArray arrayWithCapacity:0];
        isFolder = NO;
    }
    return self;
}

-(BOOL)isEntry
{
    return (![self isFolder]);
}

/*
 -(NSImage*)icon
 {
 if ([self browser] == Safari) return ([NSImage imageNamed:@"folder-safari.png"]);
 if ([self browser] == Chrome) return ([NSImage imageNamed:@"folder-chrome.png"]);
 if ([self browser] == Firefox) return ([NSImage imageNamed:@"folder-firefox.png"]);
 return nil;
 }
 */

@end
