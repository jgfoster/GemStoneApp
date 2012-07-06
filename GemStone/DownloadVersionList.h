//
//  DownloadVersionList.h
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Task.h"

@interface DownloadVersionList : Task {
	NSMutableString *taskOutput;
	NSMutableArray	*versions;
}

@property (readonly) NSArray * versions;

@end
