//
//  TSSyncController.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSSyncController.h"
#import "TSFirefoxConnector.h"
#import "TSChromeConnector.h"
#import "TSBookmark.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "NSFileManager+Extensions.h"
#import "NSString+Extensions.h"
#import "TSLogger.h"

@implementation TSSyncController

static TSSyncController *_sharedController = nil;

@synthesize delegate;

#pragma mark -
#pragma mark Singleton Methods

+ (TSSyncController *)sharedController
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

-(id)init
{
    if (self=[super init]) {
        syncInProgress = NO;
    }
    return (self);
}


#pragma mark -
#pragma mark Internal Sync Methods

-(void)deleteBookmarksAtPath:(NSString*)path
{
    TSLog (@"Delete Bookmarks at path %@", path);
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        TSLog (@"Error while enumerating files for deletion");
        return;
    }
    for(NSString *file in files) {
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
        if(error) {
            TSLog (@"Error while deleting file %@", file);
        }
    }
}

// Delete all Bookmarks from HDD
-(void)deleteFirefoxBookmarks
{
    [self deleteBookmarksAtPath:[self firefoxOutputPath]];
    TSLog (@"Deleted bookmarks at %@", [self firefoxOutputPath]);
}

-(void)deleteChromeBookmarks
{
    [self deleteBookmarksAtPath:[self chromeOutputPath]];
    TSLog (@"Deleted bookmarks at %@", [self chromeOutputPath]);
}

-(NSString*)firefoxOutputPath
{
    NSString *path = [NSHomeDirectory() stringByAppendingString:FIREFOX_OUTPUT_PATH];
    TSLog (@"firefoxOutputPath: %@", path);
    return (path);
}

-(NSString*)chromeOutputPath
{
    NSString *path = [NSHomeDirectory() stringByAppendingString:CHROME_OUTPUT_PATH];
    TSLog (@"chromeOutputPath: %@", path);
    return (path);
}


#pragma mark -
#pragma mark Public Sync Methods

-(void)syncFirefoxBookmarks
{
    // No need to sync if Firefox isn't available (anymore)
    if (![[TSFirefoxConnector sharedConnector] isInstalled]) return;
    [self deleteFirefoxBookmarks];
    NSSet *bookmarks = [[TSFirefoxConnector sharedConnector] getBookmarks];
    if (bookmarks) {
        
        // Prepare output path
        NSString *outputURLPath = [self firefoxOutputPath];
        dispatch_async(dispatch_queue_create("TSSyncQueue", NULL), ^(void) {
            
            // Create bookmark files
            NSInteger counter = 0;
            for (TSBookmark *bookmark in bookmarks) {
                counter++;
                [bookmark writeBookMarkToFileAtPath:outputURLPath];
            }
            TSLog (@"Synced %li Firefox bookmarks.", (long)counter);
        });
    } else
    {
        TSLog (@"Error while syncing Firefox Bookmarks. Couldn't retrieve bookmarks from Firefox.");
    }
}

-(void)syncChromeBookmarks
{
    // No need to sync if Chrome isn't available (anymore)
    if (![[TSChromeConnector sharedConnector] isInstalled]) return;
    
    [self deleteChromeBookmarks];
    
    NSSet *bookmarks = [[TSChromeConnector sharedConnector] getBookmarks];
    if (bookmarks) {
        
        // Prepare output path
        NSString *outputURLPath = [self chromeOutputPath];
        dispatch_async(dispatch_queue_create("TSSyncQueue", NULL), ^(void) {
            
            // Create bookmark files
            NSInteger counter = 0;
            for (TSBookmark *bookmark in bookmarks) {
                counter++;
                [bookmark writeBookMarkToFileAtPath:outputURLPath];
            }
            TSLog (@"Synced %li Chrome bookmarks.", (long)counter);
        });
    } else
    {
        TSLog (@"Error while syncing Chrome Bookmarks. Couldn't retrieve bookmarks from Chrome.");
    }
}

// Called by TSMonitorController when pref pane has been removed
-(void)deleteAllBookmarks
{
    [self deleteChromeBookmarks];
    [self deleteFirefoxBookmarks];
}


@end
