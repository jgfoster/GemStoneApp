//
//  ImportZippedVersion.h
//  GemStone
//
//  Created by James Foster on 5/8/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Task.h"

#define kImportDone @"importDone"
#define kImportError @"importError"
#define kImportProgress @"importProgress"

@interface ImportZippedVersion : Task {
	NSString	*zipFilePath;
}

@property (nonatomic, readwrite, retain) NSString *zipFilePath;

@end
