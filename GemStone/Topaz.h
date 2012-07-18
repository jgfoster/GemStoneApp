//
//  Topaz.h
//  GemStone
//
//  Created by James Foster on 7/16/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DatabaseTask.h"
#import "Login.h"

@interface Topaz : DatabaseTask {
	Login		*login;
	NSInteger	session;
}

@property (nonatomic, retain) Login *login;

+ (id)login:(Login *)aLogin toDatabase:(Database *)aDatabase;

- (void)restoreFromBackup;

@end
