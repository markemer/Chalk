//
//  CHPresentationConfigurationEntity.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHPresentationConfigurationEntity.h"

#import "CHPresentationConfiguration.h"
#import "NSObjectExtended.h"

@implementation CHPresentationConfigurationEntity

@dynamic softFloatDisplayBits;
@dynamic softPrettyPrintEndNegativeExponent;
@dynamic softPrettyPrintEndPositiveExponent;
@dynamic base;
@dynamic baseUseLowercase;
@dynamic baseUseDecimalExponent;
@dynamic integerGroupSize;
@dynamic printOptions;

@dynamic presentationConfiguration;
@dynamic plist;

-(CHPresentationConfiguration*) presentationConfiguration
{
  return [CHPresentationConfiguration presentationConfigurationWithPlist:self.plist];
}
//end presentationConfiguration

-(void) setPresentationConfiguration:(CHPresentationConfiguration*)value
{
  self.plist = value.plist;
}
//end setPresentationConfiguration:

+(NSString*) entityName {return @"PresentationConfiguration";}

-(id) plist
{
  id result = [NSMutableDictionary dictionary];
  [result setValue:@(self.softFloatDisplayBits) forKey:@"softFloatDisplayBits"];
  [result setValue:@(self.softPrettyPrintEndNegativeExponent) forKey:@"softPrettyPrintEndNegativeExponent"];
  [result setValue:@(self.softPrettyPrintEndPositiveExponent) forKey:@"softPrettyPrintEndPositiveExponent"];
  [result setValue:@(self.base) forKey:@"base"];
  [result setValue:@(self.baseUseLowercase) forKey:@"baseUseLowercase"];
  [result setValue:@(self.baseUseDecimalExponent) forKey:@"baseUseDecimalExponent"];
  [result setValue:@(self.integerGroupSize) forKey:@"integerGroupSize"];
  [result setValue:@(self.printOptions) forKey:@"printOptions"];
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
  number = [[dict objectForKey:@"softPrettyPrintEndNegativeExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softPrettyPrintEndNegativeExponent = number.unsignedIntegerValue;
  number = [[dict objectForKey:@"softPrettyPrintEndPositiveExponent"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.softPrettyPrintEndPositiveExponent = number.unsignedIntegerValue;
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
    self.integerGroupSize = number.integerValue;
  number = [[dict objectForKey:@"printOptions"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.printOptions = number.integerValue;
}
//end setPlist:

@end
