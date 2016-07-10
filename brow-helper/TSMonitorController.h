//
//  TSMonitorController.h
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSMonitorController : NSObject
{
    BOOL chromeMonitoringIsActive;
    BOOL firefoxMonitoringIsActive;
    NSURL *chromeBookmarkURL;
    NSURL *firefoxBookmarkURL;
}

+ (TSMonitorController *)sharedController;
-(void)startChromeMonitoring;
-(void)stopChromeMonitoring;
-(void)startFirefoxMonitoring;
-(void)stopFirefoxMonitoring;

@end
