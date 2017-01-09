//
//  Utilities.h
//  GemStone
//
//  Created by James Foster on 4/18/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#ifndef GemStone_Utilities_h
#define GemStone_Utilities_h

#define kSocketPath       "/var/run/com.GemTalk.GemStone.socket"
#define kHelperPlistPath  "/Library/LaunchDaemons/com.GemTalk.GemStone.Helper.plist"
#define kHelperToolPath   "/Library/PrivilegedHelperTools/com.GemTalk.GemStone.Helper"
#define kHelperIdentifier "com.GemTalk.GemStone.Helper"

//	Also edit Info.plist Bundle Version
#define kVersionPart1 1
#define kVersionPart2 0
#define kVersionPart3 17

enum HelperCommand {
    Helper_Error    = 0,	// out data is a (null-terminated) C string
    Helper_Version  = 1,	// out data is three bytes (see above)
    Helper_PID      = 2,	// out data is a four-byte int with getpid()
	Helper_Remove	= 3,	// out data is a four-byte int with errno (0 if no problems)
	Helper_shmall	= 4,	// in  data is an eight-byte unsigned long (number of pages)
							// out data is a four-byte int with errno (0 if no problems)
	Helper_shmmax	= 5,	// in  data is an eight-byte unsigned long (number of bytes)
							// out data is a four-byte int with errno (0 if no problems)
};

// This needs to change if the following structure changes
#define kHelperMessageVersion 1

struct HelperMessage {
    unsigned char version;      // kMessageVersion
    unsigned char command;      // HelperCommand
    unsigned char dataSize;     // 0 to 255
	unsigned char padding[5];	// so that union can begin on an eight-byte boundary
	union {
		int				i;
		unsigned long	ul;
		unsigned char	bytes[255];    // command-specific data
	} data;
};

#define messageSize(message_p) sizeof(*message_p) - sizeof((message_p)->data) + (message_p)->dataSize
#define initMessage(m, c) { m.version = kHelperMessageVersion; m.command = c; m.dataSize = 0; }

int readMessage(int fd, struct HelperMessage * message);


#endif
