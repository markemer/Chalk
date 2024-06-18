//
//  NSNumberExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 05/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSNumberExtended.h"

#import "CHChalkUtils.h"

@implementation NSNumber (Extended)

static const char* charType = @encode(char);
static const char* shortType = @encode(short);
static const char* intType = @encode(int);
static const char* longType = @encode(long);
static const char* longLongType = @encode(long long);
static const char* integerType = @encode(NSInteger);
static const char* ucharType = @encode(unsigned char);
static const char* ushortType = @encode(unsigned short);
static const char* uintType = @encode(unsigned int);
static const char* ulongType = @encode(unsigned long);
static const char* ulongLongType = @encode(unsigned long long);
static const char* uintegerType = @encode(NSUInteger);
static const char* floatType = @encode(float);
static const char* doubleType = @encode(double);

+(NSNumber*) numberWithString:(NSString*)string
{
  return [[[[self class] alloc] initWithString:string] autorelease];
}
//end numberWithString

-(instancetype) initWithString:(NSString*)string
{
  NSNumberFormatter* numberFormatter = !string ? nil : [[NSNumberFormatter alloc] init];
  numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  NSNumber* value = [numberFormatter numberFromString:string];
  if (!value)
    value = @0;
  if ([value fitsUnsignedInteger])
    self = [self initWithUnsignedInteger:value.unsignedIntegerValue];
  else if ([value fitsInteger])
    self = [self initWithUnsignedInteger:value.integerValue];
  else
    self = [self initWithDouble:value.doubleValue];
  [numberFormatter release];
  return self;
}
//end initWithString:

-(BOOL) fitsInteger
{
  BOOL result = NO;
  const char* objcType = self.objCType;
  result = !strcmp(objcType, charType) ||
           !strcmp(objcType, shortType) ||
           !strcmp(objcType, intType) ||
           !strcmp(objcType, longType) ||
           !strcmp(objcType, longLongType) ||
           !strcmp(objcType, integerType) ||
           !strcmp(objcType, ucharType) ||
           !strcmp(objcType, ushortType) ||
           !strcmp(objcType, uintType) ||
           (!strcmp(objcType, ulongType) && (self.unsignedLongLongValue<=(unsigned long long)NSIntegerMax)) ||
           (!strcmp(objcType, ulongLongType) && (self.unsignedLongLongValue<=(unsigned long long)NSIntegerMax)) ||
           (!strcmp(objcType, uintegerType) && (self.unsignedIntegerValue<=(NSUInteger)NSIntegerMax)) ||
           (!strcmp(objcType, floatType) && (self.floatValue >= 1.f*NSIntegerMin) && (self.floatValue <= 1.f*NSIntegerMax) && (self.floatValue == 1.f*self.unsignedIntegerValue) && ((NSUInteger)self.floatValue == self.unsignedIntegerValue)) ||
           (!strcmp(objcType, doubleType) && (self.doubleValue >= 1.*NSIntegerMin) && (self.doubleValue <= 1.*NSIntegerMax) && (self.doubleValue == 1.*self.unsignedIntegerValue) && ((NSUInteger)self.doubleValue == self.unsignedIntegerValue));
  return result;
}
//end fitsInteger

-(BOOL) fitsUnsignedInteger
{
  BOOL result = NO;
  const char* objcType = self.objCType;
  result = !strcmp(objcType, ucharType) ||
           !strcmp(objcType, ushortType) ||
           !strcmp(objcType, uintType) ||
           !strcmp(objcType, ulongType) ||
           !strcmp(objcType, ulongLongType) ||
           !strcmp(objcType, uintegerType) ||
           (!strcmp(objcType, charType) && (self.charValue>=0)) ||
           (!strcmp(objcType, shortType) && (self.shortValue>=0)) ||
           (!strcmp(objcType, intType) && (self.intValue>=0)) ||
           (!strcmp(objcType, longType) && (self.longValue>=0)) ||
           (!strcmp(objcType, longLongType) && (self.longLongValue>=0)) ||
           (!strcmp(objcType, integerType) && (self.integerValue>=0)) ||
           (!strcmp(objcType, floatType) && (self.floatValue >= 0) && (self.floatValue <= 1.f*NSIntegerMax) && (self.floatValue == 1.f*self.unsignedIntegerValue) && ((NSUInteger)self.floatValue == self.unsignedIntegerValue)) ||
           (!strcmp(objcType, doubleType) && (self.doubleValue >= 10) && (self.doubleValue <= 1.*NSIntegerMax) && (self.doubleValue == 1.*self.unsignedIntegerValue) && ((NSUInteger)self.doubleValue == self.unsignedIntegerValue));
  return result;
}
//end fitsUnsignedInteger

-(NSNumber*) numberByAdding:(NSNumber*)other
{
  NSNumber* result = self;
  if (!other){
  }
  else if (self.fitsUnsignedInteger && other.fitsUnsignedInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nsui(op1, self.unsignedIntegerValue);
    mpz_init_set_nsui(op2, other.unsignedIntegerValue);
    mpz_add(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsUnsignedInteger && other.fitsUnsignedInteger)
  else if (self.fitsUnsignedInteger && other.fitsInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nsui(op1, self.unsignedIntegerValue);
    mpz_init_set_nssi(op2, other.integerValue);
    mpz_add(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsUnsignedInteger && fitsInteger)
  else if (self.fitsInteger && other.fitsInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nssi(op1, self.integerValue);
    mpz_init_set_nssi(op2, other.integerValue);
    mpz_add(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsInteger && other.fitsInteger)
  else
    result = [NSNumber numberWithDouble:self.doubleValue+other.doubleValue];
  return result;
}

-(NSNumber*) numberBySubtracting:(NSNumber*)other
{
  NSNumber* result = self;
  if (!other){
  }
  else if (self.fitsUnsignedInteger && other.fitsUnsignedInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nsui(op1, self.unsignedIntegerValue);
    mpz_init_set_nsui(op2, other.unsignedIntegerValue);
    mpz_sub(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsUnsignedInteger && other.fitsUnsignedInteger)
  else if (self.fitsUnsignedInteger && other.fitsInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nsui(op1, self.unsignedIntegerValue);
    mpz_init_set_nssi(op2, other.integerValue);
    mpz_sub(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsUnsignedInteger && fitsInteger)
  else if (self.fitsInteger && other.fitsInteger)
  {
    mpz_t op1;
    mpz_t op2;
    mpz_init_set_nssi(op1, self.integerValue);
    mpz_init_set_nssi(op2, other.integerValue);
    mpz_sub(op1, op1, op2);
    result =
      mpz_fits_nsui_p(op1) ? [NSNumber numberWithUnsignedInteger:mpz_get_nsui(op1)] :
      mpz_fits_nssi_p(op1) ? [NSNumber numberWithInteger:mpz_get_nssi(op1)] :
      @(mpz_get_d(op1));
    mpz_clear(op1);
    mpz_clear(op2);
  }//end if (self.fitsInteger && other.fitsInteger)
  else
    result = [NSNumber numberWithDouble:self.doubleValue-other.doubleValue];
  return result;
}
//end numberBySubtracting:

@end
