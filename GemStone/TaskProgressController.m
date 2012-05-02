//
//  TaskProgressController.m
//  GemStone
//
//  Created by James Foster on 4/27/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "TaskProgressController.h"

@implementation TaskProgressController

- (void)awakeFromNib;
{
	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
}

- (IBAction)cancelTask:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kTaskCancelNotificationName object:NSApp];
}

- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
{
    [NSApp beginSheet:taskProgressPanel
       modalForWindow:[NSApp mainWindow]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
	[taskProgressIndicator startAnimation:self];
	[taskCancelButton setEnabled:allowCancel];
}

- (void)taskFinished
{
	[taskProgressIndicator stopAnimation:self];
	[taskProgressText setString:[NSMutableString new]];
	[NSApp endSheet:taskProgressPanel];
	[taskProgressPanel orderOut:nil];
}

- (void)taskProgress:(NSString *)string
{
	[taskProgressText insertText:string];
}

@end
