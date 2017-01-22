//
//  main.c
//  Helper
//
//  Created by James Foster on 4/18/12.
//  Copyright (c) 2012-2017 GemTalk Systems LLC. All rights reserved.
//
//  Based on https://github.com/atnan/SMJobBlessXPC/blob/master/SMJobBlessHelper/SMJobBlessHelper.c
//

#include <errno.h>
#include <sys/sysctl.h>
#include <syslog.h>
#include <xpc/xpc.h>

#import "HelperTool.h"

static void xpcEventDictionary(xpc_connection_t connection, xpc_object_t dictionary) {
	const char *appVersion = xpc_dictionary_get_string(dictionary, "version");
	if (strncmp(appVersion, kShortVersionString, strlen(kShortVersionString))) {
		syslog(LOG_NOTICE, "Ignoring request from version '%s' (we are '%s').", appVersion, kShortVersionString);
		xpc_connection_cancel(connection);
		exit(EXIT_FAILURE);
	}
	int error = 0;
    gs_helper_t request = (int) xpc_dictionary_get_uint64(dictionary, "request");
	syslog(LOG_NOTICE, "Received request (%d) from appVersion (%s) in dictionary (%lu) for new connection (%lu)",
           request,
		   appVersion,
           (unsigned long) dictionary,
           (unsigned long) connection);
    xpc_object_t reply = xpc_dictionary_create_reply(dictionary);
	xpc_dictionary_set_uint64(reply, "pid", (unsigned long) getpid());
    xpc_dictionary_set_string(reply, "version", kShortVersionString);
    switch (request) {
		case GS_HELPER_MEMORY: {
			unsigned long shmall = xpc_dictionary_get_uint64(dictionary, "shmall");
			unsigned long shmmax = xpc_dictionary_get_uint64(dictionary, "shmmax");
			error = sysctlbyname("kern.sysv.shmall", NULL, 0, &shmall, sizeof(shmall));
			syslog(LOG_NOTICE, "shmall returned %i (errno = %i) when set to %lu", error, errno, shmall);
			if (!error) {
				error = sysctlbyname("kern.sysv.shmmax", NULL, 0, &shmmax, sizeof(shmmax));
				syslog(LOG_NOTICE, "shmmax returned %i (errno = %i) when set to %lu", error, errno, shmmax);
			}
			break;
		}
        case GS_HELPER_REMOVE:
            xpc_dictionary_set_value(reply, "version", NULL);
            error = unlink(kHelperPlistPath);
            if (0 == error) {
                error = unlink(kHelperToolPath);
            }
            break;

		case GS_HELPER_STATUS:	//	status information included for everyone
        default:
            break;
    }
    xpc_dictionary_set_int64(reply, "error", (long) error);
    xpc_connection_send_message(connection, reply);
    xpc_release(reply);
	if (request == GS_HELPER_REMOVE) {
		syslog(LOG_NOTICE, "Received request to remove helper tool.");
		xpc_connection_cancel(connection);
		exit(EXIT_SUCCESS);
	}
}

static void xpcEventError(xpc_connection_t connection, xpc_object_t error) {
    if (error == XPC_ERROR_CONNECTION_INVALID) {
		syslog(LOG_NOTICE, "XPC_ERROR_CONNECTION_INVALID for connection (%lu)", (unsigned long) connection);
    } else if (error == XPC_ERROR_TERMINATION_IMMINENT) {
		syslog(LOG_NOTICE, "XPC_ERROR_TERMINATION_IMMINENT for connection (%lu)", (unsigned long) connection);
    } else {
        syslog(LOG_NOTICE, "Received error (%lu) for connection (%lu)", (unsigned long) error, (unsigned long) connection);
    }
}

static void xpcEvent(xpc_connection_t connection, xpc_object_t event) {
    xpc_type_t type = xpc_get_type(event);
    if (type == XPC_TYPE_ERROR) return xpcEventError(connection, event);
    if (type == XPC_TYPE_DICTIONARY) return xpcEventDictionary(connection, event);
    syslog(LOG_NOTICE,
           "Received unknown event (%lu) of type (%lu) for connection (%lu)",
           (unsigned long) event, (unsigned long) type, (unsigned long) connection);
}

static void xpcConnection(xpc_connection_t connection)  {
	syslog(LOG_NOTICE, "New connection (%lu).", (unsigned long)connection);
    xpc_connection_set_event_handler(connection,
                                     ^(xpc_object_t event) {xpcEvent(connection, event);} );
    xpc_connection_resume(connection);
}

int main(int argc, const char * argv[]) {
    xpc_connection_t service = xpc_connection_create_mach_service(kHelperIdentifier,
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    if (!service) {
        syslog(LOG_ERR, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
	syslog(LOG_NOTICE, "Created service (%lu).", (unsigned long)service);
    xpc_connection_set_event_handler(service,
                                     ^(xpc_object_t connection) {xpcConnection(connection);} );
    xpc_connection_resume(service);
    dispatch_main();        // never returns!
}
