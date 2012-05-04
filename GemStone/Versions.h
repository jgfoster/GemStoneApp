//
//  Versions.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppController.h"
#import "Version.h"

#define kVersionsTaskDone		@"versionsTaskDone"
#define kVersionsTaskError		@"versionsTaskError"
#define kVersionsTaskProgress	@"versionsTaskProgress"

@class AppController;

@interface Versions : NSObject <NSTableViewDataSource> {
	//	persistent data
	NSDate					*updateDate;
	NSMutableArray			*versions;
	NSArray					*sortDescriptors;

	//	other data
	NSTask					*task;
	NSMutableString			*taskOutput;
	NSString				*zipFilePath;
	NSFileHandle			*zipFile;
}

@property (readonly) NSDate		*updateDate;
@property (readonly) NSArray	*versions;
@property (readonly) NSArray	*sortDescriptors;

+ (NSString *)archiveFilePath;

// collection accessors for versions
- (NSInteger)countOfVersions;
- (id)objectInVersionsAtIndex:(NSUInteger)index;

- (NSString *)createZipFileForVersionAtRow:(NSInteger)rowIndex;
- (void)downloadVersionAtRow:(NSInteger)rowIndex;
- (id)getRow:(NSInteger)rowIndex column:(NSString *)columnIdentifier;
- (void)import:(NSURL *)url;
- (NSArray *)installedVersions;
- (NSString *)removeVersionAtRow:(NSInteger)rowIndex;
- (void)save;
- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;
- (void)terminateTask;
- (void)update;
- (NSString *)updateDateString;
- (void)updateIsInstalled;

@end
