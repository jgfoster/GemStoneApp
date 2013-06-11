//
//  UnzipVersion.h
//  GemStone
//
//  Created by James Foster on 9/19/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Download.h"

@interface UnzipVersion : Task <NSOpenSavePanelDelegate> {
	NSString	*zipFilePath;
	NSArray		*directoryContents;
}

@property (nonatomic, readwrite, retain) NSString *zipFilePath;

- (void)unzip;

@end
