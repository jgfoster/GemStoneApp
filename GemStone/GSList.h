//
//  GSList.h
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"

@interface GSList : DatabaseTask

+ (NSArray *)processListUsingDatabase:(Database *)aDatabase;

@end
