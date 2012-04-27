//
//  Versions.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppController.h"

@class AppController;

@interface Versions : NSObject <NSTableViewDataSource> {
	//	persistent data
	NSDate					*updateDate;
	NSMutableArray			*versions;
	NSArray					*sortDescriptors;

	//	other data
	IBOutlet NSTableView	*versionsTable;
	IBOutlet NSTextField	*updateDateField;

	NSTask					*task;
	NSMutableString			*taskOutput;
	NSString				*zipFilePath;
	NSFileHandle			*zipFile;
}

@property (readonly) NSDate			*updateDate;
@property (readonly) NSMutableArray	*versions;
@property (readonly) NSArray		*sortDescriptors;

- (void)cancelTask;
- (void)import:(NSURL *)url;
- (NSArray *)installedVersions;
- (void)update;
- (void)updateUI;

@end
