//
//  StartStone.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Task.h"
#import "Database.h"

@interface StartStone : Task {
	Database		*database;
}

- (void)setDatabase:(Database *)database;

@end
