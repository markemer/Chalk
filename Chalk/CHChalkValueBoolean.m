//
//  CHChalkValueBoolean.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueBoolean.h"

#import "CHChalkContext.h"
#import "CHChalkToken.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueBoolean

@synthesize chalkBoolValue;

+(BOOL) supportsSecureCoding {return YES;}

+(CHChalkValueBoolean*) noValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] chalkBoolValue:CHALK_BOOL_NO context:nil] autorelease];
}
//end noValue

+(CHChalkValueBoolean*) unlikelyValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] chalkBoolValue:CHALK_BOOL_UNLIKELY context:nil] autorelease];
}
//end unlikelyValue

+(CHChalkValueBoolean*) maybeValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] chalkBoolValue:CHALK_BOOL_MAYBE context:nil] autorelease];
}
//end maybeValue

+(CHChalkValueBoolean*) certainlyValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] chalkBoolValue:CHALK_BOOL_CERTAINLY context:nil] autorelease];
}
//end certainlyValue

+(CHChalkValueBoolean*) yesValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] chalkBoolValue:CHALK_BOOL_YES context:nil] autorelease];
}
//end yesValue

-(instancetype) initWithToken:(CHChalkToken*)aToken chalkBoolValue:(chalk_bool_t)aChalkBoolValue context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->chalkBoolValue = aChalkBoolValue;
  return self;
}
//end initWithToken:chalkBoolValue:context:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->chalkBoolValue = (chalk_bool_t)[aDecoder decodeInt32ForKey:@"chalkBoolValue"];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt32:(int)self->chalkBoolValue forKey:@"chalkBoolValue"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueBoolean* result = [super copyWithZone:zone];
  if (result)
    result->chalkBoolValue = self->chalkBoolValue;
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueBoolean* dstBoolean = !result ? nil : [dst dynamicCastToClass:[CHChalkValueBoolean class]];
  if (result && dstBoolean)
    dstBoolean->chalkBoolValue = self->chalkBoolValue;
  return result;
}
//end moveTo:

-(BOOL) isTerminal
{
  return YES;
}
//end isTerminal

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  switch(self->chalkBoolValue)
  {
    case CHALK_BOOL_NO:
      [stream writeString:NSLocalizedString(@"No", @"")];
      break;
    case CHALK_BOOL_UNLIKELY:
      [stream writeString:NSLocalizedString(@"Unlikely", @"")];
      break;
    case CHALK_BOOL_MAYBE:
      [stream writeString:NSLocalizedString(@"Maybe", @"")];
      break;
    case CHALK_BOOL_CERTAINLY:
      [stream writeString:NSLocalizedString(@"Certainly", @"")];
      break;
    case CHALK_BOOL_YES:
      [stream writeString:NSLocalizedString(@"Yes", @"")];
      break;
  }//end switch(self->chalkBoolValue)
}
//end writeBodyToStream:context:options:

-(void) logicalNot
{
  self->chalkBoolValue = chalkBoolNot(self->chalkBoolValue);
}
//end logicalNot

@end
