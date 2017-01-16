//
//  GemStone_HelperXPC.h
//  GemStone.HelperXPC
//
//  Created by James Foster on 1/15/17.
//  Copyright © 2017 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GemStone_HelperXPCProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface GemStone_HelperXPC : NSObject <GemStone_HelperXPCProtocol>
@end
