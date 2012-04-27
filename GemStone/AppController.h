//
//  AppController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Helper.h"
#import "Versions.h"
#import "VersionsController.h"

@class Versions;

@interface AppController : NSObject <NSOpenSavePanelDelegate> {
	IBOutlet Helper					*helper;
	IBOutlet Versions				*versions;
	
	IBOutlet NSTabView				*tabView;
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	
	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCancelButton;

	SEL			cancelMethod;
}

@property (readonly) Versions *versions;

- (IBAction)installHelperTool:(id)sender;
- (IBAction)importVersion:(id)sender;
- (IBAction)updateVersions:(id)sender;
- (IBAction)cancelTask:(id)sender;

- (void)cancelMethod:(SEL)selector;
- (void)startTaskProgressSheet;
- (void)taskFinished;
- (void)taskProgress:(NSString *)string;

@end
