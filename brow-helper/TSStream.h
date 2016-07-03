//
//  TSStream.h
//  Brow
//
//  Created by Tim Schröder on 02.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSStream : NSObject

-(void)setStream:(FSEventStreamRef)stream;
-(FSEventStreamRef)getStream;

@end
