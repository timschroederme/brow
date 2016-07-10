//
//  Brow.h
//  Brow
//
//  Created by Tim Schröder on 26.06.16.
//  Copyright © 2016 Tim Schröder. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <CoreFoundation/CoreFoundation.h>

@interface Brow : NSPreferencePane
{
    IBOutlet NSWindow *aboutWindow;
    IBOutlet NSTextView *aboutText;
}

-(IBAction)toggleSync:(id)sender;
-(IBAction)about:(id)sender;

@property (weak) IBOutlet NSSegmentedControl *toggleSyncButton;


@end
