//
//  TSLaunchDController.h
//  Brow
//
//  Created by Tim Schröder on 10.07.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSLaunchDController : NSObject

+(TSLaunchDController *)sharedController;
-(void)loadService:(NSString*)bundleIdentifier withPList:(NSDictionary*)pList;
-(void)unLoadService:(NSString*)bundleIdentifier;


@end
