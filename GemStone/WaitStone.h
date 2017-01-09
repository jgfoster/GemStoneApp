//
//  WaitStone.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"

@interface WaitStone : DatabaseTask {
	BOOL		isReady;
}

@property (readonly)			BOOL		isReady;

+ (BOOL)isStoneRunningForDatabase:(Database *)database;
+ (BOOL)isNetLdiRunningForDatabase:(Database *)database;

@end
