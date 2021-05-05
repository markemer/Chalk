//
//  CHGraphCurveParametersViewController.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/05/2017.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHGraphCurveParametersViewController.h"

#import "CHColorWell.h"
#import "CHGraphCurveItem.h"
#import "CHGraphCurve.h"

#import "NSObjectExtended.h"

@implementation CHGraphCurveParametersViewController

@synthesize target;
@synthesize action;
@synthesize graphCurveItem;

-(void) dealloc
{
  [self->graphCurveItem release];
  self->graphCurveItem = nil;
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  self->thicknessFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", NSLocalizedString(@"px", @"px")];
  self->elementSizeFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", NSLocalizedString(@"px", @"px")];
  
  NSRect frame = NSZeroRect;
  NSRect maxRect = NSZeroRect;
  
  self->thicknessStepper.minValue = self->thicknessFormatter.minimum.doubleValue;
  self->thicknessLabel.stringValue = NSLocalizedString(@"Thickness", @"");
  [self->thicknessLabel sizeToFit];
  maxRect = NSUnionRect(maxRect, self->thicknessStepper.frame);
  maxRect = NSUnionRect(maxRect, self->thicknessLabel.frame);

  self->elementPixelSizeStepper.minValue = self->elementSizeFormatter.minimum.doubleValue;
  self->elementPixelSizeLabel.stringValue = NSLocalizedString(@"Element size", @"");
  [self->elementPixelSizeLabel sizeToFit];
  maxRect = NSUnionRect(maxRect, self->elementPixelSizeStepper.frame);
  maxRect = NSUnionRect(maxRect, self->elementPixelSizeLabel.frame);
  
  self->color1Label.stringValue = NSLocalizedString(@"Predicate <false> color", @"");
  self->color2Label.stringValue = NSLocalizedString(@"Predicate <true> color", @"");
  [self->color1Label sizeToFit];
  [self->color2Label sizeToFit];
  maxRect = NSUnionRect(maxRect, self->color1Label.frame);
  maxRect = NSUnionRect(maxRect, self->color2Label.frame);

  self->color1Label.stringValue = NSLocalizedString(@"Curve color", @"");
  self->color2Label.stringValue = NSLocalizedString(@"Curve interior color", @"");
  [self->color1Label sizeToFit];
  [self->color2Label sizeToFit];
  maxRect = NSUnionRect(maxRect, self->color1Label.frame);
  maxRect = NSUnionRect(maxRect, self->color2Label.frame);
  
  self->color1ColorWell.allowAlpha = YES;
  self->color2ColorWell.allowAlpha = YES;
  
  self->uncertaintyVisibleCheckBox.title = NSLocalizedString(@"Draw uncertainty", @"");
  [self->uncertaintyVisibleCheckBox sizeToFit];
  frame = self->uncertaintyColorWell.frame;
  frame.origin.x = CGRectGetMaxX(NSRectToCGRect(self->uncertaintyVisibleCheckBox.frame))+4;
  self->uncertaintyColorWell.frame = frame;
  maxRect = NSUnionRect(maxRect, self->uncertaintyVisibleCheckBox.frame);
  maxRect = NSUnionRect(maxRect, self->uncertaintyColorWell.frame);

  self->uncertaintyNaNVisibleCheckBox.title = NSLocalizedString(@"Draw NaN as uncertainty", @"");
  self->uncertaintyNaNVisibleCheckBox.toolTip = NSLocalizedString(@"DRAW_NAN_AS_UNCERTAINTY_TOOLTIP", @"");
  [self->uncertaintyNaNVisibleCheckBox sizeToFit];
  frame = self->uncertaintyNaNColorWell.frame;
  frame.origin.x = CGRectGetMaxX(NSRectToCGRect(self->uncertaintyNaNVisibleCheckBox.frame))+4;
  self->uncertaintyNaNColorWell.frame = frame;
  maxRect = NSUnionRect(maxRect, self->uncertaintyNaNVisibleCheckBox.frame);
  maxRect = NSUnionRect(maxRect, self->uncertaintyNaNColorWell.frame);

  self->uncertaintyColorWell.allowAlpha = YES;
  self->uncertaintyNaNColorWell.allowAlpha = YES;
  
  frame = self.view.frame;
  frame.size.width = CGRectGetMaxX(NSRectToCGRect(maxRect));
  frame.size.width += 8;
  self.view.frame = frame;

  [self updateControls];
}
//end awakeFromNib

