//
//  DownloadHeader.h
//  GemStone
//
//  Created by James Foster on 12/3/20.
//  Copyright © 2020 GemTalk Systems LLC. All rights reserved.
//

#import "Download.h"

@interface DownloadHeader : Download { }

@property	NSInteger	contentLength;
@property	NSInteger	resultCode;
@property	NSString	*url;

@end
