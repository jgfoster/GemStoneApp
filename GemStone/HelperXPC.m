 //
//  HelperXPC.m
//  GemStone
//
//  Created by James Foster on 15-Jan-2017.
//  Copyright (c) 2017 GemTalk Systems LLC. All rights reserved.
//

#import "HelperXPC.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#import "Utilities.h"

#define kHelperPlistPath  "/Library/LaunchDaemons/com.GemTalk.GemStoneHelper.plist"
#define kHelperToolPath   "/Library/PrivilegedHelperTools/com.GemTalk.GemStoneHelper"
#define kHelperIdentifier "com.GemTalk.GemStoneHelper"

@implementation HelperXPC

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

//	allow use of max available memory
- (void)ensureSharedMemory;
{
/*
    struct HelperMessage messageOut, messageIn;
	unsigned long	shmmaxNeeded = [[NSProcessInfo processInfo] physicalMemory];
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
		if (sendMessageXPC(&messageOut, &messageIn)) {
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
		if (sendMessageXPC(&messageOut, &messageIn)) {
			NSLog(@"Error sending message to set shmmax");
		}
		if (messageIn.data.i) {
			NSLog(@"sysctlbyname() returned errno %i", messageIn.data.i);
		}
	}
 */
}

- (void)install;
{
	NSError *error = nil;
	if (![self blessHelperWithLabel:@kHelperIdentifier error:&error]) {
		AppError(@"HelperXPC tool installation failed: %@", [error localizedDescription]);
	}
}

- (BOOL)isCurrent;
{
    if (![fileManager fileExistsAtPath:@kHelperPlistPath])
        return NO;
    if (![fileManager fileExistsAtPath:@kHelperToolPath])
        return NO;

    if (TRUE) return false;
/*
	struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Version)
    if (sendMessageXPC(&messageOut, &messageIn)) {
		return NO;
	}
    return messageIn.command == kHelperMessageVersion
		&&  messageIn.data.bytes[0] == kVersionPart1
		&&  messageIn.data.bytes[1] == kVersionPart2
		&&  messageIn.data.bytes[2] == kVersionPart3;
 */
}

// returns 0 for success, 1 for error
/*
int sendMessageXPC(const struct HelperMessage * messageOut, struct HelperMessage * messageIn)
{
    AppError(@"Not yet implemented!");
    return 0;
}
 */

- (void)remove;
{
/*
	struct HelperMessage messageOut, messageIn;
    initMessage(messageOut, Helper_Remove)
    if (sendMessageXPC(&messageOut, &messageIn)) {
		AppError(@"Error sending message to remove helper!");
	}
	if (messageIn.data.i) {
		// see usr/include/sys/errno.h for errors, such as
		// ENOENT		2		// No such file or directory
		AppError(@"Helper remove attempt got errno = %i", messageIn.data.i);
	}
 */
}

@end
