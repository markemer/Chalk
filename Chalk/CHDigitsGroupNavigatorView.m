//
//  CHDigitsGroupNavigatorView.m
//  Chalk
//
//  Created by Pierre Chatelier on 25/03/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHDigitsGroupNavigatorView.h"

#import "CHDigitsGroupView.h"
#import "NSViewExtended.h"

@implementation CHDigitsGroupNavigatorView

@synthesize enabled;
@synthesize rangeLabel;
@synthesize leftMostButton;
@synthesize leftBestButton;
@synthesize leftButton;
@synthesize rightButton;
@synthesize rightBestButton;
@synthesize rightMostButton;
@synthesize currentDigitsGroupView;
@dynamic    inputBitInterpretation;
@synthesize inputComputeMode;
@synthesize inputNumberValue;
@synthesize inputRawValue;
@synthesize minorPartsVisible;
@synthesize outputRawValue;
@dynamic    outputBitInterpretation;
@synthesize outputNumberValue;
@synthesize digitsOrder;
@synthesize bitsPerDigit;
@synthesize digitsRangeNavigatable;
@synthesize digitsRangeModifiable;
@synthesize digitsRangeNatural;
@synthesize digitsGroupSize;
@synthesize digitsGroupIndex;
@dynamic    digitsGroupIndexNavigatableMax;
@dynamic    digitsGroupIndexModifiableMax;
@dynamic    digitsGroupIndexNaturalMax;

@synthesize signColor1;
@synthesize exponentColor1;
@synthesize significandColor1;
@synthesize signColor2;
@synthesize exponentColor2;
@synthesize significandColor2;

@synthesize delegate;

-(void) dealloc
{
  [self->nextDigitsGroupView release];
  self.exponentColor1 = nil;
  self.exponentColor2 = nil;
  self.signColor1 = nil;
  self.signColor2 = nil;
  self.significandColor1 = nil;
  self.significandColor2 = nil;
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  self->bitsPerDigit = 1;
  self->nextDigitsGroupView = [[CHDigitsGroupView alloc] initWithFrame:self.currentDigitsGroupView.frame];
  self->nextDigitsGroupView.hidden = YES;
  [self.currentDigitsGroupView.superview addSubview:self->nextDigitsGroupView];
  self->currentDigitsGroupView.navigatorView = self;
  self->nextDigitsGroupView.navigatorView = self;
  memset(&self->inputBitInterpretation, 0, sizeof(self->inputBitInterpretation));
  memset(&self->outputBitInterpretation, 0, sizeof(self->outputBitInterpretation));
}
//end awakeAfterUsingCoder:

-(void) setSignColor1:(NSColor*)value
{
  if (value != self->signColor1)
  {
    [self willChangeValueForKey:@"signColor1"];
    [self->signColor1 release];
    self->signColor1 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"signColor1"];
    [self updateControls];
  }//end if (value != self->signColor1)
}
//end setSignColor1:

-(void) setSignColor2:(NSColor*)value
{
  if (value != self->signColor2)
  {
    [self willChangeValueForKey:@"signColor2"];
    [self->signColor2 release];
    self->signColor2 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"signColor2"];
    [self updateControls];
  }//end if (value != self->signColor2)
}
//end setSignColor2:

-(void) setExponentColor1:(NSColor*)value
{
  if (value != self->exponentColor1)
  {
    [self willChangeValueForKey:@"exponentColor1"];
    [self->exponentColor1 release];
    self->exponentColor1 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"exponentColor1"];
    [self updateControls];
  }//end if (value != self->exponentColor1)
}
//end setExponentColor1:

-(void) setExponentColor2:(NSColor*)value
{
  if (value != self->exponentColor2)
  {
    [self willChangeValueForKey:@"exponentColor2"];
    [self->exponentColor2 release];
    self->exponentColor2 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"exponentColor2"];
    [self updateControls];
  }//end if (value != self->exponentColor2)
}
//end setExponentColor2:

-(void) setSignificandColor1:(NSColor*)value
{
  if (value != self->significandColor1)
  {
    [self willChangeValueForKey:@"significandColor1"];
    [self->significandColor1 release];
    self->significandColor1 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"significandColor1"];
    [self updateControls];
  }//end if (value != self->significandColor1)
}
//end setSignificandColor1:

