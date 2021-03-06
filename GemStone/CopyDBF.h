//
//  CopyDBF.h
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"

@interface CopyDBF : DatabaseTask { }

@property	NSString *path;

+ (NSString *)infoForFile:(NSString *)aString in:(Database *)aDatabase;

@end
