//
//  Login.m
//  GemStone
//
//  Created by James Foster on 5/1/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Login.h"

@implementation Login

@synthesize name;
@synthesize version;
@synthesize stoneHost;
@synthesize stoneName;
@synthesize isRpcGem;
@synthesize gemHost;
@synthesize gemNet;
@synthesize gemTask;
@synthesize isGuest;
@synthesize osUser;
@synthesize osPwd;
@synthesize gsUser;
@synthesize gsPwd;
@synthesize developer;

- (id)init;
{
	if (self = [super init]) {
		name = @"James";
	}
	return self;
}

@end
