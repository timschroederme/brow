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
#import "Constants.h"
#import "TSLogger.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

-(NSString*)helperAppPath
{
    NSString *helperPath = [NSString stringWithFormat:@"%@/Contents/Resources/Brow.app",
                            [[NSBundle mainBundle] bundlePath]];
    TSLog (@"Helper App Path: %@", helperPath);
    return (helperPath);
}


-(void)registerHelperUTIScheme
{
    NSURL *url = [NSURL fileURLWithPath:[self helperAppPath]];
    if (url) {
        OSStatus stat;
        stat = LSRegisterURL((__bridge CFURLRef)url, true);
        TSLog (@"Registered UTI Scheme with LSRegisterURL, result is %i", stat);
        stat = LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)BROW_HELPER_UTI, kLSRolesAll, (__bridge CFStringRef)BROW_HELPER_UTI);
        TSLog (@"Registered UTI Scheme with LSSetDefaultRoleHandlerForContentType, result is %i", stat);
    } else {
        TSLog (@"Could not register UTI Scheme with Launch Services");
    }
}

//
// Main Event Handling Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    TSLog(@"applicationDidFinishLaunching");
    [self registerHelperUTIScheme];
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
    NSString *url = [dict valueForKey:BOOKMARK_KEY_URL];
    NSString *app = [dict valueForKey:BOOKMARK_KEY_BROWSER];
    NSString *identifier;
    if ([app isEqualToString:FIREFOX])
    {
        identifier = [[TSFirefoxConnector sharedConnector] identifier];
    }
    if ([app isEqualToString:CHROME])
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