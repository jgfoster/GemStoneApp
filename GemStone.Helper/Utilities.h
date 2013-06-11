//
//  Utilities.h
//  GemStone
//
//  Created by James Foster on 4/18/12.
//  Copyright (c) 2012 VMware. All rights reserved.
//

#ifndef GemStone_Utilities_h
#define GemStone_Utilities_h

#define kSocketPath "/var/run/com.VMware.GemStone.socket"
#define kHelperIdentifier "com.VMware.GemStone.Helper"

//	Also edit Info.plist Bundle Version
#define kVersionPart1 1
#define kVersionPart2 0
#define kVersionPart3 9

enum HelperCommand {
    Helper_Error    = 0,	// data is a (null-terminated) C string
    Helper_Version  = 1,	// data is three bytes (see above)
    Helper_PID      = 2,	// data is a four-byte int with getpid()
	Helper_Remove	= 3,	// data is a four-byte int with errno (0 if no problems)
	Helper_shmall	= 4,	// data is an eight-byte unsigned long (number of pages)
	Helper_shmmax	= 5,	// data is an eight-byte unsigned long (number of bytes)
};

// This needs to change if the following structure changes
#define kHelperMessageVersion 1

struct HelperMessage {
    unsigned char version;      // kMessageVersion
    unsigned char command;      // SMJobBlessCommand
    unsigned char dataSize;     // 0 to 252
    unsigned char data[252];    // command-specific data
};

#define messageSize(message_p) sizeof(*message_p) - sizeof((message_p)->data) + (message_p)->dataSize
#define initMessage(m, c) { m.version = kHelperMessageVersion; m.command = c; m.dataSize = 0; }

int readMessage(int fd, struct HelperMessage * message);


#endif
