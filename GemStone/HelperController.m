//
//  HelperController.m
//  GemStone
//
//  Created by James Foster on 4/27/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "HelperController.h"

@implementation HelperController

- (void)awakeFromNib;
{
	helper = [Helper new];
	BOOL isCurrent = [helper isCurrent];
	[helperToolMessage setHidden:!isCurrent];
	[authenticateButton setEnabled:!isCurrent];
}

- (IBAction)installHelperTool:(id)sender
{
	NSString *errorString = [helper install];
	if (errorString) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert setMessageText:@"Installation failed:"];
		[alert setInformativeText:errorString];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
	} else {
		[authenticateButton setEnabled:NO];
		[helperToolMessage setHidden:NO];
	}
}

@end
