//
//  CHUnitElement.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUnitElement.h"

#import "CHUnitElementDescription.h"
#import "NSStringExtended.h"
#import "NSObjectExtended.h"

@implementation CHUnitElement

@synthesize name;
@dynamic    power;
@dynamic    powerAsString;
@dynamic    isValid;

-(instancetype) initWithDescription:(CHUnitElementDescription*)description
{
  if (!description)
  {
    [self release];
    return nil;
  }//end if (!description)
  if (!((self = [super init])))
    return nil;
  self->name = [description.name copy];
  mpq_init(self->power);
  mpq_set(self->power, description.power);
  BOOL error = [NSString isNilOrEmpty:self->name] || !mpq_sgn(self->power);
  if (error)
  {
    [self release];
    return nil;
  }//end if (error)
  
  mpq_canonicalize(self->power);
 
  return self;
}
//end initWithPlist:

-(void) dealloc
{
  [self->name release];
  mpq_clear(self->power);
  [self->powerAsString_cached release];
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

-(NSString*) powerAsString
{
  NSString* result = [[self->powerAsString_cached copy] autorelease];
  if (!result)
  {
    NSMutableString* stringBuilder = [NSMutableString string];
    BOOL isZero = !mpq_cmp_si(self->power, 0, 1);
    if (!isZero)
    {
      BOOL isOne = !mpq_cmp_si(self->power, 1, 1);
      if (!isOne)
      {
        char* s = 0;
        s = mpz_get_str(0, 10, mpq_numref(self->power));
        [stringBuilder appendFormat:@"%s", s];
        free(s);
        BOOL isFraction = (mpz_cmp_si(mpq_denref(self->power), 1) != 0);
        if (isFraction)
        {
          [stringBuilder appendString:@"/"];
          s = mpz_get_str(0, 10, mpq_denref(self->power));
          [stringBuilder appendFormat:@"%s", s];
          free(s);
        }//end if (isFraction)
      }//end if (!isOne)
    }//end if (!isZero)
    [self->powerAsString_cached release];
    self->powerAsString_cached = [stringBuilder copy];
    result = [[self->powerAsString_cached copy] autorelease];
  }//end if (!result)
  return result;
}
//end powerAsString

@end
