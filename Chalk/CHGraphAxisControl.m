//
//  CHGraphAxisControl.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHGraphAxisControl.h"

#import "CHColorWell.h"
#import "CHGraphUtils.h"
#import "CHStepper.h"
#import "NSObjectExtended.h"
#import "NSViewExtended.h"

NSString* CHAxisColorBinding = @"axisColor";

@implementation CHGraphAxisControl

@synthesize titleLabel;
@synthesize colorWell;
@synthesize colorWellButton;
@synthesize minLabel;
@synthesize minTextField;
@synthesize minStepper;
@synthesize maxLabel;
@synthesize maxTextField;
@synthesize maxStepper;
@synthesize centerButton;
@synthesize scaleTypeButton;
@synthesize scaleTypeBaseLabel;
@synthesize scaleTypeBaseTextField;
@synthesize scaleTypeBaseStepper;
@synthesize gridBox;
@synthesize gridMajorAutoCheckBox;
@synthesize gridMajorTextField;
@synthesize gridMajorStepper;
@synthesize gridMinorTextField;
@synthesize gridMinorStepper;

@dynamic axisTitle;
@dynamic axisColor;

+(void) initialize
{
  [self exposeBinding:CHAxisColorBinding];
}
//end initialize:

-(void) awakeFromNib
{
  self->colorWell.allowAlpha = YES;
  self->colorWellButton.delegate = self;
  self->centerButton.toolTip = NSLocalizedString(@"Center axe", @"");
  self->minLabel.stringValue = NSLocalizedString(@"Min", @"");
  self->maxLabel.stringValue = NSLocalizedString(@"Max", @"");
  [self->scaleTypeButton.menu itemWithTag:CHGRAPH_SCALE_LINEAR].title = NSLocalizedString(@"linear", @"");
  [self->scaleTypeButton.menu itemWithTag:CHGRAPH_SCALE_LOGARITHMIC].title = NSLocalizedString(@"logarithmic", @"");
  self->scaleTypeBaseLabel.stringValue = NSLocalizedString(@"Base log.", @"");
  self->gridBox.title = NSLocalizedString(@"Grid", @"");
  self->minStepper.controlSize = NSSmallControlSize;//NSMiniControlSize;
  self->maxStepper.controlSize = NSSmallControlSize;//NSMiniControlSize;
  self->scaleTypeBaseStepper.controlSize = NSSmallControlSize;//NSMiniControlSize;
  self->gridMajorStepper.controlSize = NSSmallControlSize;//NSMiniControlSize;
  self->gridMinorStepper.controlSize = NSSmallControlSize;//NSMiniControlSize;
  self.axisColor = [NSColor blackColor];
}
//end awakeFromNib

-(NSString*) axisTitle
{
  return [[self->titleLabel.stringValue copy] autorelease];
}
//end axisTitle

-(void) setAxisTitle:(NSString*)value
{
  self->titleLabel.stringValue = value;
  [self->titleLabel sizeToFit];
  [self->titleLabel centerInParentHorizontally:YES vertically:NO];
  NSRect frame1 = self->titleLabel.frame;
  NSRect frame2 = self->colorWell.frame;
  frame2.origin.x = CGRectGetMaxX(NSRectToCGRect(frame1))+2;
  self->colorWell.frame = frame2;
  self->colorWellButton.frame = frame2;
}
//end setAxisTitle:

-(NSColor*) axisColor
{
  return self->colorWell.color;
}
//end axisColor

-(void) setAxisColor:(NSColor*)value
{
  if (![value isEqualTo:self.axisColor])
  {
    [self willChangeValueForKey:CHAxisColorBinding];
    self->colorWell.color = !value ? [NSColor blackColor] : value;
    [self didChangeValueForKey:CHAxisColorBinding];
    [self propagateValue:self.axisColor forBinding:CHAxisColorBinding];
  }//end if (![value isEqualTo:self.axisColor])
}
//end setAxisColor:

#pragma mark CHColorWellButtonDelegate
-(IBAction) changeColor:(id)sender
{
  CHColorWellButton* senderAsColorWellButton = [sender dynamicCastToClass:[CHColorWellButton class]];
  self.axisColor = senderAsColorWellButton.associatedColorWell.color;
}
//end changeColor:


@end
