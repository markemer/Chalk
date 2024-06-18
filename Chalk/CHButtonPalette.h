//
//  CHButtonPalette.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CHButtonPalette : NSObject {
  NSMutableArray* buttons;
  BOOL isExclusive;
  id delegate;
}

@property(nonatomic) NSInteger selectedTag;

-(BOOL) isExclusive;
-(void) setExclusive:(BOOL)value;
-(void) add:(NSButton*)button;
-(void) remove:(NSButton*)button;
-(NSButton*) buttonWithTag:(int)tag;
-(NSButton*) buttonWithState:(int)state;

-(id) delegate;
-(void) setDelegate:(id)delegate;
-(void) buttonPalette:(CHButtonPalette*)buttonPalette buttonStateChanged:(NSButton*)button;

@end
