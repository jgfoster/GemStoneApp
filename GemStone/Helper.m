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
#include <sys/sysctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

#import "Utilities.h"
#import "../Helper/HelperTool.h"

@implementation Helper


- (void)checkDNS;
{
	const char *hostname = [[self hostName] UTF8String];
	struct addrinfo hints;
	struct addrinfo *list = nil;
	memset((void *) &hints, 0, sizeof(hints));
	hints.ai_flags = AI_ADDRCONFIG | AI_CANONNAME;
	hints.ai_family = PF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	int result = getaddrinfo(hostname, nil, &hints, &list);
	if (result) {
		NSLog(@"getaddrinfo returned %i", result);
		_ipAddress = nil;
	} else {
		struct sockaddr_in *addr;
		addr = (struct sockaddr_in *)list->ai_addr;
		const char *address =inet_ntoa((struct in_addr)addr->sin_addr);
		_ipAddress = [NSString stringWithCString:address encoding:NSASCIIStringEncoding];
		NSLog(@"inet_ntoa() returned %@",_ipAddress);
	}
	freeaddrinfo(list);
}

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

- (NSString*) hostName;
{
	return [self systemInfoString:"kern.hostname"];
}

- (id)init;
{
    if (self = [super init]) {
        [self verifyVersionString];
		_ipAddress = nil;
        _isAvailable = NO;
		[self performSelectorInBackground:@selector(checkDNS) withObject:nil];
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

- (NSString *)shmall;
{
	unsigned long	current = 0;
	size_t			mySize = sizeof(NSUInteger);
	int				result;
	result = sysctlbyname("kern.sysv.shmall", &current, &mySize, NULL, 0);
	return [self shmString:current * 4096];
}

- (NSString *)shmmax;
{
	unsigned long	current = 0;
	size_t			mySize = sizeof(NSUInteger);
	int				result;
	result = sysctlbyname("kern.sysv.shmmax", &current, &mySize, NULL, 0);
	return [self shmString:current];
}

- (NSString *)shmString:(unsigned long)current;
{
	if (!(current & 0x3FFFFFFF)) {
		return [NSString stringWithFormat:@"%lu GB", current / 0x3FFFFFFF];
	} else if (!(current & 0xFFFFF)) {
		return [NSString stringWithFormat:@"%lu MB", current / 0xFFFFF];
	} else if (!(current & 0x3FF)) {
		return [NSString stringWithFormat:@"%lu KB", current / 0x3FF];
	}
	return [NSString stringWithFormat:@"%lu bytes", current];;
}

- (NSString*) systemInfoString:(const char*)attributeName
{
	size_t size;
	sysctlbyname(attributeName, NULL, &size, NULL, 0); // Get the size of the data.
	char* attributeValue = malloc(size);
	int err = sysctlbyname(attributeName, attributeValue, &size, NULL, 0);
	if (err != 0) {
		NSLog(@"sysctlbyname(%s) failed: %s", attributeName, strerror(errno));
		free(attributeValue);
		return nil;
	}
	NSString* vs = [NSString stringWithUTF8String:attributeValue];
	free(attributeValue);
	return vs;
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
