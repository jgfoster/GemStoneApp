//
//  Database.h
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kDatabaseStartRequest @"databaseStartRequest"
#define kDatabaseStopRequest @"databaseStopRequest"

@interface Database : NSManagedObject {
	NSNumber *identifier;  
	NSNumber *indexInArray;  
	NSNumber *isRunningCode;
	NSDate	 *lastStartDate;
	NSString *name;
	NSString *netLDI;
	NSNumber *spc_mb;
	NSString *version;
}

@property (readonly)			NSNumber *identifier;  
@property (nonatomic, retain)	NSNumber *indexInArray;  
@property (nonatomic, retain)	NSNumber *isRunningCode;
@property (readonly)			NSDate	 *lastStartDate;
@property (nonatomic, retain)	NSString *name;
@property (nonatomic, retain)	NSString *netLDI;
@property (nonatomic, retain)	NSNumber *spc_mb;
@property (nonatomic, retain)	NSString *version;

- (BOOL)canInitialize;
- (BOOL)canStart;
- (NSString *)directory;
- (void)deleteAll;
- (NSString *)gemstone;
- (void)installBaseExtent;
- (void)installGlassExtent;
- (BOOL)isRunning;
- (NSString *)isRunningString;
- (NSArray *)logFiles;
- (void)open;
- (void)restore;
- (void)setIsRunning:(BOOL)aBool;
- (void)start;
- (void)stop;

@end
