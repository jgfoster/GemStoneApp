//
//  Database.h
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Task.h"

@interface Database : NSManagedObject <NSTableViewDataSource, NSTableViewDelegate> { }

// persistent
@property (readonly)	NSNumber *identifier;
@property				NSNumber *indexInArray;
@property				NSDate	 *lastStartDate;
@property				NSString *name;
@property				NSString *netLDI;
@property				NSNumber *spc_mb;
@property				NSString *version;
// transient
@property (readonly)	BOOL	  isRunning;
@property (readonly)	NSArray	 *statmonFiles;
@property				Task	 *statmonitor;

- (void)archiveCurrentLogFiles;
- (void)archiveCurrentTransactionLogs;
- (void)createConfigFiles;
- (NSArray *)dataFiles;
- (void)deleteAll;
- (void)deleteOldLogFiles;
- (void)deleteOldTranLogs;
- (void)deleteStatmonFilesAtIndexes:(NSIndexSet *)indexes;
- (NSString *)descriptionOfOldLogFiles;
- (NSString *)descriptionOfOldTranLogs;
- (NSString *)directory;
- (void)doubleClickStatmon:(id)sender;
- (NSString *)gemstone;
- (NSString *)gemToolsLogin;
- (void)gsList:(NSArray *)list;
- (NSString *)infoForDataFile:(NSString *)file;
- (BOOL)isRunning;
- (NSString *)isRunningString;
- (NSArray *)logFiles;
- (void)open;
- (void)openDefaultConfigFile;
- (void)openGemConfigFile;
- (void)openStoneConfigFile;
- (void)openSystemConfigFile;
- (void)openStatmonFilesAtIndexes:(NSIndexSet *)indexes;
- (IBAction)openTerminal:(id)sender;
- (IBAction)openTopaz:(id)sender;
- (IBAction)openWebTools:(id)sender;
- (void)refreshStatmonFiles;
- (void)restore;
- (void)setIsRunning:(BOOL)aBool;
- (NSString *)sizeForDataFile:(NSString *)file;
- (void)stopDatabase;

@end
