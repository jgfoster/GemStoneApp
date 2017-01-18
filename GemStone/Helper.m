 //
//  Helper.m
//  GemStone
//
//  Created by James Foster on 15-Jan-2017.
//  Copyright (c) 2017 GemTalk Systems LLC. All rights reserved.
//

#import "Helper.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#import "Utilities.h"
#import "../Helper/HelperTool.h"

@implementation Helper

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

- (id)init;
{
    if (self = [super init]) {
        [self xpcInit];
        [self verifyVersionString];
    }
    return self;
}

- (void)install;
{
    AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRef authRef		= NULL;
    AuthorizationRights authRights	= { 1, &authItem };
    AuthorizationFlags flags		=
        kAuthorizationFlagDefaults				|
        kAuthorizationFlagInteractionAllowed	|
        kAuthorizationFlagPreAuthorize			|
        kAuthorizationFlagExtendRights;
    
    /* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status == errAuthorizationCanceled) return;
    if (status != errAuthorizationSuccess ) AppError(@"Failed to create AuthorizationRef, return code %i", status);
    
    /* This does all the work of verifying the helper tool against the application
     * and vice-versa. Once verification has passed, the embedded launchd.plist
     * is extracted and placed in /Library/LaunchDaemons and then loaded. The
     * executable is placed in /Library/PrivilegedHelperTools.
     */
    CFErrorRef cfError;
    if (SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)@kHelperIdentifier, authRef, &cfError)) {
        NSLog(@"Completed installation of helper tool.");
        [self xpcInit];
    } else {
        AppError(@"Helper tool installation failed: %@", [(__bridge NSError*) cfError localizedDescription]);
    }
}

- (BOOL)isCurrent;
{
    

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

- (void)terminate;
{
    xpc_connection_cancel(connection);
    connection = nil;
    
}

- (void)verifyVersionString;
{
    NSString *versionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    if ([versionString isEqualToString:@kShortVersionString]) return;
    [NSApp performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
    AppError(@"CFBundleShortVersionString (%@) does not match kShortVersionString (%s)", versionString, kShortVersionString);
}

- (void)xpcEvent:(xpc_object_t)event;
{
    if (!connection) return;
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR) return [self xpcEventError:event];
    if (type == XPC_TYPE_DICTIONARY) return [self xpcEventDictionary:event];
    NSLog(@"Unexpected XPC event.");
}

- (void)xpcEventDictionary:(xpc_object_t)dictionary;
{
    const char *version = xpc_dictionary_get_string(dictionary, "version");
    unsigned long pid = xpc_dictionary_get_uint64(dictionary, "pid");
    NSLog(@"helper pid = %lu, version = %s", pid, version);
}

- (void)xpcEventError:(xpc_object_t)error;
{
    
    if (error == XPC_ERROR_CONNECTION_INTERRUPTED) {
        NSLog(@"XPC connection interupted.");
        
    } else if (error == XPC_ERROR_CONNECTION_INVALID) {
        NSLog(@"XPC connection invalid, releasing.");
        connection = nil;
        [appController updateHelperToolStatus];
        
    } else {
        NSLog(@"Unexpected XPC error.");
    }
}

- (void)xpcInit;
{
    xpc_connection_t myConnection;
    myConnection = xpc_connection_create_mach_service(
                                                    kHelperIdentifier,
                                                    NULL,
                                                    XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    if (!myConnection) {
        AppError(@"Failed to create XPC connection.");
    }
    connection = myConnection;
    xpc_connection_set_event_handler(myConnection, ^(xpc_object_t event) { [self xpcEvent:event]; });
    xpc_connection_resume(myConnection);
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(message, "request", GS_HELPER_STATUS);
    xpc_connection_send_message_with_reply(myConnection,
                                           message,
                                           dispatch_get_main_queue(),
                                           ^(xpc_object_t event) { [self xpcEvent:event]; });
}

@end
