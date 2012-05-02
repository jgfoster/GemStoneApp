//
//  TaskProgressController.h
//  GemStone
//
//  Created by James Foster on 4/27/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kTaskCancelNotificationName @"cancelTask"


@interface TaskProgressController : NSObject {
	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCancelButton;
}

- (IBAction)cancelTask:(id)sender;

- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
- (void)taskFinished;
- (void)taskProgress:(NSString *)string;

@end
