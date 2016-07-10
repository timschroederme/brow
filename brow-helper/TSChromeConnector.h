//
//  TSChromeConnector.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSBrowserConnector.h"

#import <Foundation/Foundation.h>
#import "TSBrowserConnector.h"
#import "Constants.h"
#import "TSBookmark.h"

@interface TSChromeConnector : TSBrowserConnector

+ (TSChromeConnector *)sharedConnector;

-(NSString*)appPath;
-(NSString*)identifier;
-(Browser)browserName;

-(NSString*)bookmarkFile;
-(NSArray*)bookmarkFilePaths;
-(NSArray*)bookmarkFileDirectories;

-(NSSet*)getBookmarks;

@property (strong) NSMutableArray *cache;

@end
