//
//  StartNetLDI.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>

#import "StartNetLDI.h"
#import "Utilities.h"

@implementation StartNetLDI

- (NSArray *)arguments;
{
	NSString *netLDI = [self.database netLDI];
	return [NSArray arrayWithObjects: 
			@"-g",
			@"-a",
			NSUserName(),
			@"-l",
			[NSString stringWithFormat:@"log/%@.log", netLDI],
			netLDI,
			nil];
}

- (NSString *)binName;
{ 
	return @"startnetldi";
}

@end
