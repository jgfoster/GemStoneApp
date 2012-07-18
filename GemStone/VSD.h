//
//  VSD.h
//  GemStone
//
//  Created by James Foster on 7/18/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"

@interface VSD : DatabaseTask {
	NSString *path;
}

+ (VSD *)openPath:(NSString *)path usingDatabase:(Database *)database;

@end
