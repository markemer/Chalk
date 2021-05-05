//
//  CHComputationConfiguration.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHComputationConfiguration.h"

#import "CHPreferencesController.h"
#import "NSObjectExtended.h"

@implementation CHComputationConfiguration

@synthesize softIntegerMaxBits;
@synthesize softIntegerDenominatorMaxBits;
@synthesize softFloatSignificandBits;
@synthesize softMaxExponent;
@synthesize computeMode;
@synthesize propagateNaN;
@synthesize baseDefault;

@dynamic plist;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) computationConfigurationWithPlist:(id)plist
{
  return [[[[self class] alloc] initWithPlist:plist] autorelease];
}
//end computationConfigurationWithPlist:

+(instancetype) computationConfiguration
{
  return [[[[self class] alloc] init] autorelease];
}
//end computationConfiguration

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  [self reset];
  return self;
}
//end init

-(instancetype) initWithPlist:(id)plist
{
  if (!((self = [self init])))
    return nil;
  self.plist = plist;
  return self;
}
//end initWithPlist:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super init])))
    return nil;
  self->softIntegerMaxBits =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softIntegerMaxBits"] unsignedIntegerValue];
  self->softIntegerDenominatorMaxBits =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softIntegerDenominatorMaxBits"] unsignedIntegerValue];
  self->softFloatSignificandBits =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softFloatSignificandBits"] unsignedIntegerValue];
  self->softMaxExponent =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softMaxExponent"] unsignedIntegerValue];
  self->computeMode =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"computeMode"] unsignedIntegerValue];
  self->propagateNaN =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"propagateNaN"] boolValue];
  self->baseDefault =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"baseDefault"] intValue];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:@(self->softIntegerMaxBits) forKey:@"softIntegerMaxBits"];
  [aCoder encodeObject:@(self->softIntegerDenominatorMaxBits) forKey:@"softIntegerDenominatorMaxBits"];
  [aCoder encodeObject:@(self->softFloatSignificandBits) forKey:@"softFloatSignificandBits"];
  [aCoder encodeObject:@(self->softMaxExponent) forKey:@"softMaxExponent"];
  [aCoder encodeObject:@(self->computeMode) forKey:@"computeMode"];
  [aCoder encodeObject:@(self->propagateNaN) forKey:@"propagateNaN"];
  [aCoder encodeObject:@(self->baseDefault) forKey:@"baseDefault"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHComputationConfiguration* result = [[[self class] alloc] init];
  if (result)
  {
    result->softIntegerMaxBits = self->softIntegerMaxBits;
    result->softIntegerDenominatorMaxBits = self->softIntegerDenominatorMaxBits;
    result->softFloatSignificandBits = self->softFloatSignificandBits;
    result->softMaxExponent = self->softMaxExponent;
    result->computeMode = self->computeMode;
    result->propagateNaN = self->propagateNaN;
    result->baseDefault = self->baseDefault;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) reset
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self->softIntegerMaxBits =
    !preferencesController ? 64 : preferencesController.softIntegerMaxBits;
  self->softIntegerDenominatorMaxBits =
    !preferencesController ? self->softIntegerMaxBits : preferencesController.softIntegerDenominatorMaxBits;
  self->softFloatSignificandBits =
    !preferencesController ? 53 : preferencesController.softFloatSignificandBits;
  self->softMaxExponent = mpfr_get_emax();
  self->computeMode = CHALK_COMPUTE_MODE_EXACT;
  self->propagateNaN = !preferencesController ? NO : preferencesController.propagateNaN;
  self->baseDefault = 10;
}
//end reset

-(id) plist
{
  id result = [NSMutableDictionary dictionary];
  [result setValue:@(self.softIntegerMaxBits) forKey:@"softIntegerMaxBits"];
  [result setValue:@(self.softIntegerDenominatorMaxBits) forKey:@"softIntegerDenominatorMaxBits"];
  [result setValue:@(self.softFloatSignificandBits) forKey:@"softFloatSignificandBits"];
  [result setValue:@(self.softMaxExponent) forKey:@"softMaxExponent"];
  [result setValue:@(self.computeMode) forKey:@"computeMode"];
  [result setValue:@(self.propagateNaN) forKey:@"propagateNaN"];
  [result setValue:@(self.baseDefault) forKey:@"baseDefault"];
  return [[result copy] autorelease];
}
//end plist

-(void) setPlist:(id)plist
{
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSNumber* number = nil;
  number = [[dict objectForKey:@"softIntegerMaxBits"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softIntegerMaxBits = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softIntegerDenominatorMaxBits"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softIntegerDenominatorMaxBits = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softFloatSignificandBits"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softFloatSignificandBits = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softMaxExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softMaxExponent = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"computeMode"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.computeMode = (chalk_compute_mode_t)number.unsignedIntegerValue;
  number = [[dict objectForKey:@"propagateNaN"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.propagateNaN = number.boolValue;
  number = [[dict objectForKey:@"baseDefault"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.baseDefault = number.intValue;
  number = [[dict objectForKey:@"baseUseLowercase"] dynamicCastToClass:[NSNumber class]];
}
//end setPlist:

-(BOOL) isEqualTo:(id)object
{
  BOOL result = (object == self);
  if (!result)
  {
    CHComputationConfiguration* other = [object dynamicCastToClass:[CHComputationConfiguration class]];
    result = other && [self.plist isEqualTo:other.plist];
  }//end if (!result)
  return result;
}
//end isEqualTo:

-(NSString*) debugDescription
{
  NSString* result = [self.plist debugDescription];
  return result;
}
//end debugDescription

@end
