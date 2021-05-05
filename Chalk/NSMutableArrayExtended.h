//  NSMutableArrayExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 3/05/05.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.

//this file is an extension of the NSMutableArray class

#import <Cocoa/Cocoa.h>

@interface NSMutableArray (Extended)

-(void) safeAddObject:(id)object;
-(void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
-(void) reverse;

@end
