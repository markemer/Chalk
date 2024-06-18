//
//  NSFileManagerExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFileManager (Extended)

-(NSString*) localizedPath:(NSString*)path;

-(NSString*) UTIFromPath:(NSString*)path;
-(NSString*) getUnusedFilePathFromPrefix:(NSString*)filePrefix extension:(NSString*)extension folder:(NSString*)folder startSuffix:(NSUInteger)startSuffix;

@end
