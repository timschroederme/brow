//
//  TSStream.m
//  Brow
//
//  Created by Tim Schröder on 02.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import "TSStream.h"

@implementation TSStream

FSEventStreamRef stream;

-(void)setStream:(FSEventStreamRef)streamValue
{
    stream = streamValue;
}

-(FSEventStreamRef)getStream
{
    return stream;
}

@end
