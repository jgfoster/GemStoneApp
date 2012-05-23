//
//  ImportZippedVersion.h
//  GemStone
//
//  Created by James Foster on 5/8/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kImportDone @"importDone"
#define kImportError @"importError"
#define kImportProgress @"importProgress"

@interface ImportZippedVersion : NSObject {
	NSTask		*task;
	NSString	*zipFilePath;
}

@property (nonatomic, readwrite, retain) NSString *zipFilePath;

- (void)start;

@end
