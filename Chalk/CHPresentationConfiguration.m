//
//  CHPresentationConfiguration.m
//  Chalk
//
//  Created by Pierre Chatelier on 20/03/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHPresentationConfiguration.h"

#import "CHPreferencesController.h"

#import "NSObjectExtended.h"

@implementation CHPresentationConfiguration

@synthesize softFloatDisplayBits;
@synthesize softMaxPrettyPrintNegativeExponent;
@synthesize softMaxPrettyPrintPositiveExponent;
@synthesize base;
@synthesize baseUseLowercase;
@synthesize baseUseDecimalExponent;
@synthesize integerGroupSize;
@synthesize description;
@synthesize printOptions;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) presentationConfigurationWithDescription:(chalk_value_description_t)description
{
  return [[[[self class] alloc] initWithDescription:description] autorelease];
}
//end presentationConfigurationWithDescription:

+(instancetype) presentationConfigurationWithPlist:(id)plist
{
  return [[[[self class] alloc] initWithPlist:plist] autorelease];
}
//end presentationConfigurationWithDescription:

+(instancetype) presentationConfiguration
{
  return [self presentationConfigurationWithDescription:CHALK_VALUE_DESCRIPTION_STRING];
}
//end presentationConfiguration

-(instancetype) initWithDescription:(chalk_value_description_t)aDescription
{
  if (!((self = [super init])))
    return nil;
  [self reset];
  self->description = aDescription;
  return self;
}
//end initWithDescription:

-(instancetype) initWithPlist:(id)plist
{
  if (!((self = [self initWithDescription:CHALK_VALUE_DESCRIPTION_STRING])))
    return nil;
  self.plist = plist;
  return self;
}
//end initWithPlist:

-(instancetype) init
{
  return [self initWithDescription:CHALK_VALUE_DESCRIPTION_STRING];
}
//end init

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super init])))
    return nil;
  self->softFloatDisplayBits =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softFloatDisplayBits"] unsignedIntegerValue];
  self->softMaxPrettyPrintPositiveExponent =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softMaxPrettyPrintPositiveExponent"] unsignedIntegerValue];
  self->softMaxPrettyPrintNegativeExponent =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"softMaxPrettyPrintNegativeExponent"] unsignedIntegerValue];
  self->base =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"base"] intValue];
  self->baseUseLowercase =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"baseUseLowercase"] boolValue];
  self->baseUseDecimalExponent =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"baseUseDecimalExponent"] boolValue];
  self->integerGroupSize =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"integerGroupSize"] integerValue];
  self->description =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"description"] unsignedIntegerValue];
  self->printOptions =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"printOptions"] unsignedIntegerValue];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:@(self->softFloatDisplayBits) forKey:@"softFloatDisplayBits"];
  [aCoder encodeObject:@(self->softMaxPrettyPrintPositiveExponent) forKey:@"softMaxPrettyPrintPositiveExponent"];
  [aCoder encodeObject:@(self->softMaxPrettyPrintNegativeExponent) forKey:@"softMaxPrettyPrintNegativeExponent"];
  [aCoder encodeObject:@(self->base) forKey:@"base"];
  [aCoder encodeObject:@(self->baseUseLowercase) forKey:@"baseUseLowercase"];
  [aCoder encodeObject:@(self->baseUseDecimalExponent) forKey:@"baseUseDecimalExponent"];
  [aCoder encodeObject:@(self->integerGroupSize) forKey:@"integerGroupSize"];
  [aCoder encodeObject:@(self->description) forKey:@"description"];
  [aCoder encodeObject:@(self->printOptions) forKey:@"printOptions"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHPresentationConfiguration* result = [[[self class] alloc] init];
  if (result)
  {
    result->softFloatDisplayBits = self->softFloatDisplayBits;
    result->softMaxPrettyPrintPositiveExponent = self->softMaxPrettyPrintPositiveExponent;
    result->softMaxPrettyPrintNegativeExponent = self->softMaxPrettyPrintNegativeExponent;
    result->base = self->base;
    result->baseUseLowercase = self->baseUseLowercase;
    result->baseUseDecimalExponent = self->baseUseDecimalExponent;
    result->integerGroupSize = self->integerGroupSize;
    result->description = self->description;
    result->printOptions = self->printOptions;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) reset
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self->softFloatDisplayBits =
    !preferencesController ? self->softFloatDisplayBits : preferencesController.softFloatDisplayBits;
  self->softMaxPrettyPrintNegativeExponent = 4;
  self->softMaxPrettyPrintPositiveExponent = 6;
  self->base = 10;
  self->baseUseLowercase = NO;
  self->baseUseDecimalExponent = NO;
  self->integerGroupSize = 0;
  self->description = CHALK_VALUE_DESCRIPTION_STRING;
  self->printOptions = CHALK_VALUE_PRINT_OPTION_NONE;
}
//end reset

-(id) plist
{
  id result = [NSMutableDictionary dictionary];
  [result setValue:@(self.softFloatDisplayBits) forKey:@"softFloatDisplayBits"];
  [result setValue:@(self.softMaxPrettyPrintNegativeExponent) forKey:@"softMaxPrettyPrintNegativeExponent"];
  [result setValue:@(self.softMaxPrettyPrintPositiveExponent) forKey:@"softMaxPrettyPrintPositiveExponent"];
  [result setValue:@(self->base) forKey:@"base"];
  [result setValue:@(self.baseUseLowercase) forKey:@"baseUseLowercase"];
  [result setValue:@(self.baseUseDecimalExponent) forKey:@"baseUseDecimalExponent"];
  [result setValue:@(self->integerGroupSize) forKey:@"integerGroupSize"];
  [result setValue:@(self->description) forKey:@"description"];
  [result setValue:@(self->printOptions) forKey:@"printOptions"];
  return [[result copy] autorelease];
}
//end plist

-(void) setPlist:(id)plist
{
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSNumber* number = nil;
  number = [[dict objectForKey:@"softFloatDisplayBits"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softFloatDisplayBits = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softMaxPrettyPrintNegativeExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softMaxPrettyPrintNegativeExponent = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softMaxPrettyPrintPositiveExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softMaxPrettyPrintPositiveExponent = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"base"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.base = number.intValue;
  number = [[dict objectForKey:@"baseUseLowercase"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.baseUseLowercase = number.boolValue;
  number = [[dict objectForKey:@"baseUseDecimalExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.baseUseDecimalExponent = number.boolValue;
  number = [[dict objectForKey:@"integerGroupSize"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self->integerGroupSize = number.integerValue;
  number = [[dict objectForKey:@"description"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self->description = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"printOptions"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self->printOptions = number.unsignedIntegerValue;
}
//end setPlist:

-(BOOL) isEqualTo:(id)object
{
  BOOL result = (object == self);
  if (!result)
  {
    CHPresentationConfiguration* other = [object dynamicCastToClass:[CHPresentationConfiguration class]];
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
