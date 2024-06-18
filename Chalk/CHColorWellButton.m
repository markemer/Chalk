//
//  CHColorWellButton.m
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHColorWellButton.h"

#import "CHColorWell.h"

#import "NSObjectExtended.h"

@implementation CHColorWellButton

@synthesize associatedColorWell;
@synthesize delegate;

-(instancetype) initWithCoder:(NSCoder*)coder
{
  id result = [super initWithCoder:coder];
  self.target = self;
  self.action = @selector(click:);
  return result;
}
//end initWithCoder:

-(IBAction) click:(id)sender
{
  [self.window makeFirstResponder:self];
  [[NSApplication sharedApplication] orderFrontColorPanel:nil];
  NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
  CHColorWell* chColorWell = [self.associatedColorWell dynamicCastToClass:[CHColorWell class]];
  colorPanel.showsAlpha = !chColorWell || chColorWell.allowAlpha;
  colorPanel.color = self.associatedColorWell.color;
}
//end click:

-(void) changeColor:(id)sender
{
  [self.associatedColorWell setColor:[[NSColorPanel sharedColorPanel] color]];
  [self.associatedColorWell propagateValue:self.associatedColorWell.color forBinding:NSValueBinding];
  [self.delegate changeColor:self];
}
//end changeColor:


@end
