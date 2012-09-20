//
//  UnzipVersion.h
//  GemStone
//
//  Created by James Foster on 9/19/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Download.h"

@interface UnzipVersion : Task {
	NSString	*zipFilePath;
	NSArray		*directoryContents;
}

@property (nonatomic, readwrite, retain) NSString *zipFilePath;

@end
