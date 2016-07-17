//
//  NSString+Extensions.m
//  Brow
//
//  Created by Tim Schröder on 17.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "NSString+Extensions.h"

@implementation NSString (Extensions)

// Returns a sting representing this filename transformed (if neccesary) to make
// a valid (Mac OS X) filename.
- (NSString *) stringByMakingFileNameValid
{
    NSMutableString * validFileName = [NSMutableString stringWithString:self];
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

@end
