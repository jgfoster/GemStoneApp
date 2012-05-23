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

@interface AppController : NSObject <NSOpenSavePanelDelegate> {
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	IBOutlet NSTextField			*lastUpdateDateField;
	IBOutlet NSArrayController		*databaseListController;
	IBOutlet NSArrayController		*loginListController;
	IBOutlet NSArrayController		*versionListController;
	IBOutlet NSArrayController		*versionPopupController;

	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCancelButton;

	Helper	*helper;
	id		task;		// to protect it from being garbage collected!
	Setup	*setup;
}

- (IBAction)cancelTask:(id)sender;
- (IBAction)installHelperTool:(id)sender;
- (IBAction)removeDatabase:(id)sender;
- (IBAction)updateVersionList:(id)sender;
- (IBAction)unzipRequest:(id)sender;

@property (readonly) Setup *setup;

@end
