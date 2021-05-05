//
//  NSWorkspaceExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/07/05.
//  Copyright 2005-2014 Pierre Chatelier. All rights reserved.
//

//this file is an extension of the NSWorkspace class

#import <Cocoa/Cocoa.h>

@interface NSWorkspace (Extended)

-(NSString*) applicationName;
-(NSString*) applicationVersion;
-(NSString*) applicationBundleIdentifier;
-(NSString*) temporaryDirectory;
-(NSString*) getBestStandardPath:(NSSearchPathDirectory)searchPathDirectory domain:(NSSearchPathDomainMask)domain defaultValue:(NSString*)defaultValue;
-(NSURL*)    getBestStandardURL:(NSSearchPathDirectory)searchPathDirectory domain:(NSSearchPathDomainMask)domain defaultValue:(NSURL*)defaultValue;
@end
