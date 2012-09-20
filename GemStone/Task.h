//
//  Task.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTaskDone		@"taskDone"
#define kTaskError		@"taskError"
#define kTaskProgress	@"taskProgress"
#define kTaskStart		@"taskStart"

@interface Task : NSOperation {
	NSTask			*task;
	int				 doneCount;
	NSMutableString *errorOutput;
	NSMutableString *standardOutput;
}

- (NSString *)currentDirectoryPath;
- (void)dataString:(NSString *)aString;
- (void)done;
- (void)doneWithError:(int)statusCode;
- (void)doRunLoopFor:(double)seconds;
- (NSMutableDictionary *)environment;
- (void)errorOutputString:(NSString *)message;
- (void)progress:(NSString *)aString;
- (void)startTask;

@end
