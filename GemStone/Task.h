//
//  Task.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTaskDone @"taskDone"
#define kTaskError @"taskError"
#define kTaskProgress @"taskProgress"

@interface Task : NSObject {
	NSTask			*task;
	int				doneCount;
	NSMutableString *errorOutput;
	NSMutableString *standardOutput;
}

- (void)cancelTask;
- (NSString *)currentDirectoryPath;
- (NSMutableDictionary *)environment;
- (void)error:(NSString *)message;
- (void)progress:(NSString *)aString;
- (void)notifyDone;
- (void)start;
- (void)verifyNoTask;

@end
