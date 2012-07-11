//
//  StartNetLDI.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>

#import "StartNetLDI.h"
#import "Utilities.h"

@implementation StartNetLDI

- (NSArray *)arguments;
{
	NSString *netLDI = [database netLDI];
	return [NSArray arrayWithObjects: 
			@"-g",
			@"-a",
			NSUserName(),
			@"-l",
			[NSString stringWithFormat:@"log/%@.log", netLDI],
			netLDI,
			nil];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/startnetldi", [database gemstone]];
}

/*
- (uint16)port;
{
	uint16 port = [database netLdiPort];
	if (port) return port;
	int sock = socket(PF_INET, SOCK_STREAM, 0);
	int reuse = 1;
	if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse))) {
		AppError(@"setsockopt() failed with errno = %i", errno);
	}
	if (listen(sock, 0)) {
		AppError(@"listen() failed with errno = %i", errno);
	}
	struct sockaddr_in sin;
	socklen_t len = sizeof(sin);
	if (getsockname(sock, (struct sockaddr *) &sin, &len)) {
		AppError(@"getsockname() failed with errno = %i", errno);
	}
	port = sin.sin_port;
	[database setNetLdiPort: port];
	int result = close(sock);
	if (result) {
		AppError(@"close() of socket failed with errno = %i", errno);
	}
	return port;
}
*/

@end
