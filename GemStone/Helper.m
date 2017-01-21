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
	unsigned long physicalMemory = [[NSProcessInfo processInfo] physicalMemory];
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	NSString *versionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
	xpc_dictionary_set_string(message, "version", [versionString cStringUsingEncoding:NSASCIIStringEncoding]);
	xpc_dictionary_set_uint64(message, "request", GS_HELPER_MEMORY);
	xpc_dictionary_set_uint64(message, "shmmax", physicalMemory);
	xpc_dictionary_set_uint64(message, "shmall", physicalMemory / 4096);
	xpc_connection_send_message_with_reply(connection,
										   message,
										   dispatch_get_main_queue(),
										   ^(xpc_object_t event) { [self xpcEvent:event]; });
	NSLog(@"Sent XPC request (%i) on connection (%lu).", GS_HELPER_MEMORY, (unsigned long) connection);
}

- (id)init;
{
    if (self = [super init]) {
        [self verifyVersionString];
        _isAvailable = NO;
        [self xpcInit];
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

- (void)remove;
{
    _isAvailable = NO;
    [self xpcRequest:GS_HELPER_REMOVE];
}

- (void)terminate;
{
    xpc_connection_cancel(connection);
    connection = nil;
    
}

- (void)updateSetupState;
{
	[appController performSelectorOnMainThread:@selector(updateSetupState) withObject:nil waitUntilDone:NO];
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
    xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		return [self xpcEventError:event];
	}
	if (type == XPC_TYPE_DICTIONARY) {
		return [self xpcEventDictionary:event];
	}
    NSLog(@"Unexpected XPC event.");
}

- (void)xpcEventDictionary:(xpc_object_t)dictionary;
{
//	NSLog(@"Got XPC dictionary (%lu) on connection (%lu).", (unsigned long)dictionary, (unsigned long) connection);
    NSString *bundleVersionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    const char *helperVersionString = xpc_dictionary_get_string(dictionary, "version");
    _isAvailable = helperVersionString && [bundleVersionString isEqualToString:@(helperVersionString)];
    [self updateSetupState];
}

- (void)xpcEventError:(xpc_object_t)error;
{
    if (error == XPC_ERROR_CONNECTION_INTERRUPTED) {
//      NSLog(@"XPC connection interupted.");
		
	} else if (error == XPC_ERROR_CONNECTION_INVALID) {
//		NSLog(@"XPC connection invalid, releasing.");
		connection = nil;
		_isAvailable = NO;
		[self updateSetupState];
		
	} else {
		NSLog(@"Unexpected XPC error (%lu).", (unsigned long) error);
	}
}

- (void)xpcInit;
{
    connection = xpc_connection_create_mach_service(kHelperIdentifier,
                                                    NULL,
                                                    XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    if (!connection) {
        AppError(@"Failed to create XPC connection.");
    }
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) { [self xpcEvent:event]; });
    xpc_connection_resume(connection);
    [self ensureSharedMemory];
	[self updateSetupState];		// if no helper tool, then we don't get a response to the request!
}

- (void)xpcRequest:(gs_helper_t) request;
{
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(message, "request", request);
	NSString *versionString = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
	xpc_dictionary_set_string(message, "version", [versionString cStringUsingEncoding:NSASCIIStringEncoding]);
    xpc_connection_send_message_with_reply(connection,
                                           message,
                                           dispatch_get_main_queue(),
                                           ^(xpc_object_t event) { [self xpcEvent:event]; });
	NSLog(@"Sent XPC request (%i) on connection (%lu).", request, (unsigned long) connection);
}

@end
