//
//  Task.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Task : NSOperation {
	NSTask			*task;
	BOOL			 didLaunch;
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
- (void)terminateTask;

@end
