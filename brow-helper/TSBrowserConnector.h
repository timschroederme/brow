//
//  TSBrowserConnector.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Appkit/Appkit.h>
#import "Constants.h"

@interface TSBrowserConnector : NSObject

-(NSString*)appPath;
-(Browser)browserName;
-(BOOL)isInstalled;
-(NSImage*)appIcon;

@end
