//
//  TSBookmark.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface TSBookmark : NSObject

@property (retain) NSString *idNo;
@property (retain) NSString *parent;
@property (retain) NSString *title;
@property (retain) NSURL *URL;
@property (assign) Browser browser;
@property (assign) BOOL isFolder;
@property (retain) NSMutableArray *children;
@property (retain) NSImage *icon;
@property (assign, readonly) BOOL isEntry;

@end
