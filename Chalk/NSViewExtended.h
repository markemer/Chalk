//
//  NSViewExtended.h
// Chalk
//
//  Created by Pierre Chatelier on 22/12/12.
//  Copyright (c) 2012 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* NSTagBinding;

@interface NSView (Extended)

-(void) centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically;
-(void) centerChild:(NSView*)child horizontally:(BOOL)horizontally vertically:(BOOL)vertically;
-(void) centerChildren:(NSArray*)children horizontally:(BOOL)horizontally vertically:(BOOL)vertically;
-(void) centerRelativelyTo:(NSView*)other horizontally:(BOOL)horizontally vertically:(BOOL)vertically;

-(NSView*) findSubviewOfClass:(Class)class;
-(NSView*) findSubviewOfClass:(Class)class andTag:(NSInteger)tag;

@end
