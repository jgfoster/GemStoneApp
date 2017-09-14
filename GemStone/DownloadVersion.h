//
//  DownloadVersion.h
//  GemStone
//
//  Created by James Foster on 5/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Download.h"
#import "Version.h"

@interface DownloadVersion : Download { }

@property				Version		*version;
@property (readonly)	NSString	*zipFilePath;

@end
