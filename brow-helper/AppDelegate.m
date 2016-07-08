//
//  AppDelegate.m
//  brow-helper
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "AppDelegate.h"
#import "TSMonitorController.h"
#import "TSLogger.h"

// TODO: webbookmarks mit unterschiedlichen browsern assoziieren

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

//
// Main Event Handling Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    TSLog(@"applicationDidFinishLaunching");
    TSMonitorController *monitorController = [TSMonitorController sharedController];
    [monitorController startFirefoxMonitoring];
    [monitorController startChromeMonitoring];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    TSLog(@"applicationWillTerminate");
    TSMonitorController *monitorController = [TSMonitorController sharedController];
    [monitorController stopFirefoxMonitoring];
    [monitorController stopChromeMonitoring];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    TSLog (@"brow-helper should open %@", filename);
    return YES;
}

@end