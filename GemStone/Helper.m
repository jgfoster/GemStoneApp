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
		AppError(@"Failed to create AuthorizationRef, return code %i", status);
	}
	
	/* This does all the work of verifying the helper tool against the application
	 * and vice-versa. Once verification has passed, the embedded launchd.plist
	 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
	 * executable is placed in /Library/PrivilegedHelperTools.
	 */
	result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, &cfError);
	*error = (__bridge NSError*) cfError;
	return result;
}

- (void)ensureSharedMemoryMB:(NSNumber *)sizeMB;
{
	struct HelperMessage messageOut, messageIn;
	unsigned long	shmmaxNeeded = [sizeMB unsignedLongValue];
					shmmaxNeeded = shmmaxNeeded * 1024 * 1126;	//	add 10% for non-page data structures;
	//	allow use of max available memory
	shmmaxNeeded = [[NSProcessInfo processInfo] physicalMemory];
	unsigned long	shmallNeeded = (shmmaxNeeded + 4095) / 4096;
	unsigned long	shmallNow = 0;
	unsigned long	shmmaxNow = 0;
	size_t			mySize = sizeof(NSUInteger);
	int				result;
	result = sysctlbyname("kern.sysv.shmall", &shmallNow, &mySize, NULL, 0);
	if (shmallNow < shmallNeeded ) {
		if (![self isCurrent]) {
			[self install];
			[appController updateHelperToolStatus];
		}
		initMessage(messageOut, Helper_shmall);
		messageOut.data.ul = shmallNeeded;
		messageOut.dataSize = sizeof(messageOut.data.ul);
		if (sendMessage(&messageOut, &messageIn)) {
			NSLog(@"Error sending message to set shmall");
		}
		if (messageIn.data.i) {
			NSLog(@"sysctlbyname() returned errno %i", messageIn.data.i);
		}
	}
	result = sysctlbyname("kern.sysv.shmmax", &shmmaxNow, &mySize, NULL, 0);
	if (shmmaxNow < shmmaxNeeded) {
		if (![self isCurrent]) {
			[self install];
			[appController updateHelperToolStatus];
		}
		initMessage(messageOut, Helper_shmmax);
		messageOut.data.ul = shmmaxNeeded;
		messageOut.dataSize = sizeof(messageOut.data.ul);
		if (sendMessage(&messageOut, &messageIn)) {
			NSLog(@"Error sending message to set shmmax");
		}
		if (messageIn.data.i) {
			NSLog(@"sysctlbyname() returned errno %i", messageIn.data.i);
		}
	}
}

- (void)install;
{
	NSError *error = nil;
	if (![self blessHelperWithLabel:@kHelperIdentifier error:&error]) {
		AppError(@"Helper tool installation failed: %@", [error localizedDescription]);
	}
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
