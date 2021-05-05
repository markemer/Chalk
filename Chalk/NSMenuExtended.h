//
//  NSMenuExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 04/05/2017.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMenu (Extended)

-(NSMenuItem*) addItemWithTitle:(NSString*)title tag:(NSInteger)tag action:(SEL)action target:(id)target;
-(NSMenuItem*) addItemWithTitle:(NSString*)aString target:(id)target action:(SEL)aSelector
                  keyEquivalent:(NSString*)keyEquivalent  keyEquivalentModifierMask:(int)keyEquivalentModifierMask
                  tag:(int)tag;

@end
