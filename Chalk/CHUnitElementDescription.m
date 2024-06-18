//
//  CHUnitElementDescription.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUnitElementDescription.h"

#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHUnitElementDescription

@synthesize name;
@synthesize uid;
@dynamic    power;
@dynamic    isValid;

-(instancetype) initWithPlist:(id)plist
{
  NSDictionary* plistAsDict = [plist dynamicCastToClass:[NSDictionary class]];
  if (!plistAsDict)
  {
    [self release];
    return nil;
  }//end if (!plistAsDict)
  if (!((self = [super init])))
    return nil;
  mpq_init(self->power);
  mpq_set_si(self->power, 0, 1);
  self->name = [[[plistAsDict objectForKey:@"name"] dynamicCastToClass:[NSString class]] copy];
  NSNumber* power = [[plistAsDict objectForKey:@"power"] dynamicCastToClass:[NSNumber class]];
  mpq_set_si(self->power, [power longValue], 1);
  BOOL error = [NSString isNilOrEmpty:self->name] || !mpq_sgn(self->power);
  if (error)
  {
    [self release];
    return nil;
  }//end if (error)
  
  mpq_canonicalize(self->power);
  
  NSMutableString* string = [NSMutableString stringWithString:self->name];
  char* num = mpz_get_str(0, 10, mpq_numref(self->power));
  char* den = 0;
  BOOL isInteger = !mpz_cmp_si(mpq_denref(self->power), 1);
  if (isInteger)
    [string appendFormat:@"^%s", num];
  else//if (!isInteger)
  {
    den = mpz_get_str(0, 10, mpq_denref(self->power));
    [string appendFormat:@"^(%s/%s)", num, den];
  }//end if (!isInteger)
  self->uid = [string copy];
  free(num);
  free(den);
  
  return self;
}
//end initWithPlist:

-(void) dealloc
{
  [self->uid release];
  [self->name release];
  mpq_clear(self->power);
  [super dealloc];
}
//end dealloc

-(mpq_srcptr) power
{
  return self->power;
}
//end power

-(BOOL) isValid
{
  BOOL result = (mpq_sgn(self->power) != 0);
  return result;
}
//end isValid

-(void) addPower:(mpq_srcptr)otherPower
{
  mpq_add(self->power, self->power, otherPower);
}
//end addPower:

@end
