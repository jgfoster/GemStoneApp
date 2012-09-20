//
//  AppController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Helper.h"
#import "Task.h"
#import "Version.h"

@interface AppController : NSObject <NSOpenSavePanelDelegate, NSTabViewDelegate> {
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	IBOutlet NSTextField			*lastUpdateDateField;
	IBOutlet NSArrayController		*databaseListController;
	IBOutlet NSTableView			*databaseTableView;
	IBOutlet NSArrayController		*logFileListController;
	IBOutlet NSArrayController		*loginListController;
	IBOutlet NSButton				*removeButton;
	IBOutlet NSArrayController		*versionListController;
	IBOutlet NSArrayController		*versionPopupController;
	IBOutlet NSArrayController		*upgradePopupController;
	IBOutlet NSTextField			*oldLogFilesText;
	IBOutlet NSButton				*deleteLogFilesButton;
	IBOutlet NSTextField			*oldTranLogsText;
	IBOutlet NSButton				*deleteTranLogsButton;
	IBOutlet NSArrayController		*dataFileListController;
	IBOutlet NSTextView				*dataFileInfo;
	IBOutlet NSTextField			*dataFileSizeText;
	IBOutlet NSArrayController		*processListController;
	IBOutlet NSTabViewItem			*gsListTabViewItem;
	IBOutlet NSTableView			*statmonTableView;
	IBOutlet NSObjectController		*statmonFileSelectedController;
	IBOutlet NSButton				*repositoryConversionCheckbox;
	IBOutlet NSButton				*upgradeSeasideCheckbox;

	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCloseWhenDoneButton;
	IBOutlet NSButton				*taskCancelButton;

	Helper					*helper;
	NSManagedObjectContext	*managedObjectContext;
	NSManagedObject			*mySetup;	//	'setup' is too common for searches!
	Task					*taskX;		//	to protect it from being garbage collected!
	NSMutableDictionary		*statmonitors;
	NSOperationQueue		*operations;
}

- (IBAction)cancelTask:(id)sender;
- (IBAction)clickedDataFile:(id)sender;
- (IBAction)defaultLogin:(id)sender;
- (IBAction)deleteStatmonFiles:(id)sender;
- (IBAction)doUpgrade:(id)sender;
- (IBAction)installHelperTool:(id)sender;
- (NSString *)mostAdvancedVersion;
- (NSNumber *)nextDatabaseIdentifier;
- (IBAction)openStatmonFiles:(id)sender;
- (IBAction)removeDatabase:(id)sender;
- (IBAction)removeHelperTool:(id)sender;
- (void)setIsStatmonFileSelected:(BOOL)flag;
- (NSTableView *)statmonTableView;
- (IBAction)taskCloseWhenDone:(id)sender;
- (void)taskFinishedAfterDelay;
- (void)versionDownloadRequest:(Version *)aVersion;
- (NSArray *)versionList;
- (IBAction)versionListDownloadRequest:(id)sender;
- (void)versionRemoveRequest:(Version *)aVersion;
- (IBAction)versionUnzipRequest:(id)sender;

@end