-(void) setSignificandColor2:(NSColor*)value
{
  if (value != self->significandColor2)
  {
    [self willChangeValueForKey:@"significandColor2"];
    [self->significandColor2 release];
    self->significandColor2 = [value copy];
    self->isDirtyUpdate = YES;
    [self didChangeValueForKey:@"significandColor2"];
    [self updateControls];
  }//end if (value != self->significandColor2)
}
//end setSignificandColor2:

-(void) drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
}
//end drawRect:

-(void) setDelegate:(id)value
{
  if (value != self->delegate)
  {
    self->delegate = value;
    self->currentDigitsGroupView.delegate = self->delegate;
    self->nextDigitsGroupView.delegate = self->delegate;
  }//end if (value != self->delegate)
}
//end setDelegate:

-(void) setDigitsOrder:(NSInteger)value
{
  if (value != self->digitsOrder)
  {
    self->digitsOrder = value;
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value != self->digitsOrder)
}
//end setDigitsOrder:

-(void) setBitsPerDigit:(NSUInteger)value
{
  if (value != self->bitsPerDigit)
  {
    if (value)
    {
      self->bitsPerDigit = value;
      self->isDirtyUpdate = YES;
      [self updateControls];
    }//end if (value)
  }//end if (value != self->bitsPerDigit)
}
//end setBitsPerDigit:

