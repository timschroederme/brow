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
#pragma mark Internal Helper Methods

// Returns a sting representing this filename transformed (if neccesary) to make
// a valid (Mac OS X) filename.
- (NSString *) stringByMakingFileNameValid:(NSString *)fileName
{
    NSMutableString * validFileName = [NSMutableString stringWithString:fileName];
    if (!validFileName || [validFileName isEqualToString:@""]) {
        return @"untitled";
    }
    // remove initial period chars "."
    if ([validFileName hasPrefix:@"."]) {
        NSRange dotRange = [validFileName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
        [validFileName deleteCharactersInRange:dotRange];
    }
    // remove any colon chars ":" (same as webloc creation behaviour)
    [validFileName replaceOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(0, [validFileName length])];
    // this may lead to spaces at either end which need trimming
    validFileName = [[validFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
    
    // if there is nothing left return default value
    if ([validFileName isEqualToString:@""]) {
        return @"untitled";
    }
    // replace other disallowed Mac OS X characters
    [validFileName replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, [validFileName length])];
    
    // if grater than 102 chars reduce to 101 and add elipses
    if ([validFileName length] > 102) {
        [validFileName deleteCharactersInRange:NSMakeRange(100, [validFileName length]-100)];
        [validFileName appendString:@"…"];
    }
    
    return [validFileName copy];
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

-(void)createBookmarkFileForBookmark:(TSBookmark*)bookmark
                              atPath:(NSString*)path
                          forBrowser:(NSString*)browser
{
    // Create output directory if necessary
    BOOL fileExists;
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!fileExists) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) TSLog (@"Error while trying to create Dir: %@", error);
    }
    
    // Create bookmark data
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:[bookmark title] forKey:BOOKMARK_KEY_NAME];
    [dict setValue:[[bookmark URL] absoluteString] forKey:BOOKMARK_KEY_URL];
    [dict setValue:browser forKey:BOOKMARK_KEY_BROWSER];
    
    // Write data to file
    NSData *xmlData;
    NSError *error;
    xmlData = [NSPropertyListSerialization dataWithPropertyList:dict
                                                         format:NSPropertyListXMLFormat_v1_0
                                                        options:0
                                                          error:&error];
    if ((error) || (!xmlData)) {
        TSLog (@"Error while trying to save bookmark file: %@", error);
        return;
    }
    NSString *title = [self stringByMakingFileNameValid:[bookmark title]];
    NSString *extension = @"brow";
    path = [path stringByAppendingFormat:@"/%@.%@", title, extension];
    [xmlData writeToFile:path
              atomically:NO];
    TSLog (@"Writing bookmark to path %@", path);
    
    // Hide file extension
    NSDictionary* attributes = [NSDictionary dictionaryWithObject:
                                [NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden];
    [[NSFileManager defaultManager] setAttributes:attributes
                                     ofItemAtPath:path
                                            error:nil];
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
                [self createBookmarkFileForBookmark:bookmark
                                             atPath:outputURLPath
                                         forBrowser:FIREFOX];
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
                [self createBookmarkFileForBookmark:bookmark
                                             atPath:outputURLPath
                                         forBrowser:CHROME];
            }
            TSLog (@"Synced %li Chrome bookmarks.", (long)counter);
        });
    } else
    {
        TSLog (@"Error while syncing Chrome Bookmarks. Couldn't retrieve bookmarks from Chrome.");
    }
}


@end
