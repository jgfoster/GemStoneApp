//
//  main.c
//  Helper
//
//  Created by James Foster on 4/18/12.
//  Copyright (c) 2012-2017 GemTalk Systems LLC. All rights reserved.
//
//  Based on https://github.com/atnan/SMJobBlessXPC/blob/master/SMJobBlessHelper/SMJobBlessHelper.c
//

#include <syslog.h>
#include <xpc/xpc.h>

#import "HelperTool.h"

/*
 
 
int respondToRequests() {
    int listener_fd = get_listener_fd();
    if (listener_fd == -1) return 1;
    int connection_fd;
    while (0 <= (connection_fd = get_connection_fd(listener_fd))) {
        struct HelperMessage messageIn, messageOut;
        if (readMessage(connection_fd, &messageIn)) break;
        initMessage(messageOut, messageIn.command);
        switch (messageIn.command) {
            case Helper_Version:
				messageOut.dataSize = 3;
                messageOut.data.bytes[0] = kVersionPart1;
                messageOut.data.bytes[1] = kVersionPart2;
                messageOut.data.bytes[2] = kVersionPart3;
                break;
                
			//	answer our PID as a demo of things we can do and to allow debugging
            case Helper_PID: {
                messageOut.data.i = getpid();
				messageOut.dataSize = sizeof(messageOut.data.i);
                break;
            }
			case Helper_Remove: {
				int error = unlink(kHelperPlistPath); 
				if (0 == error) {
					error = unlink(kHelperToolPath);
				}
				messageOut.data.i = error;
				messageOut.dataSize = sizeof(messageOut.data.i);
				break;
			}
			case Helper_shmall: {
				unsigned long	shmall = messageIn.data.ul;
				int				result = sysctlbyname("kern.sysv.shmall", NULL, 0, &shmall, sizeof(shmall));
				syslog(LOG_NOTICE, "shmall returned %i (errno = %i) when set to %lu", result, errno, shmall);
				messageOut.data.i = result ? errno : 0;
				messageOut.dataSize = sizeof(messageOut.data.i);
				break;
			}
			case Helper_shmmax: {
				unsigned long	shmmax = (unsigned long)messageIn.data.ul;
				int				result = sysctlbyname("kern.sysv.shmmax", NULL, 0, &shmmax, sizeof(shmmax));
				syslog(LOG_NOTICE, "shmmax returned %i (errno = %i) when set to %lu", result, errno, shmmax);
				messageOut.data.i = result ? errno : 0;
				messageOut.dataSize = sizeof(messageOut.data.i);
				break;
			}
            default:
                syslog(LOG_NOTICE, "Unknown command: %hhd\n", messageIn.command);
                char *message = "Unknown command!";
                messageOut.command = Helper_Error;
                messageOut.dataSize = strlen(message) + 1;    // add trailing \0
                strcpy((char *) messageOut.data.bytes, message);
                break;
        }
        int count = messageSize(&messageOut);
        long written = write(connection_fd, &messageOut, count);
        if (written != count) {
            syslog(LOG_NOTICE, "tried to write %i, but wrote %li", count, written);
            break;
        }
		syslog(LOG_NOTICE, "wrote %i", count);
        close(connection_fd);
    }
    close(listener_fd);
    if (0 < connection_fd) close(connection_fd);
	return connection_fd == -1 ? 0 : 1;
}
 */

static void xpcEventDictionary(xpc_connection_t connection, xpc_object_t dictionary) {
    syslog(LOG_NOTICE, "Received dictionary (%lu) for connection (%lu)", (unsigned long) dictionary, (unsigned long) connection);

    enum gs_helper request = (int) xpc_dictionary_get_uint64(dictionary, "request");
    syslog(LOG_NOTICE, "request = %d", request);
    
    xpc_object_t reply = xpc_dictionary_create_reply(dictionary);
    xpc_dictionary_set_uint64(reply, "pid", (unsigned long) getpid());
    xpc_dictionary_set_string(reply, "version", kShortVersionString);

    const char *version = xpc_dictionary_get_string(reply, "version");
    unsigned long pid = xpc_dictionary_get_uint64(reply, "pid");
    syslog(LOG_NOTICE, "helper pid = %lu, version = %s", pid, version);

    xpc_connection_send_message(connection, reply);
    xpc_release(reply);
}

static void xpcEventError(xpc_connection_t connection, xpc_object_t error) {
    syslog(LOG_NOTICE, "Received error (%lu) for connection (%lu)", (unsigned long) error, (unsigned long) connection);

    if (error == XPC_ERROR_CONNECTION_INVALID) {
        // The client process on the other end of the connection has either
        // crashed or cancelled the connection. After receiving this error,
        // the connection is in an invalid state, and you do not need to
        // call xpc_connection_cancel(). Just tear down any associated state
        // here.
        
    } else if (error == XPC_ERROR_TERMINATION_IMMINENT) {
        // Handle per-connection termination cleanup.
    }
}

static void xpcEvent(xpc_connection_t connection, xpc_object_t event) {
    
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR) return xpcEventError(connection, event);
    if (type == XPC_TYPE_DICTIONARY) return xpcEventDictionary(connection, event);
    syslog(LOG_NOTICE,
           "Received unknown event (%lu) type (%lu) for connection (%lu)",
           (unsigned long) event, (unsigned long) type, (unsigned long) connection);
}

static void xpcConnection(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring event handler for connection (%lu)", (unsigned long)connection);
    xpc_connection_set_event_handler(connection,
                                     ^(xpc_object_t event) {xpcEvent(connection, event);} );
    xpc_connection_resume(connection);
}

int main(int argc, const char * argv[]) {
    syslog(LOG_NOTICE, "main(): uid = %d, euid = %d, pid = %d", getuid(), geteuid(), getpid());

    xpc_connection_t service = xpc_connection_create_mach_service(kHelperIdentifier,
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
    syslog(LOG_NOTICE, "Configuring event handler for service (%lu)", (unsigned long)service);
    xpc_connection_set_event_handler(service,
                                     ^(xpc_object_t connection) {xpcConnection(connection);} );
    xpc_connection_resume(service);
    dispatch_main();        // never returns!
}