-(void) setDigitRangeNavigatable:(NSRange)value
{
  if (!NSEqualRanges(value, self->digitsRangeNavigatable))
  {
    self->digitsRangeNavigatable = value;
    self.digitsGroupIndex = MIN(self.digitsGroupIndex, self.digitsGroupIndexNavigatableMax);
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (!NSEqualRanges(value, self->digitRangeNavigatable))
}
//end setDigitRangeNavigatable:

-(void) setDigitRangeModifiable:(NSRange)value
{
  if (!NSEqualRanges(value, self->digitsRangeModifiable))
  {
    self->digitsRangeModifiable = value;
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (!NSEqualRanges(value, self->digitRangeModifiable))
}
//end setDigitRangeModifiable:

-(void) setDigitRangeNatural:(NSRange)value
{
  if (!NSEqualRanges(value, self->digitsRangeNatural))
  {
    self->digitsRangeNatural = value;
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (!NSEqualRanges(value, self->digitRangeNatural))
}
//end setDigitRangeNatural:

-(void) setDigitsGroupSize:(NSUInteger)value
{
  if (value != self->digitsGroupSize)
  {
    self->digitsGroupSize = value;
    self.digitsGroupIndex = MIN(self.digitsGroupIndex, self.digitsGroupIndexNavigatableMax);
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value != self->digitsGroupSize)
}
//end setDigitsGroupSize:

-(NSUInteger) digitsGroupIndexNavigatableMax
{
  NSUInteger result = !self->digitsGroupSize || !self->digitsRangeNavigatable.length ? 0U :
   ((NSMaxRange(self->digitsRangeNavigatable)-1)/self->digitsGroupSize)/self.bitsPerDigit;
  return result;
}
//end digitsGroupIndexNavigatableMax:

-(NSUInteger) digitsGroupIndexModifiableMax
{
  NSUInteger result = !self->digitsGroupSize || !self->digitsRangeNavigatable.length ? 0U :
   ((NSMaxRange(self->digitsRangeModifiable)-1)/self->digitsGroupSize)/self.bitsPerDigit;
  return result;
}
//end digitsGroupIndexNavitagableMax:

-(NSUInteger) digitsGroupIndexNaturalMax
{
  NSUInteger result = !self->digitsGroupSize || !self->digitsRangeNavigatable.length ? 0U :
   ((NSMaxRange(self->digitsRangeNatural)-1)/self->digitsGroupSize)/self.bitsPerDigit;
  return result;
}
//end digitsGroupIndexNaturalMax:

-(void) setDigitsGroupIndex:(NSUInteger)value
{
  if (value != self->digitsGroupIndex)
  {
    self->digitsGroupIndex = MIN(value, self.digitsGroupIndexNavigatableMax);
    [self->currentDigitsGroupView invalidatePresentation];
    [self->nextDigitsGroupView invalidatePresentation];
    self->currentDigitsGroupView.digitsGroupIndex = self->digitsGroupIndex;
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value != self->digitsGroupIndex)
}
//end setDIgitsGroupsCount:

-(void) setInputComputeMode:(chalk_compute_mode_t)value
{
  if (value != self->inputComputeMode)
  {
    self->inputComputeMode = value;
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value != self->inputComputeMode)
}
//end setInputComputeMode:

-(void) setInputNumberValue:(const chalk_gmp_value_t*)value
{
  self->inputNumberValue = value;
  self->isDirtyUpdate = YES;
  self.digitsGroupIndex = MIN(self.digitsGroupIndex, self.digitsGroupIndexNavigatableMax);
  [self updateControls];
}
//end setInputNumberValue:

-(const chalk_bit_interpretation_t*) inputBitInterpretation
{
  return &self->inputBitInterpretation;
}
//end inputBitInterpretation

-(void) setInputBitInterpretation:(const chalk_bit_interpretation_t*)value
{
  if (value && !bitInterpretationEquals(value, &self->inputBitInterpretation))
  {
    self->inputBitInterpretation = *value;
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value && !bitInterpretationEquals(value, &self->inputBitInterpretation))
}
//end setBitInterpretation:

-(void) setInputRawValue:(const chalk_raw_value_t*)value
{
  self->inputRawValue = value;
  self->isDirtyUpdate = YES;
  [self updateControls];
}
//end setInputRawValue:

-(void) setMinorPartsVisible:(chalk_number_part_minor_type_t)value
{
  self->minorPartsVisible = value;
  self->isDirtyUpdate = YES;
  [self updateControls];
}
//end setMinorPartsVisible:

-(void) setOutputRawValue:(chalk_raw_value_t*)value
{
  self->outputRawValue = value;
  self->isDirtyUpdate = YES;
  [self updateControls];
}
//end setOutputRawValue:

-(const chalk_bit_interpretation_t*) outputBitInterpretation
{
  return &self->outputBitInterpretation;
}
//end outputBitInterpretation

-(void) setOutputBitInterpretation:(const chalk_bit_interpretation_t*)value
{
  if (value && !bitInterpretationEquals(value, &self->outputBitInterpretation))
  {
    self->outputBitInterpretation = *value;
    self->isDirtyUpdate = YES;
    [self updateControls];
  }//end if (value && !bitInterpretationEquals(value, &self->outputBitInterpretation))
}
//end setOutputBitInterpretation:

-(void) setOutputNumberValue:(chalk_gmp_value_t*)value
{
  self->outputNumberValue = value;
  self->isDirtyUpdate = YES;
  [self updateControls];
}
//end setNumberValueModified:

-(IBAction) navigate:(id)sender
{
  if ((sender == self.leftMostButton) || (sender == self.leftBestButton) || (sender == self.leftButton) ||
      (sender == self.rightButton) || (sender == self.rightBestButton) || (sender == self.rightMostButton))
  {
    if (!self->isAnimating)
    {
      NSRect currentDigitsGroupViewCurrentFrame = self.currentDigitsGroupView.frame;
      NSRect currentDigitsGroupViewNextFrame = currentDigitsGroupViewCurrentFrame;
      NSRect nextDigitsGroupViewCurrentFrame = currentDigitsGroupViewCurrentFrame;
      NSRect nextDigitsGroupViewNextFrame = currentDigitsGroupViewCurrentFrame;
      NSUInteger nextDigitsGroupIndex = self->digitsGroupIndex;
      NSButton* localRightMostButton =
        (self->digitsOrder == 0) ? self.rightMostButton : self.leftMostButton;
      NSButton* localLeftMostButton =
        (self->digitsOrder == 0) ? self.leftMostButton : self.rightMostButton;
      NSButton* localRightBestButton =
        (self->digitsOrder == 0) ? self.rightBestButton : self.leftBestButton;
      NSButton* localLeftBestButton =
        (self->digitsOrder == 0) ? self.leftBestButton : self.rightBestButton;
      NSButton* localRightButton =
        (self->digitsOrder == 0) ? self.rightButton : self.leftButton;
      NSButton* localLeftButton =
        (self->digitsOrder == 0) ? self.leftButton : self.rightButton;
      if (sender == localRightMostButton)
      {
        nextDigitsGroupIndex = 0;
        currentDigitsGroupViewNextFrame.origin.x -= currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x += currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localRightMostButton)
      else if (sender == localRightBestButton)
      {
        mp_bitcnt_t LSBIndex = mpz_scan1(self->outputRawValue->bits, 0)/self.bitsPerDigit;
        NSUInteger bestRightDigitsGroupIndex = (LSBIndex == (mp_bitcnt_t)-1) ? 0 : (LSBIndex/mp_bits_per_limb);
        nextDigitsGroupIndex = bestRightDigitsGroupIndex;
        currentDigitsGroupViewNextFrame.origin.x -= currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x += currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localRightBestButton)
      else if (sender == localRightButton)
      {
        if (nextDigitsGroupIndex)
          --nextDigitsGroupIndex;
        currentDigitsGroupViewNextFrame.origin.x -= currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x += currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localRightButton)
      else if (sender == localLeftButton)
      {
        if (nextDigitsGroupIndex < self.digitsGroupIndexNavigatableMax)
          ++nextDigitsGroupIndex;
        currentDigitsGroupViewNextFrame.origin.x += currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x -= currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localLeftButton)
      else if (sender == localLeftBestButton)
      {
        mp_bitcnt_t MSBIndex = mpz_sizeinbase(self->outputRawValue->bits, 2)/self.bitsPerDigit;
        NSUInteger bestLeftDigitsGroupIndex = (MSBIndex == (mp_bitcnt_t)-1) ? 0 : (MSBIndex/mp_bits_per_limb);
        nextDigitsGroupIndex = bestLeftDigitsGroupIndex;
        currentDigitsGroupViewNextFrame.origin.x -= currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x += currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localLeftBestButton)
      else if (sender == localLeftMostButton)
      {
        nextDigitsGroupIndex = self.digitsGroupIndexNavigatableMax;
        currentDigitsGroupViewNextFrame.origin.x += currentDigitsGroupViewNextFrame.size.width;
        nextDigitsGroupViewCurrentFrame.origin.x -= currentDigitsGroupViewCurrentFrame.size.width;
      }//end if (sender == localLeftMostButton)
      
      if (nextDigitsGroupIndex != self->digitsGroupIndex)
      {
        self->isAnimating = YES;
        self->nextDigitsGroupView.digitsGroupIndex = nextDigitsGroupIndex;
        self->nextDigitsGroupView.frame = nextDigitsGroupViewCurrentFrame;
        self->nextDigitsGroupView.hidden = NO;
        /*NSAnimationContext is buggy, use NSViewAnimation instead*/
        NSViewAnimation* viewAnimation = [[[NSViewAnimation alloc] initWithViewAnimations:@[
          @{NSViewAnimationTargetKey:self->currentDigitsGroupView,
            NSViewAnimationStartFrameKey:[NSValue valueWithRect:self->currentDigitsGroupView.frame],
            NSViewAnimationEndFrameKey:[NSValue valueWithRect:currentDigitsGroupViewNextFrame],
          },
          @{NSViewAnimationTargetKey:self->nextDigitsGroupView,
            NSViewAnimationStartFrameKey:[NSValue valueWithRect:self->nextDigitsGroupView.frame],
            NSViewAnimationEndFrameKey:[NSValue valueWithRect:nextDigitsGroupViewNextFrame],
          },
          ]] autorelease];
        viewAnimation.duration = 0.33;
        viewAnimation.delegate = self;
        viewAnimation.animationCurve = NSAnimationEaseOut;
        viewAnimation.animationBlockingMode = NSAnimationNonblocking;
        self->animationNextDigitsGroupIndex = nextDigitsGroupIndex;
        [viewAnimation startAnimation];
        /*[NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setCompletionHandler:^{
          CHDigitsGroupView* tmp = self->currentDigitsGroupView;
          self->currentDigitsGroupView = self->nextDigitsGroupView;
          self->nextDigitsGroupView = tmp;
          self->nextDigitsGroupView.hidden = YES;
          self.digitsGroupIndex = nextDigitsGroupIndex;
          self->isAnimating = NO;
        }];//end setCompletionHandler:
        [[NSAnimationContext currentContext] setDuration:0.33];
        [[self->currentDigitsGroupView animator] setFrame:currentDigitsGroupViewNextFrame];
        [[self->nextDigitsGroupView animator] setFrame:nextDigitsGroupViewNextFrame];
        [NSAnimationContext endGrouping];*/
      }//end if (nextDigitsGroupIndex != self->digitsGroupIndex)
    }//end if (!self->isAnimating)
  }//end if ((sender == self.leftMostButton) || (sender == self.leftBestButton) || (sender == self.leftButton) || (sender == self.rightButton) || (sender == self.rightBestButton) || (sender == self.rightMostButton))
}
//end navigate:

-(void) animationDidEnd:(NSAnimation *)animation
{
  CHDigitsGroupView* tmp = self->currentDigitsGroupView;
  self->currentDigitsGroupView = self->nextDigitsGroupView;
  self->nextDigitsGroupView = tmp;
  self->nextDigitsGroupView.hidden = YES;
  self.digitsGroupIndex = self->animationNextDigitsGroupIndex;
  self->isAnimating = NO;
}
//end animationDidStop:(NSAnimation *)animation

-(void) beginUpdate
{
  ++self->updateCount;
}
//end beginUpdate

-(void) endUpdate
{
  if (!(--self->updateCount))
    [self updateControls];
}
//end endUpdate

-(void) outputRawValueDidChange:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(outputRawValueDidChange:)])
    [self.delegate outputRawValueDidChange:self];
}
//end outputRawValueDidChange:

