//
//  TSLaunchDController.m
//  Brow
//
//  Created by Tim Schröder on 10.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSLaunchDController.h"
#import "TSLogger.h"

@implementation TSLaunchDController

static TSLaunchDController *_sharedController = nil;

#pragma mark -
#pragma mark Singleton Methods

+ (TSLaunchDController *)sharedController
{
    if (!_sharedController) {
        _sharedController = [[super allocWithZone:NULL] init];
    }
    return _sharedController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedController];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark -
#pragma mark Internal Helper Methods

-(void)invokeLaunchctlWithCommand:(NSString*)cmd argument:(NSString*)arg
{
    NSString *launchctlPath = @"/bin/launchctl";
    
    NSTask *task = [NSTask launchedTaskWithLaunchPath:launchctlPath
                                            arguments:[NSArray arrayWithObjects:cmd,
                                                       arg,
                                                       nil]];
    [task waitUntilExit];
    
}

-(void)removeLaunchdPlistFileAtPath:(NSString*)path
{
    TSLog (@"TSLaunchDController: removeLaunchdPlistFileAtPath at %@", path);
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}


#pragma mark -
#pragma mark Public Methods

// Loads a service in launchd
// and copies plist file to launchd location so that it is started again at next login
-(void)loadService:(NSString*)bundleIdentifier withPList:(NSDictionary*)pList
{
    NSString *path = [self launchdPListPathForBundleIdentifier:bundleIdentifier];
    TSLog (@"TSLaunchDController: loadService at %@", path);
    
    // Remove plist file
    [self removeLaunchdPlistFileAtPath:path];
    
    // Copy plist file
    [pList writeToURL:[NSURL fileURLWithPath:path] atomically:YES];

    // Load service
    [self invokeLaunchctlWithCommand:@"load" argument:path];

}

// Unloads a service from launchd and removes the plist file also so that
// the service is not started again on next login
-(void)unLoadService:(NSString*)bundleIdentifier
{
    NSString *path = [self launchdPListPathForBundleIdentifier:bundleIdentifier];
    TSLog (@"TSLaunchDController: unLoadService at %@", path);
    [self invokeLaunchctlWithCommand:@"unload" argument:path];
    [self removeLaunchdPlistFileAtPath:path];
}

// Computes the full file system path for a launchd plist file for a given bundle identifier
-(NSString*)launchdPListPathForBundleIdentifier:(NSString*)bundleIdentifier
{
    return [NSString stringWithFormat:@"%@%@%@.plist",
            NSHomeDirectory(),
            @"/Library/LaunchAgents/",
            bundleIdentifier];
}


@end
