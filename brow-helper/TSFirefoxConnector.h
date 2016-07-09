//
//  TSFirefoxConnector.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSBrowserConnector.h"
#import "Constants.h"

@interface TSFirefoxConnector : TSBrowserConnector

+ (TSFirefoxConnector *)sharedConnector;

-(NSString*)appPath;
-(Browser)browserName;

-(NSURL*)bookmarkPath;
-(NSString*)fullBookmarkPathWithFileName:(BOOL)withFileName;
-(NSArray*)bookmarkFiles;

-(NSSet*)getBookmarks;


@end
