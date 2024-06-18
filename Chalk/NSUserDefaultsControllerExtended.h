//
//  NSUserDefaultsControllerExtended.h
// Chalk
//
//  Created by Pierre Chatelier on 26/04/09.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSUserDefaultsController (Extended)

+(NSString*) adaptedKeyPath:(NSString*)keyPath;
-(NSString*) adaptedKeyPath:(NSString*)keyPath;

@end
