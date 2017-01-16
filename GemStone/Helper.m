 //
//  Helper.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Helper.h"
#import "../Gemstone.Helper/Utilities.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
//	#include <sys/types.h>
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#import "Utilities.h"

#define MAX_PATH_SIZE 128

@implementation Helper

// returns 0 for success, 1 for error
int sendMessage(const struct HelperMessage * messageOut, struct HelperMessage * messageIn)
{
    int socket_fd = socket(PF_UNIX, SOCK_STREAM, 0);
    if (socket_fd == -1) {
        NSLog(@"socket() failed!");
        return 1;
    }
    
    int size = sizeof(struct sockaddr) + MAX_PATH_SIZE;
    char address_data[size];
    struct sockaddr* address = (struct sockaddr*) &address_data;
    address->sa_len = size;
    address->sa_family = AF_UNIX;      // unix domain socket
    strncpy(address->sa_data, kSocketPath, MAX_PATH_SIZE);
    
    if (connect(socket_fd, address, size) == -1) {
        NSLog(@"Socket connect() failed!");
        return 1;
    }
    int count = messageSize(messageOut);
    long written = write(socket_fd, messageOut, count);
    if (count != written) {
        NSLog(@"tried to write %i, but wrote %li", count, written);
        close(socket_fd);
        return 1;
    }
    if (readMessage(socket_fd, messageIn)) {
        NSLog(@"Error reading from socket!");
        close(socket_fd);
        return 1;
    }
    close(socket_fd);
    return 0;
}

- (BOOL)isCurrent;
{
    if (![fileManager fileExistsAtPath:@kSocketPath])		return NO;
    if (![fileManager fileExistsAtPath:@kHelperPlistPath])	return NO;
    if (![fileManager fileExistsAtPath:@kHelperToolPath])	return NO;
    
    struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Version)
    if (sendMessage(&messageOut, &messageIn)) {
        return NO;
    }
    return messageIn.command == kHelperMessageVersion
    &&  messageIn.data.bytes[0] == kVersionPart1
    &&  messageIn.data.bytes[1] == kVersionPart2
    &&  messageIn.data.bytes[2] == kVersionPart3;
}

- (void)remove;
{
	struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Remove)
    if (sendMessage(&messageOut, &messageIn)) {
		AppError(@"Error sending message to remove helper!");
	}
	if (messageIn.data.i) {
		// see usr/include/sys/errno.h for errors, such as
		// ENOENT		2		/* No such file or directory */
		AppError(@"Helper remove attempt got errno = %i", messageIn.data.i);
	}
}

@end
