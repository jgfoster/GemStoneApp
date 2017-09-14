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

@interface AppController : NSObject <NSTabViewDelegate> { }

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
