//
//  TSFirefoxConnector.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSFirefoxConnector.h"
#import "TSBrowserConnector.h"
#import "NSURL+Extensions.h"
#import "FMDatabase.h"
#import "Constants.h"
#import "TSBookmark.h"
#import "TSLogger.h"

@implementation TSFirefoxConnector

static TSFirefoxConnector *_sharedConnector = nil;

#pragma mark -
#pragma mark Singleton Methods

+ (TSFirefoxConnector *)sharedConnector
{
    if (!_sharedConnector) {
        _sharedConnector = [[super allocWithZone:NULL] init];
    }
    return _sharedConnector;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedConnector];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


#pragma mark -
#pragma mark Firefox Connection Methods

-(NSString*)appPath
{
    NSString *path;
    path = [[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:[self identifier]] path];
    TSLog (@"Firefox installation path: %@", path)
    return path;
}

-(NSString*)identifier
{
    return (@"org.mozilla.firefox");
}

-(Browser)browserName
{
    return Firefox;
}

-(NSURL*)bookmarkPath
{
    NSString *path;
    path = [NSString stringWithFormat:@"%@/Library/Application Support/Firefox/", NSHomeDirectory()];
    NSURL *URL;
    URL = [NSURL fileURLWithPath:path];
    return URL;
}

-(NSString*)fullBookmarkPathWithFileName:(BOOL)withFileName
{
    
    // Prepare path and check if bookmark file exists
    NSString *path;
    path = [[self bookmarkPath] path];
    NSError *error;
    
    // Parse Profiles.ini
    NSString *iniPath;
    iniPath = [path stringByAppendingPathComponent:@"profiles.ini"];
    NSString *iniString;
    iniString = [NSString stringWithContentsOfFile:iniPath
                                          encoding:NSASCIIStringEncoding
                                             error:&error];
    if (error) return nil;
    
    NSRange range = [iniString rangeOfString:@"Name=default"];
    if (range.location == NSNotFound) return nil;
    
    NSString *subIniString = [iniString substringFromIndex:range.location];
    range = [subIniString rangeOfString:@"Path="];
    if (range.location == NSNotFound) return nil;
    
    NSString *profileName = [subIniString substringFromIndex:(range.location+range.length)];
    range = [profileName rangeOfString:@"\n"];
    if (range.location == NSNotFound) return nil;
    
    profileName = [profileName substringToIndex:range.location];
    
    // Finalize things
    path = [path stringByAppendingFormat:@"/%@", profileName];
    if (withFileName) path = [path stringByAppendingFormat:@"/places.sqlite"];
    
    return (path);
}

-(NSArray*)bookmarkFiles
{
    NSArray *files = [NSArray arrayWithObjects:@"places.sqlite", @"places.sqlite-wal", nil];
    return files;
}

#pragma mark -
#pragma mark Firefox Parsing Methods

-(NSSet*)getBookmarks
{
    NSSet *bookmarks;
    bookmarks = nil;
    
    // Prüfen, ob App auf Bookmarks zugreifen kann
    if ([self isInstalled]) {
        
        // Bookmark-Path erzeugen
        NSString *path = [self fullBookmarkPathWithFileName:YES];
        if (!path) return nil;
        
        // Firefox-Bookmarkdaten lesen
        FMDatabase *db = [FMDatabase databaseWithPath:path];
        if (!db) TSLog (@"Firefox Connector Database Error");
        if (db) {
            
            NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
            
            if ([db open]) {
                
                // Einträge ermitteln
                FMResultSet *entries = [db executeQuery:@"SELECT b.id, a.url, b.title FROM moz_places a, moz_bookmarks b INNER JOIN moz_bookmarks AS c ON b.parent=c.id WHERE a.id=b.fk;"];
                while ([entries next]) {
                    
                    // Daten des Links ermitteln
                    NSString *idNo = [entries stringForColumn:@"id"];
                    NSString *URL = [entries stringForColumn:@"url"];
                    NSString *title = [entries stringForColumn:@"title"];
                    BOOL addFlag = YES;
                    if ([[URL substringToIndex:6] isEqualToString:@"place:"]) addFlag = NO;
                    if (addFlag) {
                        TSBookmark *bookmark = [[TSBookmark alloc] init];
                        [bookmark setIdNo:idNo];
                        [bookmark setTitle:title];
                        [bookmark setURL:[NSURL URLWithString:URL]];
                        [bookmark setIsFolder:NO];
                        [bookmark setBrowser:Firefox];
                        [results addObject:bookmark];
                    }
                }
                [db close];
                
                // Ergebnis-Array vorbereiten
                bookmarks = [NSSet setWithArray:results];
            }
        }
    }
    TSLog (@"Parsed %lu Firefox bookmarks",(unsigned long)[bookmarks count]);
    return bookmarks;
}


@end
