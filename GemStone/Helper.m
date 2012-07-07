//
//  Helper.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Helper.h"
#import "../Gemstone.Helper/Utilities.h"
#include <sys/socket.h>
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#define MAX_PATH_SIZE 128

@implementation Helper

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)error;
{
	BOOL result = NO;
    
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRef authRef		= NULL;
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	
		kAuthorizationFlagDefaults				| 
		kAuthorizationFlagInteractionAllowed	|
		kAuthorizationFlagPreAuthorize			|
		kAuthorizationFlagExtendRights;
	CFErrorRef cfError;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
	if (status != errAuthorizationSuccess) {
		NSLog(@"Failed to create AuthorizationRef, return code %i", status);
	} else {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &cfError);
		*error = (__bridge NSError*) cfError;
	}
	
	return result;
}

- (NSString *)install;
{
	NSError *error = nil;
	if (![self blessHelperWithLabel:@kHelperIdentifier error:&error]) {
		NSLog(@"Helper tool installation failed: %@", [error localizedDescription]);
		return [error localizedDescription];
	} else {
		NSLog(@"Helper tool installed!");
		return nil;
    }
}

- (BOOL)isCurrent;
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:@kSocketPath]) {
		return NO;	
	}
	struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Version)
    if (sendMessage(&messageOut, &messageIn)) {
		return NO;
	}
    return messageIn.command == kHelperMessageVersion
		&&  messageIn.data[0] == kVersionPart1
		&&  messageIn.data[1] == kVersionPart2
		&&  messageIn.data[2] == kVersionPart3;
}

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
    int written = write(socket_fd, messageOut, count);
    if (count != written) {
        NSLog(@"tried to write %i, but wrote %i", count, written);
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

- (NSString *)remove;
{
	struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Remove)
    if (sendMessage(&messageOut, &messageIn)) {
		return @"sendMessage failed!";
	}
	if (messageIn.command == Helper_Error) {
		return [NSString stringWithCString:(const char *)messageIn.data encoding:NSUTF8StringEncoding];
	}
	if (messageIn.command != Helper_Remove) {
		return @"unknown error";
	}
	int error;
	if (messageIn.dataSize != sizeof(error)) {
		return @"wrong size!";
	}
	memcpy(&error, messageIn.data, messageIn.dataSize);
	if (0 == error) {
		return nil;
	}
	// see usr/include/sys/errno.h for errors, such as 
	// ENOENT		2		/* No such file or directory */
	return [NSString stringWithFormat:@"errno = %i", error];
}

@end