-(void) setGraphCurveItem:(CHGraphCurveItem*)value
{
  if (value != self->graphCurveItem)
  {
    [self->graphCurveItem release];
    self->graphCurveItem = [value retain];
    [self updateControls];
  }//end if (value != self->graphCurveItem)
}
//end setGraphCurveItem:

-(IBAction) changeParameter:(id)sender
{
  if (sender == self->thicknessTextField)
  {
    self->graphCurveItem.curveThickness =
      [self->thicknessFormatter numberFromString:self->thicknessTextField.stringValue].unsignedIntegerValue;
    [self updateControls];
  }//end if (sender == self->thicknessTextField)
  else if (sender == self->thicknessStepper)
  {
    self->graphCurveItem.curveThickness =
      [self->thicknessFormatter numberFromString:self->thicknessStepper.stringValue].unsignedIntegerValue;
    [self updateControls];
  }//end if (sender == self->thicknessStepper)
  else if (sender == self->elementPixelSizeTextField)
  {
    self->graphCurveItem.curve.elementPixelSize =
      [self->elementSizeFormatter numberFromString:self->elementPixelSizeTextField.stringValue].unsignedIntegerValue;
    [self updateControls];
  }//end if (sender == self->elementPixelSizeTextField)
  else if (sender == self->elementPixelSizeStepper)
  {
    self->graphCurveItem.curve.elementPixelSize =
      [self->elementSizeFormatter numberFromString:self->elementPixelSizeStepper.stringValue].unsignedIntegerValue;
    [self updateControls];
  }//end if (sender == self->elementPixelSizeStepper)
  else if (sender == self->color1ColorWell)
  {
    if (!self->graphCurveItem.isPredicate)
      self->graphCurveItem.curveColor = self->color1ColorWell.color;
    else//if (self->graphCurveItem.isPredicate)
      self->graphCurveItem.predicateColorFalse = self->color1ColorWell.color;
    [self updateControls];
  }//end if (sender == self->color1ColorWell)
  else if (sender == self->color2ColorWell)
  {
    if (!self->graphCurveItem.isPredicate)
      self->graphCurveItem.curveInteriorColor = self->color2ColorWell.color;
    else//if (self->graphCurveItem.isPredicate)
      self->graphCurveItem.predicateColorTrue = self->color2ColorWell.color;
    [self updateControls];
  }//end if (sender == self->color2ColorWell)
  else if (sender == self->uncertaintyVisibleCheckBox)
  {
    self->graphCurveItem.curveUncertaintyVisible = (self->uncertaintyVisibleCheckBox.state == NSOnState);
    [self updateControls];
  }//end if (sender == self->uncertaintyVisibleCheckBox)
  else if (sender == self->uncertaintyColorWell)
  {
    self->graphCurveItem.curveUncertaintyColor = self->uncertaintyColorWell.color;
    [self updateControls];
  }//end if (sender == self->uncertaintyColorWell)
  else if (sender == self->uncertaintyNaNVisibleCheckBox)
  {
    self->graphCurveItem.curveUncertaintyNaNVisible = (self->uncertaintyNaNVisibleCheckBox.state == NSOnState);
    [self updateControls];
  }//end if (sender == self->uncertaintyNaNVisibleCheckBox)
  else if (sender == self->uncertaintyNaNColorWell)
  {
    self->graphCurveItem.curveUncertaintyNaNColor = self->uncertaintyNaNColorWell.color;
    [self updateControls];
  }//end if (sender == self->uncertaintyNaNColorWell)
}
//end changeParameter:

