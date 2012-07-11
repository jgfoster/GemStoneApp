//
//  StopNetLDI.m
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "StopNetLDI.h"

@implementation StopNetLDI

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			[database netLDI],
			nil];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/stopnetldi", [database gemstone]];
}

@end
