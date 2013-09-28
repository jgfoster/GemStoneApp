//
//  Topaz.h
//  GemStone
//
//  Created by James Foster on 7/16/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"

@class Topaz;

typedef void(^block_t)(Topaz *);

@interface Topaz : DatabaseTask {
	NSInteger	 session;
	block_t		 block;
}

@property (nonatomic, copy)		block_t	 block;

+ (id)database:(Database *)aDatabase do:(block_t)aBlock;

- (void)fullBackupTo:(NSString *)aString;
- (void)restoreFromBackup:(NSString *)aString;

@end
