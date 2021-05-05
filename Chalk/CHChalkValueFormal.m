//
//  CHChalkValueFormal.m
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueFormal.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueFormal

@synthesize baseValue;
@synthesize value;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->baseValue = [[aDecoder decodeObjectOfClass:[CHChalkValueNumberGmp class] forKey:@"baseValue"] retain];
  self->value = [[aDecoder decodeObjectOfClass:[CHChalkValueNumberGmp class] forKey:@"value"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->baseValue forKey:@"baseValue"];
  [aCoder encodeObject:self->value forKey:@"value"];
}
//end encodeWithCoder:

-(void)dealloc
{
  [self->baseValue release];
  [self->value release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  id result = [super copyWithZone:zone];
  CHChalkValueFormal* clone = [result dynamicCastToClass:[CHChalkValueFormal class]];
  if (!clone)
    [result release];
  else//if (clone)
  {
    clone.baseValue = self->baseValue;
    clone.value = self->value;
  }//end if (clone)
  return result;
}
//end copyWithZone:

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
}
//end adaptToComputeMode:context:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
}
//end writeBodyToStream:context:presentationConfiguration:

@end