-(void) updateControls
{
  if (self->updateCount)
    self->isDirtyUpdate = YES;
  else if (self->isDirtyUpdate)
  {
    NSButton* localRightMostButton =
      (self->digitsOrder == 0) ? self.rightMostButton : self.leftMostButton;
    NSButton* localLeftMostButton =
      (self->digitsOrder == 0) ? self.leftMostButton : self.rightMostButton;
    NSButton* localRightBestButton =
      (self->digitsOrder == 0) ? self.rightBestButton : self.leftBestButton;
    NSButton* localLeftBestButton =
      (self->digitsOrder == 0) ? self.leftBestButton : self.rightBestButton;
    NSButton* localRightButton =
      (self->digitsOrder == 0) ? self.rightButton : self.leftButton;
    NSButton* localLeftButton =
      (self->digitsOrder == 0) ? self.leftButton : self.rightButton;
    
    localLeftMostButton.toolTip = NSLocalizedString(@"To most significand bits", @"");
    localLeftBestButton.toolTip = NSLocalizedString(@"To most significand set bit", @"");
    localLeftButton.toolTip = NSLocalizedString(@"To next group of bits", @"");
    localRightMostButton.toolTip = NSLocalizedString(@"To least significand bits", @"");
    localRightBestButton.toolTip = NSLocalizedString(@"To least significand set bit", @"");
    localRightButton.toolTip = NSLocalizedString(@"To previous group of bits", @"");

    mp_bitcnt_t MSBIndex = mpz_sizeinbase(self->outputRawValue->bits, 2)/self.bitsPerDigit;
    mp_bitcnt_t LSBIndex = mpz_scan1(self->outputRawValue->bits, 0)/self.bitsPerDigit;
    NSUInteger bestLeftDigitsGroupIndex = (MSBIndex == (mp_bitcnt_t)-1) ? 0 : (MSBIndex/mp_bits_per_limb);
    NSUInteger bestRightDigitsGroupIndex = (LSBIndex == (mp_bitcnt_t)-1) ? 0 : (LSBIndex/mp_bits_per_limb);

    localLeftMostButton.enabled = (self->digitsGroupIndex < self.digitsGroupIndexNavigatableMax);
    localLeftBestButton.enabled = (self->digitsGroupIndex < bestLeftDigitsGroupIndex);
    localLeftButton.enabled = (self->digitsGroupIndex < self.digitsGroupIndexNavigatableMax);
    localRightButton.enabled = (self->digitsGroupIndex > 0);
    localRightBestButton.enabled = (self->digitsGroupIndex > bestRightDigitsGroupIndex);
    localRightMostButton.enabled = (self->digitsGroupIndex > 0);
    self.rangeLabel.stringValue = [NSString stringWithFormat:@"[%@...%@[",
      @(self->digitsGroupIndex*self->digitsGroupSize),
      @((self->digitsGroupIndex+1)*self->digitsGroupSize)];
    [self.rangeLabel sizeToFit];
    [self.rangeLabel centerInParentHorizontally:YES vertically:NO];
    [self->currentDigitsGroupView updateControls];
    self->isDirtyUpdate = NO;
  }//end if (self->isDirtyUpdate)
}
//end updateControls

@end
