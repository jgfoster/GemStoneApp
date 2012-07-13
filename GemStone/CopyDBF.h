//
//  CopyDBF.h
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"

@interface CopyDBF : DatabaseTask {
	NSString *path;
}

+ (NSString *)infoForFile:(NSString *)aString in:(Database *)aDatabase;

@end
