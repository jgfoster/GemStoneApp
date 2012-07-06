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
	NSString *name;
	NSNumber *spc_mb;
	NSString *version;
	NSDate	 *lastStartDate;
}

@property (readonly)			NSNumber *identifier;  
@property (nonatomic, retain)	NSNumber *indexInArray;  
@property (nonatomic, retain)	NSString *name;
@property (nonatomic, retain)	NSNumber *spc_mb;
@property (nonatomic, retain)	NSString *version;
@property (readonly)			NSDate	 *lastStartDate;

- (BOOL)canEditVersion;
- (BOOL)canInitialize;
- (BOOL)canRestore;
- (BOOL)canStart;
- (BOOL)canStop;
- (NSString *)directory;
- (void)deleteAll;
- (NSString *)gemstone;
- (void)installBaseExtent;
- (void)installGlassExtent;
- (NSString *)nameOrDefault;
- (void)restore;
- (void)start;
- (void)stop;

@end
