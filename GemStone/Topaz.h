//
//  Topaz.h
//  GemStone
//
//  Created by James Foster on 7/16/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"
#import "Login.h"

@class Topaz;

typedef void(^block_t)(Topaz *);

@interface Topaz : DatabaseTask {
	Login		*login;
	NSInteger	 session;
	block_t		 block;
}

@property (nonatomic, retain)	Login	*login;
@property (nonatomic, copy)		block_t	 block;

+ (id)login:(Login *)aLogin toDatabase:(Database *)aDatabase andDo:(block_t)aBlock;

- (void)fullBackupTo:(NSString *)aString;
- (void)restoreFromBackup:(NSString *)aString;

@end
