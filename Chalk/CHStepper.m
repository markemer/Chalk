//
//  CHStepper.m
//  Chalk
//
//  Created by Pierre Chatelier on 20/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHStepper.h"

@interface CHStepper ()
-(void) customInit;
-(BOOL) performIncrement;
-(BOOL) performDecrement;
@end

@interface CHStepperAssistant : NSObject {
  double innerValue;
}
@property(assign) CHStepper* owner;
@property(assign) NSStepper* stepper;
@property(nonatomic) double innerValue;
@end

@implementation CHStepperAssistant
@synthesize owner;
@synthesize stepper;
@synthesize innerValue;

-(void) setInnerValue:(double)value
{
  double prev = self->innerValue;
  double next = value;
  if (next != self->innerValue)
  {
    [self willChangeValueForKey:@"innerValue"];
    self->innerValue = next;
    [self didChangeValueForKey:@"innerValue"];
    if (next == prev+self->stepper.increment)
      [self->owner performIncrement];
    else if (next == prev-self->stepper.increment)
      [self->owner performDecrement];
    else if (next == self->stepper.minValue)
      [self->owner performIncrement];
    else if (next == self->stepper.maxValue)
      [self->owner performDecrement];
  }//end if (next != self->_innerValue)
}
//end setInnerValue:

@end

@implementation CHStepper

@dynamic controlSize;

-(instancetype) initWithFrame:(NSRect)frame
{
  if (!((self = [super initWithFrame:frame])))
    return nil;
  [self customInit];
  return self;
}
//end initWithFrame:

-(instancetype) initWithCoder:(NSCoder*)coder
{
  if (!((self = [super initWithCoder:coder])))
    return nil;
  [self customInit];
  return self;
}
//end initWithCoder:

-(void) customInit
{
  self->innerStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height)];
  self->innerStepper.enabled = YES;
  self->innerStepper.minValue = -1;
  self->innerStepper.maxValue =  1;
  self->innerStepper.increment = 1;
  self->innerStepper.doubleValue = 0;
  [self addSubview:self->innerStepper];
  self->assistant = [[CHStepperAssistant alloc] init];
  self->assistant.owner = self;
  self->assistant.stepper = self->innerStepper;
  [self->innerStepper bind:NSValueBinding toObject:self->assistant withKeyPath:@"innerValue" options:nil];
}
//end customInit

-(void) dealloc
{
  [self->innerStepper unbind:@"innerValue"];
  [self->innerStepper removeFromSuperview];
  [self->innerStepper release];
  [self->assistant release];
  [super dealloc];
}
//end dealloc

-(NSControlSize) controlSize
{
  NSControlSize result = ((NSCell*)self->innerStepper.cell).controlSize;
  return result;
}
//end controlSize

-(void) setControlSize:(NSControlSize)value
{
  ((NSCell*)self->innerStepper.cell).controlSize = value;
}
//end setControlSize:

-(void) setEnabled:(BOOL)value
{
  [super setEnabled:value];
  [self->innerStepper setEnabled:value];
}
//end setEnabled:

-(BOOL) performIncrement
{
  BOOL result = NO;
  if (self.delegate)
    result = [self.delegate stepperShouldIncrement:self];
  return result;
}
//end performIncrement

-(BOOL) performDecrement
{
  BOOL result = NO;
  if (self.delegate)
    result = [self.delegate stepperShouldDecrement:self];
  return result;
}
//end performDecrement

@end
