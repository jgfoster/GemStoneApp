//
//  DownloadVersionList.h
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Download.h"

@interface DownloadVersionList : Download {
	NSMutableString *taskOutput;
	NSMutableArray	*versions;
}

@property (readonly) NSArray * versions;

@end
