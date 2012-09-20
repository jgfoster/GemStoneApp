//
//  Database.h
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kDababaseInfoChanged @"databaseInfoChanged"
#define kDatabaseStartRequest @"databaseStartRequest"
#define kDatabaseStopRequest @"databaseStopRequest"

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
	NSNumber *isRunningCode;
	NSString *restorePath;
	NSArray *statmonFiles;
}

@property (readonly)			NSNumber *identifier;  
@property (nonatomic, retain)	NSNumber *indexInArray;  
@property (readonly)			NSDate	 *lastStartDate;
@property (nonatomic, retain)	NSString *name;
@property (nonatomic, retain)	NSString *netLDI;
@property (nonatomic, retain)	NSNumber *spc_mb;
@property (nonatomic, retain)	NSString *version;

@property (nonatomic, retain)	NSNumber *isRunningCode;
@property (nonatomic, retain)	NSString *restorePath;

- (void)archiveCurrentLogFiles;
- (void)archiveCurrentTransactionLogs;
- (NSArray *)dataFiles;
- (NSString *)directory;
- (void)deleteAll;
- (void)deleteOldLogFiles;
- (void)deleteOldTranLogs;
- (void)deleteStatmonFilesAtIndexes:(NSIndexSet *)indexes;
- (NSString *)descriptionOfOldLogFiles;
- (NSString *)descriptionOfOldTranLogs;
- (NSString *)gemstone;
- (void)gsList:(NSArray *)list;
- (NSString *)infoForDataFile:(NSString *)file;
- (void)installBaseExtent;
- (void)installGlassExtent;
- (BOOL)isRunning;
- (NSString *)isRunningString;
- (NSArray *)logFiles;
- (void)open;
- (void)openStatmonFilesAtIndexes:(NSIndexSet *)indexes;
- (void)refreshStatmonFiles;
- (void)restore;
- (void)setIsRunning:(BOOL)aBool;
- (NSString *)sizeForDataFile:(NSString *)file;
- (void)startDatabase;
- (void)stopDatabase;

@end
