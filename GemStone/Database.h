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

@interface Database : NSManagedObject <NSTableViewDataSource, NSTableViewDelegate> {
	// persistent
	NSNumber *identifier;  
	NSNumber *indexInArray;  
	NSDate	 *lastStartDate;
	NSString *name;
	NSString *netLDI;
	NSNumber *spc_mb;
	NSString *version;

	// transient
	NSNumber	*isRunningCode;
	NSArray		*statmonFiles;
	Task		*statmonitor;
}

@property (readonly)			NSNumber *identifier;  
@property (nonatomic, retain)	NSNumber *indexInArray;  
@property (readonly)			NSDate	 *lastStartDate;
@property (nonatomic, retain)	NSString *name;
@property (nonatomic, retain)	NSString *netLDI;
@property (nonatomic, retain)	NSNumber *spc_mb;
@property (nonatomic, retain)	NSString *version;

@property (nonatomic, retain)	NSNumber *isRunningCode;

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
- (void)refreshStatmonFiles;
- (void)restore;
- (void)setIsRunning:(BOOL)aBool;
- (NSString *)sizeForDataFile:(NSString *)file;
- (void)stopDatabase;

@end
