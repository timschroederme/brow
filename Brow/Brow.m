//
//  Brow.m
//  Brow
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "Brow.h"
#import "TSLogger.h"

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
#pragma mark brow-importer Helper Methods

- (void)copyFolderAtPath:(NSString *)sourceFolder toDestinationFolderAtPath:(NSString*)destinationFolder {
    destinationFolder = [destinationFolder stringByAppendingPathComponent:[sourceFolder lastPathComponent]];
    
    NSFileManager * fileManager = [ NSFileManager defaultManager];
    NSError * error = nil;
    
    // Create destination folder if it doesn't exist
    NSError *createError;
    BOOL isDir;
    if (![fileManager fileExistsAtPath:destinationFolder isDirectory:&isDir])
    {
        if (![fileManager createDirectoryAtPath:destinationFolder
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&createError])
        {
            TSLog (@"Error creating Spotlight directory: %@", [createError description]);
        }
    }
    
    if ([ fileManager fileExistsAtPath:destinationFolder])  //check if destinationFolder exists
    {
        //removing destination, so source may be copied
        if (![fileManager removeItemAtPath:destinationFolder error:&error])
        {
            TSLog(@"Could not remove old files. Error:%@",error);
        }
    }
    
    error = nil;
    
    //copying to destination
    if ( !( [ fileManager copyItemAtPath:sourceFolder toPath:destinationFolder error:&error ]) )
    {
        TSLog(@"Could not copy from path %@ to path %@. error %@",sourceFolder, destinationFolder, [error description]);
    }
}

-(void)installImporter
{
    TSLog (@"Installing Spotlight importer..");
    NSString* importerBundlePath = [NSString stringWithFormat:@"%@/Contents/Resources/brow-importer.mdimporter/", [[self bundle] bundlePath]];
    NSString *spotlightPath = [NSString stringWithFormat:@"%@/Library/Spotlight", NSHomeDirectory()];
    TSLog (@"ImporterBundlePath: %@", importerBundlePath);
    TSLog (@"spotlightPath: %@", spotlightPath);
    [self copyFolderAtPath:importerBundlePath toDestinationFolderAtPath:spotlightPath];
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
    NSString *helperPath = [NSString stringWithFormat:@"%@/Contents/Resources/brow-helper.app",
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

-(void)startHelper
{
    // Remove plist file
    [self removelaunchdPlistFile];
    
    // Copy plist file
    [[self helperPlist] writeToURL:[NSURL fileURLWithPath:self.launchdPlistPath] atomically:YES];
        
    // Load brow-helper agent in launchd (will start automatically)
    [self invokeLaunchctlWithCommand:@"load" argument:self.launchdPlistPath];
}

-(void)stopHelper
{    
    // Terminate helper app, if running
    NSArray *running = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.helperBundleIdentifier];
    if ([running count] > 0) {
        NSRunningApplication *r = [running firstObject];
        [r terminate];
    }
    
    // Unload brow-helper agent from launchd
    [self invokeLaunchctlWithCommand:@"unload"
                            argument:self.launchdPlistPath];
    
    // Remove plist file
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

// TODO: Update-Mechanismus mit Versionserkennung für Helper install und importer install ergänzen
- (void)mainViewDidLoad
{
    // Check if pref pane is opened the first time
    NSString *key = @"browAlreadyInstalled"; // defaults delete com.apple.systempreferences browAlreadyInstalled to reset
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults]; // will be stored in com.apple.systempreferences
    NSNumber *alreadyInstalled = [prefs objectForKey:key];
    
    // First time, install spotlight importer and launch helper
    if (alreadyInstalled == nil) {
        TSLog (@"First Time Launch, installing helper and spotlight importer..");
        [self installImporter]; // install spotlight importer
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