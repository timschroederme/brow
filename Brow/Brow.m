//
//  Brow.m
//  Brow
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "Brow.h"
#import "TSLogger.h"
#import "TSLaunchDController.h"
#import "Constants.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation Brow

@synthesize toggleSyncButton;


#pragma mark -
#pragma mark brow-helper Control Methods

-(BOOL)isHelperRunning
{
    BOOL result = NO;
    NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:BROW_HELPER_UTI];
    if ([running count] > 0) {
        result = YES;;
    }
    return result;
}

-(NSString*)helperAppPath
{
    NSString *helperPath = [NSString stringWithFormat:@"%@/Contents/Resources/Brow.app",
                            [[self bundle] bundlePath]];
    TSLog (@"Helper App Path: %@", helperPath);
    return (helperPath);
}

-(NSDictionary*)helperPlist
{
    NSString *key = @"ProgramArguments";
    
    // load plist file from resource bundle
    NSURL *source = [[NSBundle bundleForClass:[self class]] URLForResource:BROW_HELPER_UTI
                                                             withExtension:@"plist"];
    NSMutableDictionary *mutablePlist = [NSMutableDictionary dictionaryWithContentsOfURL:source];
    
    // modify path in plist
    NSArray *args = [mutablePlist objectForKey:key];
    NSMutableArray *mutableArgs = [NSMutableArray arrayWithArray:args];
    [mutableArgs replaceObjectAtIndex:1
                           withObject:[self helperAppPath]];
    [mutablePlist replaceValueAtIndex:1
                    inPropertyWithKey:key
                            withValue:[self helperAppPath]];
    // return modified plist
    return ([NSDictionary dictionaryWithDictionary:mutablePlist]);
}

-(void)registerHelperUTIScheme
{
    NSURL *url = [NSURL fileURLWithPath:[self helperAppPath]];
    if (url) {
        LSRegisterURL((__bridge CFURLRef)url, true);
        OSStatus stat;
        stat = LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)BROW_HELPER_UTI, kLSRolesAll, (__bridge CFStringRef)BROW_HELPER_UTI);
        TSLog (@"Registered UTI Scheme with Launch Services");
    } else {
        TSLog (@"Could not register UTI Scheme with Launch Services");
    }
}

-(void)startHelper
{
    TSLog (@"Brow: startHelper");
    
    // Load brow-helper agent in launchd (will start automatically)
    [[TSLaunchDController sharedController] loadService:BROW_HELPER_UTI
                                              withPList:[self helperPlist]];
    
    // Register helper UTI scheme with Launch Services
   // [self registerHelperUTIScheme]; TEMP
}

-(void)stopHelper
{
    // Terminate helper app, if running
    TSLog (@"Brow: stopHelper");
    NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:BROW_HELPER_UTI];
    if ([running count] > 0) {
        NSRunningApplication *r = [running firstObject];
        TSLog (@"Brow-Helper is running, terminating");
        [r terminate];
    }
    
    // Unload brow-helper agent from launchd
    [[TSLaunchDController sharedController] unLoadService:BROW_HELPER_UTI];
}

#pragma mark -
#pragma mark UI Helper Methods

-(void)setSyncButtonToOn
{
    [toggleSyncButton setSelectedSegment:0]; // 0 = ON
}

-(float)preferenceWindowWidth
{
    float result = 668.0;  // default for English language
    NSMutableArray *windows = (NSMutableArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    int myProcessIdentifier = [[NSProcessInfo processInfo] processIdentifier];
    BOOL foundWidth = NO;
    for (NSDictionary *window in windows) {
        int windowProcessIdentifier = [[window objectForKey:@"kCGWindowOwnerPID"] intValue];
        if ((myProcessIdentifier == windowProcessIdentifier) && (!foundWidth)) {
            foundWidth = YES;
            NSDictionary *bounds = [window objectForKey:@"kCGWindowBounds"];
            result = [[bounds valueForKey:@"Width"] floatValue];
        }
    }
    return result;
}


#pragma mark -
#pragma mark Main Event Handling Methods

- (void)mainViewDidLoad
{
    // Adjust width of the pref pane according to the actual size of the system preference window
    NSSize size = self.mainView.frame.size;
    size.width = [self preferenceWindowWidth];
    [[self mainView] setFrameSize:size];

    NSString *contentPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"about" ofType:@"rtf"];
    [aboutText readRTFDFromFile:contentPath];

    // Check if pref pane is opened the first time
    NSString *key = @"browAlreadyInstalled"; // defaults delete com.apple.systempreferences browAlreadyInstalled to reset
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults]; // will be stored in com.apple.systempreferences
    NSNumber *alreadyInstalled = [prefs objectForKey:key];
    
    // First time, install spotlight importer and launch helper
    if (alreadyInstalled == nil) {
        TSLog (@"First Time Launch, installing helper ..");
        [prefs setValue:@YES forKey:key]; // write to defaults that not first time install
        [prefs synchronize];
        [self startHelper]; // start helper
        [self setSyncButtonToOn];
    } else {
        // Init toggleSyncButton
        if ([self isHelperRunning]) {
            [self setSyncButtonToOn];
        }
    }
}

- (IBAction)toggleSync:(id)sender
{
    NSString * theTitle = [toggleSyncButton labelForSegment:toggleSyncButton.selectedSegment];
    if ([theTitle isEqualToString:@"ON"]) {
        [self startHelper];
    } else {
        [self stopHelper];
    }
}

- (IBAction) about:(id)sender
{
    NSWindowController *aboutController = [[NSWindowController alloc] initWithWindow:aboutWindow];
    [aboutController showWindow:self];
}

@end