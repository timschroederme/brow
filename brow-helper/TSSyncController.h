//
//  TSSyncController.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSSyncController : NSObject
{
    BOOL syncInProgress;
}

+ (TSSyncController *)sharedController;
-(void)syncFirefoxBookmarks;
-(void)syncChromeBookmarks;

@property (assign) id delegate;

@end
