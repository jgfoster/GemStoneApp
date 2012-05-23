//
//  DownloadVersion.h
//  GemStone
//
//  Created by James Foster on 5/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Download.h"
#import "Version.h"

@interface DownloadVersion : Download {
	Version			*version;
	NSString		*zipFilePath;
	NSFileHandle	*zipFile;
}

@property (nonatomic, retain)	Version		*version;
@property (readonly)			NSString	*zipFilePath;

@end
