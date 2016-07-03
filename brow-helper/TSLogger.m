//
//  TSLogger.m
//  Brow
//
//  Created by Tim Schröder on 29.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSLogger.h"

@implementation TSLogger

static TSLogger *_sharedLogger = nil;
BOOL _debugging = NO;

#pragma mark -
#pragma mark Singleton Methods

+ (TSLogger *)sharedLogger
{
    if (!_sharedLogger) {
        _sharedLogger = [[super allocWithZone:NULL] init];
    }
    return _sharedLogger;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedLogger];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


#pragma mark -
#pragma Custom Methods

// Read settings if debugging is enabled in user defaults
// If yes, debug output is enabled but setting is cleared from user defaults
// To enable debugging for one run, use this command in Terminal:
// defaults write com.timschroeder.brow-helper browDebug true
// defaults write com.apple.systempreferences browDebug true
-(void)readUserDefaults
{
    NSString *key = @"browDebug";
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSLog (@"%@", bundleIdentifier);
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *defaults = [prefs objectForKey:key];
    if (defaults != nil) {
        BOOL debug_setting = [defaults boolValue];
        if (debug_setting == YES) {
            _debugging = YES;
            [prefs setValue:@NO forKey:key];
            [prefs synchronize];
        }
    }
    _debugging = YES;
}

-(BOOL)isLoggingEnabled
{
    return _debugging;
}


#pragma mark -
#pragma mark Overriden Methods

-(id)init
{
    if (self = [super init]) {
        [self readUserDefaults];
    }
    return (self);
}


@end
