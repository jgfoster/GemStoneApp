//
//  DatabaseTask.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Task.h"
#import "Database.h"

@interface DatabaseTask : Task {
	Database		*database;
}

- (void)setDatabase:(Database *)database;

@end
