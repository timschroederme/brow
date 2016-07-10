//
//  AppDelegate.m
//  brow-helper
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "AppDelegate.h"
#import "TSMonitorController.h"
#import "TSChromeConnector.h"
#import "TSFirefoxConnector.h"
#import "TSLogger.h"


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

// Open URL from a bookmark with the original browser
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    // Collect all required data
    TSLog (@"brow-helper should open %@", filename);
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filename];
    NSString *url = [dict valueForKey:@"URL"];
    NSString *app = [dict valueForKey:@"Browser"];
    NSString *identifier;
    if ([app isEqualToString:@"Firefox"])
    {
        identifier = [[TSFirefoxConnector sharedConnector] identifier];
    }
    if ([app isEqualToString:@"Chrome"])
    {
        identifier = [[TSChromeConnector sharedConnector] identifier];
    }
    
    // Launch the correct app with URL as parameter
    TSLog (@"brow-helper opening %@ with %@", filename, app);
    NSArray *arguments = [NSArray arrayWithObjects:@"-b", identifier, url, nil];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:arguments];
    [task launch];
    return YES;
}

@end