-(void) updateControls
{
  BOOL isPredicate = self.graphCurveItem.isPredicate;
  
  NSUInteger thickness = self->graphCurveItem.curveThickness;
  NSString* thicknessString = [self->thicknessFormatter stringFromNumber:@(thickness)];
  self->thicknessTextField.enabled = !isPredicate;
  self->thicknessStepper.enabled = !isPredicate;
  self->thicknessTextField.stringValue = thicknessString;
  self->thicknessStepper.enabled = !isPredicate;
  self->thicknessStepper.stringValue = thicknessString;

  NSUInteger elementPixelSize = MAX(1U, self->graphCurveItem.curve.elementPixelSize);
  NSString* elementPixelSizeString = [self->elementSizeFormatter stringFromNumber:@(elementPixelSize)];
  self->elementPixelSizeTextField.enabled = (self->graphCurveItem.curve != nil) && (isPredicate || self.graphCurveItem.curveUncertaintyVisible);
  self->elementPixelSizeTextField.stringValue = elementPixelSizeString;
  self->elementPixelSizeStepper.enabled = (self->graphCurveItem.curve != nil) && (isPredicate || self.graphCurveItem.curveUncertaintyVisible);
  self->elementPixelSizeStepper.stringValue = elementPixelSizeString;
  
  NSColor* color1 = !isPredicate ? self.graphCurveItem.curveColor : self.graphCurveItem.predicateColorFalse;
  NSColor* color2 = !isPredicate ? self.graphCurveItem.curveInteriorColor : self.graphCurveItem.predicateColorTrue;
  self->color1ColorWell.color = !color1 ? [NSColor blackColor] : color1;
  self->color2ColorWell.color = !color2 ? (isPredicate ? [NSColor blackColor] : [NSColor clearColor]) : color2;
  self->color1ColorWell.hidden = NO;
  self->color2ColorWell.hidden = NO;
  self->color1Label.hidden = NO;
  self->color2Label.hidden = NO;
  self->color1Label.stringValue = !isPredicate ? NSLocalizedString(@"Curve color", @"") :
    NSLocalizedString(@"Predicate <false> color", @"");
  self->color2Label.stringValue = !isPredicate ? NSLocalizedString(@"Curve interior color", @"") :
    NSLocalizedString(@"Predicate <true> color", @"");
  
  self->uncertaintyVisibleCheckBox.hidden = isPredicate;
  self->uncertaintyVisibleCheckBox.enabled = !isPredicate;
  self->uncertaintyVisibleCheckBox.state = self.graphCurveItem.curveUncertaintyVisible ? NSOnState : NSOffState;
  self->uncertaintyColorWell.hidden = isPredicate;
  self->uncertaintyColorWell.enabled = !isPredicate;
  NSColor* color3 = isPredicate ? nil : self.graphCurveItem.curveUncertaintyColor;
  if (color3)
    self->uncertaintyColorWell.color = color3;

  self->uncertaintyNaNVisibleCheckBox.hidden = isPredicate;
  self->uncertaintyNaNVisibleCheckBox.enabled = !isPredicate && self.graphCurveItem.curveUncertaintyVisible;
  self->uncertaintyNaNVisibleCheckBox.state = self.graphCurveItem.curveUncertaintyNaNVisible ? NSOnState : NSOffState;
  self->uncertaintyNaNColorWell.hidden = isPredicate;
  self->uncertaintyNaNColorWell.enabled = !isPredicate && self.graphCurveItem.curveUncertaintyVisible;
  NSColor* color4 = isPredicate ? nil : self.graphCurveItem.curveUncertaintyNaNColor;
  if (color4)
    self->uncertaintyNaNColorWell.color = color3;
}
//end updateControls

@end
