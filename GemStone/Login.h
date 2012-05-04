//
//  Login.h
//  GemStone
//
//  Created by James Foster on 5/1/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Login : NSObject {
	NSString	*name;
	NSString	*version;
	NSString	*stoneHost;
	NSString	*stoneName;
	BOOL		isRpcGem;
	NSString	*gemHost;
	NSString	*gemNet;
	NSString	*gemTask;
	BOOL		isGuest;
	NSString	*osUser;
	NSString	*osPwd;
	NSString	*gsUser;
	NSString	*gsPwd;
	NSString	*developer;
}

@property (readwrite,retain)	NSString	*name;
@property (readwrite,retain)	NSString	*version;
@property (readwrite,retain)	NSString	*stoneHost;
@property (readwrite,retain)	NSString	*stoneName;
@property (readwrite,assign)	BOOL		isRpcGem;
@property (readwrite,retain)	NSString	*gemHost;
@property (readwrite,retain)	NSString	*gemNet;
@property (readwrite,retain)	NSString	*gemTask;
@property (readwrite,assign)	BOOL		isGuest;
@property (readwrite,retain)	NSString	*osUser;
@property (readwrite,retain)	NSString	*osPwd;
@property (readwrite,retain)	NSString	*gsUser;
@property (readwrite,retain)	NSString	*gsPwd;
@property (readwrite,retain)	NSString	*developer;

@end
