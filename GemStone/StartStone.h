//
//  StartStone.h
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"

@interface StartStone : DatabaseTask {
	NSArray *args;
}

@property(nonatomic, retain) NSArray *args;

@end
