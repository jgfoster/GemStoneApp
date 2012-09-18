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

@interface Task : NSObject {
	NSTask			*task;
	int				doneCount;
	NSMutableString *errorOutput;
	NSMutableString *standardOutput;
}

- (void)cancelTask;
- (NSString *)currentDirectoryPath;
- (void)dataString:(NSString *)aString;
- (void)done;
- (void)doneWithError:(int)statusCode;
- (NSMutableDictionary *)environment;
- (BOOL)isRunning;
- (void)errorOutputString:(NSString *)message;
- (void)progress:(NSString *)aString;
- (void)run;
- (void)start;
- (void)verifyNoTask;

@end
