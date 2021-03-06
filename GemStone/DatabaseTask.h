//
//  DatabaseTask.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Task.h"
#import "Database.h"

@interface DatabaseTask : Task { }

@property	Database *database;

+ (id)forDatabase:(Database *)aDatabase;
- (NSString *)binName;

@end
