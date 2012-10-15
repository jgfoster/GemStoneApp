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

@interface AppController : NSObject <NSTabViewDelegate> {
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	IBOutlet NSTextField			*lastUpdateDateField;
	IBOutlet NSArrayController		*databaseListController;
	IBOutlet NSTableView			*databaseTableView;
	IBOutlet NSTextView				*infoPanelTextView;
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

	IBOutlet NSPanel				*infoPanel;
	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCloseWhenDoneButton;
	IBOutlet NSButton				*taskCancelButton;

	Helper					*helper;
	NSManagedObjectContext	*managedObjectContext;
	NSManagedObject			*mySetup;	//	'setup' is too common for searches!
	NSMutableDictionary		*statmonitors;
	NSOperationQueue		*operations;
}

@property(readonly) NSManagedObjectContext	*managedObjectContext;

- (void)addOperation:(NSOperation *)anOperation;
- (IBAction)cancelTask:(id)sender;
- (IBAction)clickedDataFile:(id)sender;
- (IBAction)closeInfoPanel:(id)sender;
- (IBAction)defaultLogin:(id)sender;
- (IBAction)deleteStatmonFiles:(id)sender;
- (IBAction)doUpgrade:(id)sender;
- (IBAction)installHelperTool:(id)sender;
- (NSString *)mostAdvancedVersion;
- (NSNumber *)nextDatabaseIdentifier;
- (IBAction)openStatmonFiles:(id)sender;
- (IBAction)removeDatabase:(id)sender;
- (IBAction)removeHelperTool:(id)sender;
- (void)removeVersionDone;
- (void)setIsStatmonFileSelected:(BOOL)flag;
- (IBAction)showHelperToolInfo:(id)sender;
- (NSTableView *)statmonTableView;
- (void)taskStart:(NSString *)aString;
- (IBAction)taskCloseWhenDone:(id)sender;
- (void)taskError:(NSString *)aString;
- (void)taskFinishedAfterDelay;
- (void)taskProgress:(NSString *)aString;
- (void)updateDatabaseList:(id)sender;
- (NSArray *)versionList;
- (IBAction)versionListDownloadRequest:(id)sender;
- (IBAction)versionUnzipRequest:(id)sender;

@end
