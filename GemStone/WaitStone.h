//
//  WaitStone.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"

@interface WaitStone : DatabaseTask {
	NSString	*name;
	BOOL		isReady;
}

@property (nonatomic, retain)	NSString	*name;
@property (readonly)			BOOL		isReady;

+ (BOOL)isStoneRunningForDatabase:(Database *)database;
+ (BOOL)isNetLdiRunningForDatabase:(Database *)database;

@end
