//
//  NSFileManager+Extensions.h
//  Brow
//
//  Created by Tim Schröder on 17.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Extensions)

-(BOOL) createDirectory:(NSString*)path;
-(void) hideFileExtensionOfFile:(NSString*)path;

@end
