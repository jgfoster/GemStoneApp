//
//  Task.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define mustOverride() 	[NSException raise:NSInternalInconsistencyException \
format:@"You must override \'%@\' in a subclass", NSStringFromSelector(_cmd)];

@interface Task : NSOperation {
	NSTask			*task;
	BOOL			 didLaunch;
	int				 doneCount;
	NSMutableString	*allOutput;
	NSMutableString *errorOutput;
	NSMutableString *standardOutput;
}

- (NSString *)currentDirectoryPath;
- (void)dataString:(NSString *)aString;
- (void)delayFor:(NSTimeInterval)seconds;
- (void)done;
- (void)doneWithError:(int)statusCode;
- (NSMutableDictionary *)environment;
- (void)errorOutputString:(NSString *)message;
- (void)progress:(NSString *)aString;
- (void)removeReadCompletionNotifications;
- (void)startTask;

@end
