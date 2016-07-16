//
//  TSChromeConnector.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSChromeConnector.h"
#import "TSBrowserConnector.h"
#import "NSURL+Extensions.h"
#import "Constants.h"
#import "TSBookmark.h"
#import "TSLogger.h"

@implementation TSChromeConnector

@synthesize cache;


static TSChromeConnector *_sharedConnector = nil;

#pragma mark -
#pragma mark Singleton Methods

+ (TSChromeConnector *)sharedConnector
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
#pragma mark Chrome Connection Methods


-(NSString*)appPath
{
    NSString *path;
    path = [[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:[self identifier]] path];
    TSLog (@"Chrome installation path: %@", path)
    return path;
}

-(NSString*)identifier
{
    return (@"com.google.Chrome");
}

-(Browser)browserName
{
    return Chrome;
}

-(NSArray*)bookmarkFilePaths
{
    NSArray *profiles = [self profileNames];
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[profiles count]];
    for (id name in profiles)
    {
        [paths addObject:[self bookmarkFileForProfile:name]];
    }
    TSLog (@"Chrome bookmark file paths: %@", paths);
    return ([NSArray arrayWithArray:paths]);
}

-(NSString*)bookmarkFile
{
    return (@"Bookmarks");
}

-(NSArray*)bookmarkFileDirectories
{
    NSArray *profiles = [self profileNames];
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[profiles count]];
    for (id name in profiles)
    {
        [paths addObject:[self bookmarkFolderForProfile:name]];
    }
    TSLog (@"Chrome bookmark file paths: %@", paths);
    return ([NSArray arrayWithArray:paths]);
}

-(NSString*)bookmarkFileForProfile:(NSString*)profileName
{
    NSString *path = [NSString stringWithFormat:@"%@/Library/Application Support/Google/Chrome/%@/Bookmarks", NSHomeDirectory(), profileName];
    return path;
}

-(NSString*)bookmarkFolderForProfile:(NSString*)profileName
{
    NSString *path = [NSString stringWithFormat:@"%@/Library/Application Support/Google/Chrome/%@", NSHomeDirectory(), profileName];
    return path;
}


-(NSString*)preferencesFilePath
{
    return ([NSString stringWithFormat:@"%@/Library/Application Support/Google/Chrome/Local State", NSHomeDirectory()]);
}

-(NSArray*)profileNames
{
    NSArray *result;
    NSData *chromeData = [NSData dataWithContentsOfFile:[self preferencesFilePath]];
    if (!chromeData) {
        return nil;
    }
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:chromeData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (!dict) {
        return nil;
    }
    NSDictionary *profiles = [[dict objectForKey:@"profile"] objectForKey:@"info_cache"];
    if (!profiles) {
        return nil;
    }
    result = [profiles allKeys];
    
    TSLog (@"Chrome profiles: %@", result);
    return (result);
}

#pragma mark -
#pragma mark Chrome Parsing Methods

-(void)parseEntry:(NSDictionary*)entry
{
    
    NSString *type = [entry objectForKey:@"type"];
    if (type) {
        // Folder zu Cache hinzufügen
        if ([type isEqualToString:@"folder"]) {
            
            // Diese Routine für alle Kinder des Folders aufrufen
            NSArray *children = [entry objectForKey:@"children"];
            if (children) {
                for (NSDictionary *child in children) [self parseEntry:child];
            }
        }
        
        // Entries zu Cache hinzufügen
        if ([type isEqualToString:@"url"]) {
            
            NSString *idNo = [entry objectForKey:@"id"];
            NSString *title = [entry objectForKey:@"name"];
            NSURL *URL = [NSURL URLWithString:[entry objectForKey:@"url"]];
            
            TSBookmark *entry = [[TSBookmark alloc] init];
            [entry setIdNo:idNo];
            [entry setURL:URL];
            [entry setTitle:title];
            [entry setBrowser:Chrome];
            [cache addObject:entry];
        }
    } else {
        NSArray *children = [entry objectForKey:@"children"];
        if (children) {
            for (NSDictionary *child in children) [self parseEntry:child];
        }
    }
}

-(NSSet*)getBookmarks
{
    NSSet *bookmarks;
    bookmarks = nil;
    
    // Prüfen, ob App auf Bookmarks zugreifen kann
    if ([self isInstalled]) {
        
        // Cache vorbereiten
        if (cache) {
            [cache removeAllObjects];
        } else {
            cache = [NSMutableArray arrayWithCapacity:0];
        }
        
        // Über alle Chrome-Profile iterieren
        NSArray *profiles = [self profileNames];
        for (id profileName in profiles) {
            
            // Chrome-Bookmark-Pfad vorbereiten
            NSString *bookmarkFile = [self bookmarkFileForProfile:profileName];
            TSLog (@"Getting Chrome Boomkarks from file %@", bookmarkFile);

            // Chrome-Bookmark-Daten lesen
            NSData *chromeData = [NSData dataWithContentsOfFile:bookmarkFile];
            
            if (chromeData) {
                NSError *error;
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:chromeData
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&error];
                if (result) {
                    
                    NSArray *rootArray = [[result objectForKey:@"roots"] allValues];
                    for (id rootEntry in rootArray) {
                        if ([rootEntry isKindOfClass:[NSDictionary class]]) [self parseEntry:rootEntry];
                    }
                    
                    // Leere Ordner wieder löschen
                    NSMutableArray *delArray = [NSMutableArray arrayWithCapacity:0];
                    for (TSBookmark *bm in cache) {
                        if (([bm isFolder]) && ([[bm children] count] == 0)) [delArray addObject:bm];
                    }
                    [cache removeObjectsInArray:delArray];
                }
            }
        }
        bookmarks = [NSSet setWithArray:cache];
    }
    return bookmarks;
}


@end
