//
//  GSList.h
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"

@interface GSList : DatabaseTask {
	BOOL	foundNoProcesses;
}

+ (NSArray *)processListUsingDatabase:(Database *)aDatabase;

@end
