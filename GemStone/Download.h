//
//  Download.h
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownloadDone @"downloadDone"
#define kDownloadError @"downloadError"
#define kDownloadProgress @"downloadProgress"

@interface Download : NSObject {
	NSTask *task;
}

- (void)cancelTask;
- (void)notifyDone;
- (void)start;
- (void)verifyNoTask;

@end
