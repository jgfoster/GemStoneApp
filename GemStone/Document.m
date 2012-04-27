//
//  Document.m
//  GemStone
//
//  Created by James Foster on 4/19/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Document.h"
#import "Versions.h"
#import "Version.h"

@implementation Document

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (IBAction)login:(id)sender;
{
	NSLog(@"login:");
}

- (IBAction)setGemType:(id)sender;
{
	NSString *identifier = [[gemTypeMatrix selectedCell] identifier];
	BOOL hidden = [identifier compare:@"linkedGem"] == NSOrderedSame;
	[gemHostLabel setHidden:hidden];
	[gemHostEntry setHidden:hidden];
	[gemNetLabel  setHidden:hidden];
	[gemNetEntry  setHidden:hidden];
	[gemTaskLabel setHidden:hidden];
	[gemTaskEntry setHidden:hidden];
}

- (IBAction)setOsType:(id)sender;
{
	NSString *identifier = [[osTypeMatrix selectedCell] identifier];
	BOOL hidden = [identifier compare:@"osGuest"] == NSOrderedSame;
	[osUserLabel setHidden:hidden];
	[osUserEntry setHidden:hidden];
	[osPwdLabel  setHidden:hidden];
	[osPwdEntry  setHidden:hidden];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	[self setGemType:self];
	[self setOsType:self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification;
{
	NSArray *versions = [[[NSApp delegate] versions] installedVersions];
	NSMutableArray *versionNames = [NSMutableArray arrayWithCapacity:[versions count]];
	for (Version *version in versions) {
		[versionNames addObject:version.version];
	}
	NSString *selection = [versionList titleOfSelectedItem];
	[versionList removeAllItems];
	[versionList addItemsWithTitles:versionNames];
	[versionList selectItemWithTitle:selection];
	[versionList synchronizeTitleAndSelectedItem];
}

- (void)startTopaz;
{
    NSData* data;
    NSString* string;
    NSTask *task = [NSTask new];
    NSDictionary * environment = [[NSProcessInfo processInfo] environment];
    [environment setValue:@"/opt/gemstone/product" forKey:@"GEMSTONE"];
    [task setEnvironment: environment];
//  NSArray	*arguments = [NSArray arrayWithObjects:@"-l", @"-T50000", nil];
//  [task setArguments:arguments];
    [task setStandardInput: [NSPipe pipe]];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError: [NSPipe pipe]];
    NSFileHandle *taskIn  = [[task standardInput]  fileHandleForWriting];
    NSFileHandle *taskOut = [[task standardOutput] fileHandleForReading];
    NSFileHandle *taskErr = [[task standardError]  fileHandleForReading];
    [task setLaunchPath:@"/opt/gemstone/product/bin/topaz"];
    [task launch];
    sleep(1);
    data = [taskOut availableData];
    string = [[NSString alloc] 
              initWithData:data 
              encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
/*
    data = [taskErr availableData];
    NSLog(@"responseData length = %lu", [data length]);
    string = [[NSString alloc] 
                                initWithData:data 
                                encoding:NSUTF8StringEncoding];
    NSLog(@"errOut = %@", string);
*/ 
    string = @"set user DataCurator pass swordfish gems jfoster0\n";
    data = [NSData 
             dataWithBytes:[string cStringUsingEncoding: NSUTF8StringEncoding] 
             length:[string length]];
    [taskIn writeData:data];
    sleep(1);
    data = [taskOut availableData];
    string = [[NSString alloc] 
              initWithData:data 
              encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);

    string = @"status\n";
    data = [NSData 
            dataWithBytes:[string cStringUsingEncoding: NSUTF8StringEncoding] 
            length:[string length]];
    [taskIn writeData:data];
    sleep(1);
    data = [taskOut availableData];
    string = [[NSString alloc] 
              initWithData:data 
              encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    @try {
        int code = [task terminationStatus];
        NSLog(@"terminationStatus = %i", code);
    } @catch (NSException *exception) {
        NSLog(@"exception: %@", exception);
    }
    string = @"exit\n";
    data = [NSData 
            dataWithBytes:[string cStringUsingEncoding: NSUTF8StringEncoding] 
            length:[string length]];
    [taskIn writeData:data];
    sleep(1);
    data = [taskOut availableData];
    string = [[NSString alloc] 
              initWithData:data 
              encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    
    [taskIn  closeFile];
    [taskOut closeFile];
    [taskErr closeFile];
    int code = [task terminationStatus];
    NSLog(@"terminationStatus = %i", code);
    [task terminate];
}

@end
