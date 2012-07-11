//
//  AppController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Helper.h"
#import "Setup.h"
#import "Task.h"

@interface AppController : NSObject <NSOpenSavePanelDelegate> {
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	IBOutlet NSTextField			*lastUpdateDateField;
	IBOutlet NSArrayController		*databaseListController;
	IBOutlet NSArrayController		*logFileListController;
	IBOutlet NSArrayController		*loginListController;
	IBOutlet NSButton				*removeButton;
	IBOutlet NSArrayController		*versionListController;
	IBOutlet NSArrayController		*versionPopupController;

	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCancelButton;

	Helper		*helper;
	Task 		*task;		// to protect it from being garbage collected!
	Setup		*setup;
}

- (IBAction)cancelTask:(id)sender;
- (IBAction)installHelperTool:(id)sender;
- (void)openDirectory;
- (void)openLogFile;
- (IBAction)removeDatabase:(id)sender;
- (IBAction)removeHelperTool:(id)sender;
- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
- (void)taskFinished;
- (IBAction)updateVersionList:(id)sender;
- (IBAction)unzipRequest:(id)sender;

@property (readonly) Setup *setup;

@end
