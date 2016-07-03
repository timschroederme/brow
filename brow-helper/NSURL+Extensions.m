//
//  NSURL+Extensions.m
//  Brow
//
//  Created by Tim Schröder on 27.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "NSURL+Extensions.h"

@implementation NSURL (Extensions)


// Compares two URLs
- (BOOL) isEqualToURL:(NSURL*)otherURL
{
    return ([[self absoluteURL] isEqual:[otherURL absoluteURL]]) || ([self isFileURL] && [otherURL isFileURL] && ([[self path] isEqual:[otherURL path]]));
}

@end
