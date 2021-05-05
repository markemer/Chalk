//
//  CHComputationConfigurationEntity.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHComputationConfigurationEntity.h"

#import "CHComputationConfiguration.h"
#import "NSObjectExtended.h"

@implementation CHComputationConfigurationEntity

@dynamic softIntegerMaxBits;
@dynamic softIntegerDenominatorMaxBits;
@dynamic softFloatSignificandBits;
@dynamic computeMode;
@dynamic propagateNaN;
@dynamic baseDefault;

@dynamic computationConfiguration;
@dynamic plist;

+(NSString*) entityName {return @"ComputationConfiguration";}

-(CHComputationConfiguration*) computationConfiguration
{
  return [CHComputationConfiguration computationConfigurationWithPlist:self.plist];
}
//end computationConfiguration

-(void) setComputationConfiguration:(CHComputationConfiguration*)value
{
  self.plist = value.plist;
}
//end setComputationConfiguration:

-(id) plist
{
  id result = [NSMutableDictionary dictionary];
  [result setValue:@(self.softIntegerMaxBits) forKey:@"softIntegerMaxBits"];
  [result setValue:@(self.softIntegerDenominatorMaxBits) forKey:@"softIntegerDenominatorMaxBits"];
  [result setValue:@(self.softFloatSignificandBits) forKey:@"softFloatSignificandBits"];
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
  number = [[dict objectForKey:@"computeMode"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.computeMode = (chalk_compute_mode_t)number.intValue;
  number = [[dict objectForKey:@"propagateNaN"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.propagateNaN = number.boolValue;
  number = [[dict objectForKey:@"baseDefault"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.baseDefault = number.intValue;
}
//end setPlist:

@end
