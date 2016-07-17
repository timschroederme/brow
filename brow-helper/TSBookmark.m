//
//  TSBookmark.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSBookmark.h"
#import "NSFileManager+Extensions.h"
#import "NSString+Extensions.h"
#import "TSLogger.h"
#import "Constants.h"

@implementation TSBookmark

@synthesize idNo, parent, title, URL, browser, children, isFolder, icon;

#pragma mark -
#pragma mark Overriden Methods

-(id)init
{
    if (self=[super init]) {
        children = [NSMutableArray arrayWithCapacity:0];
        isFolder = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Property Methods

-(BOOL)isEntry
{
    return (![self isFolder]);
}

#pragma mark -
#pragma mark Internal Helper Methods

-(NSDictionary*)dictForBookmark
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:[self title] forKey:BOOKMARK_KEY_NAME];
    [dict setValue:[[self URL] absoluteString] forKey:BOOKMARK_KEY_URL];
    [dict setValue:[self browserString] forKey:BOOKMARK_KEY_BROWSER];
    return ([NSDictionary dictionaryWithDictionary:dict]);
}

-(NSString*)browserString
{
    NSString *browserStringValue = nil;
    if ([self browser] == Chrome)
    {
        browserStringValue = CHROME;
    }
    if ([self browser] == Chrome)
    {
        browserStringValue = FIREFOX;
    }
    return browserStringValue;
}


#pragma mark -
#pragma mark Public Methods

// Stores bookmark in file at given location
-(BOOL)writeBookMarkToFileAtPath:(NSString*)path
{    
    // Create output directory if necessary
    [[NSFileManager defaultManager] createDirectory:path];
    
    // Write data to file
    NSData *xmlData;
    NSError *error;
    xmlData = [NSPropertyListSerialization dataWithPropertyList:[self dictForBookmark]
                                                         format:NSPropertyListXMLFormat_v1_0
                                                        options:0
                                                          error:&error];
    if ((error) || (!xmlData)) {
        TSLog (@"Error while trying to save bookmark file: %@", error);
        return NO;
    }
    NSString *filename = [[self title] stringByMakingFileNameValid];
    NSString *extension = @"brow";
    path = [path stringByAppendingFormat:@"/%@.%@", filename, extension];
    [xmlData writeToFile:path
              atomically:NO];
    TSLog (@"Writing bookmark to path %@", path);
    
    // Hide file extension
    [[NSFileManager defaultManager] hideFileExtensionOfFile:path];
    
    return YES;
}

@end
