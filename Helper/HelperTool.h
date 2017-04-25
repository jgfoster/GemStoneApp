//
//  HelperTool.h
//  GemStone
//
//  Created by James Foster on 1/17/17.
//  Copyright © 2017 GemTalk Systems LLC. All rights reserved.
//

#ifndef HelperTool_h
#define HelperTool_h

#define kHelperPlistPath  "/Library/LaunchDaemons/com.GemTalk.GemStone.Helper.plist"
#define kHelperToolPath   "/Library/PrivilegedHelperTools/com.GemTalk.GemStone.Helper"
#define kHelperIdentifier "com.GemTalk.GemStone.Helper"

#define kShortVersionString "1.4.2"

typedef enum {
    GS_HELPER_STATUS = 0,
    GS_HELPER_REMOVE,
	GS_HELPER_MEMORY,
	GS_HELPER_SYSTEM,
    
} gs_helper_t;

#endif /* HelperTool_h */
