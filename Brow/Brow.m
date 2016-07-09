//
//  Brow.m
//  Brow
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "Brow.h"
#import "TSLogger.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation Brow

@synthesize toggleSyncButton;

#pragma mark -
#pragma mark System Helper Methods

-(NSString*)helperBundleIdentifier
{
    return @"com.timschroeder.brow-helper";
}

-(NSString*)launchdPlistPath
{
    return [NSString stringWithFormat:@"%@%@%@.plist",
            NSHomeDirectory(),
            @"/Library/LaunchAgents/",
            [self helperBundleIdentifier]];
}

-(void)invokeLaunchctlWithCommand:(NSString*)cmd argument:(NSString*)arg
{
    NSString *launchctlPath = @"/bin/launchctl";

    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlPath
                                            arguments:[NSArray arrayWithObjects:cmd,
                                                       arg,
                                                       nil]];
    [task waitUntilExit];

}

-(void)removelaunchdPlistFile
{
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:self.launchdPlistPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.launchdPlistPath error:nil];
    }

}


#pragma mark -
#pragma mark brow-helper Control Methods

-(BOOL)isHelperRunning
{
    BOOL result = NO;
    NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.helperBundleIdentifier];
    if ([running count] > 0) {
        result = YES;;
    }
    return result;
}

-(NSString*)helperAppPath
{
    NSString *helperPath = [NSString stringWithFormat:@"%@/Contents/Resources/Brow.app",
                            [[self bundle] bundlePath]];
    return (helperPath);
}

-(NSDictionary*)helperPlist
{
    NSString *key = @"ProgramArguments";
    
    // load plist file from resource bundle
    NSURL *source = [[NSBundle bundleForClass:[self class]] URLForResource:self.helperBundleIdentifier
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
        stat = LSSetDefaultRoleHandlerForContentType((__bridge CFStringRef)[self helperBundleIdentifier], kLSRolesAll, (__bridge CFStringRef)[self helperBundleIdentifier]);
        TSLog (@"Registered UTI Scheme with Launch Services");
    } else {
        TSLog (@"Could not register UTI Scheme with Launch Services");
    }

}

-(void)startHelper
{
    // Remove plist file
    TSLog (@"Remove launchd plist file");
    [self removelaunchdPlistFile];
    
    // Copy plist file
    TSLog (@"Write new launchd plist file");
    [[self helperPlist] writeToURL:[NSURL fileURLWithPath:self.launchdPlistPath] atomically:YES];
        
    // Load brow-helper agent in launchd (will start automatically)
    TSLog (@"Launch Helper app");
    [self invokeLaunchctlWithCommand:@"load" argument:self.launchdPlistPath];
    // Register helper UTI scheme with Launch Services
    [self registerHelperUTIScheme];
}

-(void)stopHelper
{
    // Terminate helper app, if running
    TSLog (@"Should Terminate Brow-Helper");
    NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.helperBundleIdentifier];
    if ([running count] > 0) {
        NSRunningApplication *r = [running firstObject];
        TSLog (@"Terminating Brow-Helper");
        [r terminate];
    }
    
    // Unload brow-helper agent from launchd
    TSLog (@"Removing Brow-Helper from Autostart");
    [self invokeLaunchctlWithCommand:@"unload"
                            argument:self.launchdPlistPath];
    [self removelaunchdPlistFile];
}

#pragma mark -
#pragma mark UI Helper Methods

-(void)setSyncButtonToOn
{
    [toggleSyncButton setSelectedSegment:0]; // 0 = ON
}

#pragma mark -
#pragma mark Main Event Handling Methods

- (void)mainViewDidLoad
{
    // Check if pref pane is opened the first time
    NSString *key = @"browAlreadyInstalled"; // defaults delete com.apple.systempreferences browAlreadyInstalled to reset
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults]; // will be stored in com.apple.systempreferences
    NSNumber *alreadyInstalled = [prefs objectForKey:key];
    
    // First time, install spotlight importer and launch helper
    if (alreadyInstalled == nil) {
        TSLog (@"First Time Launch, installing helper and spotlight importer..");
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

@end