//
//  StopNetLDI.m
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "StopNetLDI.h"
#import "Utilities.h"

@implementation StopNetLDI

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			[database netLDI],
			nil];
}

- (NSString *)binName;
{ 
	return @"stopnetldi";
}

@end
