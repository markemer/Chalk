//  NSArrayExtended.h
//  Chalk
//  Created by Pierre Chatelier on 4/05/05.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.

// This file is an extension of the NSArray class

#import <Cocoa/Cocoa.h>

@interface NSArray (Extended)

-(id) firstObject;
-(BOOL) containsObjectIdenticalTo:(id)object;
-(NSArray*) reversedArray;
-(NSString*) componentsJoinedByString:(NSString*)separator allowEmpty:(BOOL)allowEmpty;
-(NSArray*) arrayByRemovingDuplicates;

@end
