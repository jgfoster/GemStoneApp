//
//  GemStone_HelperXPC.m
//  GemStone.HelperXPC
//
//  Created by James Foster on 1/15/17.
//  Copyright © 2017 GemTalk Systems LLC. All rights reserved.
//

#import "GemStone_HelperXPC.h"

@implementation GemStone_HelperXPC

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
