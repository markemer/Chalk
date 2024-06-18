//
//  CHStepperNumber.m
//  Chalk
//
//  Created by Pierre Chatelier on 04/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHStepperNumber.h"

#import "CHUtils.h"
#import "NSNumberExtended.h"
#import "NSObjectExtended.h"


@interface CHStepper()
-(void) customInit;
-(BOOL) performIncrement;
-(BOOL) performDecrement;
@end

@interface CHStepperNumber()
-(NSNumber*) clip:(NSNumber*)input;
@end

@implementation CHStepperNumber

@dynamic minValue;
@dynamic maxValue;
@dynamic increment;
@dynamic value;
@dynamic stringValue;
@dynamic attributedStringValue;
@dynamic objectValue;
@dynamic intValue;
@dynamic floatValue;
@dynamic doubleValue;
@dynamic integerValue;
@synthesize autorepeat;
@synthesize valueWraps;

+(void) initialize
{
  [self exposeBinding:NSValueBinding];
}
//end initialize

-(Class) valueClassForBinding:(NSString*)binding
{
  Class result = Nil;
  if ([binding isEqualToString:NSValueBinding])
    result = [NSDecimalNumber class];
  else
    result = [super valueClassForBinding:binding];
  return result;
}
//end valueClassForBinding

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
  [super customInit];
  self->minValue = [[NSDecimalNumber zero] copy];
  self->maxValue = [[NSDecimalNumber alloc] initWithUnsignedInteger:NSUIntegerMax];
  self->increment = [[NSDecimalNumber one] copy];
  self->_value = [[NSDecimalNumber zero] copy];
  self->autorepeat = self->innerStepper.autorepeat;
  self->valueWraps = NO;
}
//end customInit

-(void) dealloc
{
  [self->minValue release];
  [self->maxValue release];
  [self->increment release];
  [self->_value release];
  [super dealloc];
}
//end dealloc

-(NSNumber*) minValue
{
  NSNumber* result = [[self->minValue copy] autorelease];
  return result;
}
//end minValue

-(void) setMinValue:(NSNumber*)value
{
  if (value != self->minValue)
  {
    [self->minValue release];
    self->minValue = !value ? @0 : [value copy];
    self.value = [self clip:self->_value];
  }//end if (value != self->minValue)
}
//end setMinValue:

-(NSNumber*) maxValue
{
  NSNumber* result = [[self->maxValue copy] autorelease];  return result;
}
//end maxValue

-(void) setMaxValue:(NSNumber*)value
{
  if (value != self->maxValue)
  {
    [self->maxValue release];
    self->maxValue = !value ? @0 : [value copy];
    self.value = [self clip:self->_value];
  }//end if (value != self->maxValue)
}
//end setMaxValue:

-(NSNumber*) increment
{
  NSNumber* result = [[self->increment copy] autorelease];
  return result;
}
//end increment

-(void) setIncrementNumber:(NSNumber*)value
{
  if (value != self->increment)
  {
    [self->increment release];
    self->increment = !value ? @0 : [value copy];
  }//end if (value != self->increment)
}
//end setIncrementNumber:

-(NSNumber*) value
{
  NSNumber* result = [[self->_value copy] autorelease];
  return result;
}
//end value

-(void) setValue:(NSNumber*)value
{
  NSNumber* newValue = [self clip:(!value ? @0 : value)];
  if (![newValue isEqualToNumber:self->_value])
  {
    [self willChangeValueForKey:NSValueBinding];
    [self->_value release];
    self->_value = [newValue retain];
    [self didChangeValueForKey:NSValueBinding];
    [self propagateValue:self->_value forBinding:NSValueBinding];
  }//end if (![newValue isEqualToNumber:self->_value])
}
//end setValue:

-(id) objectValue
{
  return self.value;
}
//end objectValue

-(void) setObjectValue:(id)objectValue
{
  [self setValue:objectValue];
}
//end setObjectValue:

-(NSString*) stringValue
{
  return [self->_value stringValue];
}
//end stringValue

-(void) setStringValue:(NSString*)value
{
  if (![value isEqualToString:self.stringValue])
    self.value = [NSNumber numberWithString:value];
}
//end setStringValue:

-(NSAttributedString*) attributedStringValue
{
  return [[[NSAttributedString alloc] initWithString:self.stringValue] autorelease];
}
//end attributedStringValue

