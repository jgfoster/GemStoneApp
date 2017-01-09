//
//  Utilties.c
//  GemStone
//
//  Created by James Foster on 4/18/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#include "Utilities.h"
#include <errno.h>
#include <poll.h>
#include <syslog.h>
#include <unistd.h>

/*
 return 0 for success, 1 for failure
 */
int readBytes(int size, int fd, unsigned char * buffer) {
    int left = size;
    unsigned char *pointer = buffer;
    struct pollfd fds;
    fds.fd = fd;
    fds.events = POLLIN;
    
    while (0 < left) {
        int readyCount = poll(&fds, 1, 5000);  // wait for data
        if (readyCount == -1) {
            syslog(LOG_NOTICE, "poll() error = %d\n", errno);
            return 1;
        }
        if (readyCount == 0) {
            syslog(LOG_NOTICE, "no bytes available on socket!");
            return 1;
        }
        long numberRead = read(fd, pointer, left);
        if (numberRead == 0) {
            syslog(LOG_NOTICE, "poll() said that data was available but we didn't get any!");
            return 1;
        }
        left -= numberRead;
        pointer += numberRead;
    }
    return 0;
}

int readMessage(int fd, struct HelperMessage *message) {
    if (readBytes(1, fd, &(message->version))) return 1;
    if (message->version != kHelperMessageVersion) {
        syslog(LOG_NOTICE, "expected message format version %i but got %i", kHelperMessageVersion, message->version);
        return 1;
    }
    if (readBytes(1, fd, &(message->command))) return 1;
    if (readBytes(1, fd, &(message->dataSize))) return 1;
	if (readBytes(sizeof(message->padding), fd, message->padding)) return 1;
    return readBytes(message->dataSize, fd, message->data.bytes);
}



