//
//  AppController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "Helper.h"
#import "Task.h"
#import "UnzipVersion.h"
#import "Version.h"

@interface AppController : NSObject <NSTabViewDelegate> {
	//	Setup Tab
	IBOutlet NSTabViewItem			*setupTabViewItem;
	IBOutlet NSTextField			*helperToolMessage;
	IBOutlet NSButton				*authenticateButton;
	IBOutlet NSTextField			*currentShmall;
	IBOutlet NSTextField			*currentShmmax;
	IBOutlet NSTextField			*hostname;
	IBOutlet NSTextField			*ipAddress;
	IBOutlet NSButton				*addToEtcHostsButton;
	//	Versions Tab
	IBOutlet NSTextField			*lastUpdateDateField;
	//	Databases Tab
	IBOutlet NSArrayController		*databaseListController;
	IBOutlet NSTableView			*databaseTableView;
	IBOutlet NSTextView				*infoPanelTextView;
	IBOutlet NSArrayController		*logFileListController;
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
	IBOutlet NSTabView				*topTabView;
	IBOutlet NSButton				*repositoryConversionCheckbox;
	IBOutlet NSButton				*upgradeSeasideCheckbox;

	IBOutlet NSPanel				*infoPanel;
	IBOutlet NSPanel				*taskProgressPanel;
	IBOutlet NSTextView				*taskProgressText;
	IBOutlet NSProgressIndicator	*taskProgressIndicator;
	IBOutlet NSButton				*taskCloseWhenDoneButton;
	IBOutlet NSButton				*taskCancelButton;

    Helper                  *helper;
	NSManagedObjectContext	*managedObjectContext;
	NSManagedObject			*mySetup;	//	'setup' is too common for searches!
	NSMutableDictionary		*statmonitors;
	NSOperationQueue		*operations;
}

@property(readonly) NSManagedObjectContext	*managedObjectContext;

- (IBAction)addDatabase:(id)sender;
- (void)addOperation:(NSOperation *)anOperation;
- (IBAction)addToEtcHosts:(id)sender;
- (IBAction)cancelTask:(id)sender;
- (IBAction)clickedDataFile:(id)sender;
- (IBAction)closeInfoPanel:(id)sender;
- (Boolean)databaseExistsForVersion:(Version *)version;
- (void)databaseStartDone:(Database *)aDatabase;
- (void)databaseStopDone:(Database *)aDatabase;
- (IBAction)deleteStatmonFiles:(id)sender;
- (IBAction)doUpgrade:(id)sender;
- (void)ensureSharedMemory;
- (IBAction)gemToolsSession:(id)sender;
- (IBAction)installHelperTool:(id)sender;
- (NSString *)mostAdvancedVersion;
- (NSNumber *)nextDatabaseIdentifier;
- (IBAction)openBrowserOnAvailableVersions:(id)sender;
- (IBAction)openGemConfigFile:(id)sender;
- (IBAction)openDefaultConfigFile:(id)sender;
- (IBAction)openStatmonFiles:(id)sender;
- (IBAction)openStoneConfigFile:(id)sender;
- (IBAction)openSystemConfigFile:(id)sender;
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
- (void)updateSetupState;
- (NSArray *)versionList;
- (IBAction)versionListDownloadRequest:(id)sender;
- (void)versionUnzipDone:(UnzipVersion *)unzipTask;
- (IBAction)versionUnzipRequest:(id)sender;

@end