-(void) setAttributedStringValue:(NSAttributedString*)value
{
  if (![value isEqualToAttributedString:self.attributedStringValue])
    [self setStringValue:value.string];
}
//end setAttributedStringValue:

-(int) intValue
{
  return [self->_value intValue];
}
//end intValue

-(void) setIntValue:(int)value
{
  if (value != self.intValue)
    self.value = [[[NSNumber alloc] initWithInt:value] autorelease];
}
//end setIntValue:

-(float) floatValue
{
  return [self->_value floatValue];
}
//end floatValue

-(void) setFloatValue:(float)value
{
  if (value != self.floatValue)
    self.value = [[[NSNumber alloc] initWithFloat:value] autorelease];
}
//end setFloatValue:

-(double) doubleValue
{
  return [self->_value doubleValue];
}
//end doubleValue

-(void) setDoubleValue:(double)value
{
  if (value != self.doubleValue)
    self.value = [[[NSNumber alloc] initWithDouble:value] autorelease];
}
//end setDoubleValue:

-(NSInteger) integerValue
{
  return [self->_value integerValue];
}
//end integerValue

-(void) setIntegerValue:(NSInteger)value
{
  if (value != self.integerValue)
    self.value = [[[NSNumber alloc] initWithInteger:value] autorelease];
}
//end setIntegerValue:

-(void) takeIntValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(intValue)])
    [self setIntValue:[sender intValue]];
}
//end takeIntValueFrom:

-(void) takeFloatValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(floatValue)])
    [self setFloatValue:[sender floatValue]];
}
//end takeFloatValueFrom:

-(void) takeDoubleValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(doubleValue)])
    [self setDoubleValue:[sender doubleValue]];
}
//end takeDoubleValueFrom:

-(void) takeStringValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(stringValue)])
    [self setStringValue:[sender stringValue]];
}
//end takeStringValueFrom:

-(void) takeObjectValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(objectValue)])
    [self setObjectValue:[sender objectValue]];
}
//end takeObjectValueFrom:

-(void) takeIntegerValueFrom:(id)sender
{
  if ([sender respondsToSelector:@selector(integerValue)])
    [self setIntegerValue:[sender integerValue]];
}
//end takeIntegerValueFrom:

-(NSNumber*) clip:(NSNumber*)input
{
  NSNumber* result = input;
  if ([input compare:self->minValue]<0)
  {
    [self willChangeValueForKey:NSValueBinding];
    [self->_value release];
    self->_value = [self->minValue copy];
    [self didChangeValueForKey:NSValueBinding];
  }//end if ([self->_value compare:self->minValue]<0)
  else if ([self->_value compare:self->maxValue]>0)
  {
    [self willChangeValueForKey:NSValueBinding];
    [self->_value release];
    self->_value = [self->maxValue copy];
    [self didChangeValueForKey:NSValueBinding];
  }//end if ([self->_value compare:self->minValue]>0)
  return result;
}
//end clip

-(BOOL) performIncrement
{
  BOOL result = NO;
  if (![self->increment isEqualToNumber:@0])
  {
    NSNumber* gapValue = [self->maxValue numberBySubtracting:self->_value];
    NSNumber* newValue = nil;
    if ([self->increment compare:gapValue] <= 0)
      newValue = [self->_value numberByAdding:self->increment];
    else if (!self.valueWraps)
      newValue = [[self->maxValue copy] autorelease];
    else
      newValue = [[self->minValue copy] autorelease];
    result = ![self->_value isEqualToNumber:newValue];
    if (result)
      self.value = newValue;
  }//end if (![self->increment isEqualToNumber:@0])
  [super performIncrement];
  return result;
}
//end performIncrement

-(BOOL) performDecrement
{
  BOOL result = NO;
  if (![self->increment isEqualToNumber:@0])
  {
    NSNumber* gapValue = [self->_value numberBySubtracting:self->minValue];
    NSNumber* newValue = nil;
    if ([self->increment compare:gapValue] <= 0)
      newValue = [self->_value numberBySubtracting:self->increment];
    else if (!self.valueWraps)
      newValue = [[self->minValue copy] autorelease];
    else
      newValue = [[self->maxValue copy] autorelease];
    result = ![self->_value isEqualToNumber:newValue];
    if (result)
      self.value = newValue;
  }//end if (![self->increment isEqualToNumber:@0])
  [super performDecrement];
  return result;
}
//end performIncrement

@end
