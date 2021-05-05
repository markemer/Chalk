//
//  CHChalkUtils.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#include "CHChalkUtils.h"

#include "CHChalkContext.h"
#include "CHGmpPool.h"
#include "CHUtils.h"

#include "NSDataExtended.h"
#include "NSNumberExtended.h"
#include "NSObjectExtended.h"
#include "NSStringExtended.h"
#import "NSStringExtended.h"

const NSInteger GMP_BASE_MIN = 2;
const NSInteger GMP_BASE_MAX = 36;
const NSString* NSSTRING_PI = @"\u03C0";
const NSString* NSSTRING_INFINITY = @"\u221E";
const NSString* NSSTRING_ELLIPSIS = @"\u2026";
const NSString* NSSTRING_PLUSMINUS = @"\u00B1";
const NSString* NSSTRING_UNBREAKABLE_SPACE = @"\u00A0";

static const mp_bitcnt_t MP_BITCNT_MAX = (mp_bitcnt_t)(-1);
static const mp_limb_t   MP_LIMB_MAX   = (mp_limb_t)(-1);
static const mp_limb_t   MP_LIMB_ONE   = (mp_limb_t)(1);

/*CG_INLINE mp_limb_t reverseLimb(mp_limb_t x)
{
  mp_limb_t result = 0;
  size_t count = mp_bits_per_limb;
  while(count--)
  {
    result <<= 1U;
    result &= x&((mp_limb_t)0x1);
    x >>= 1U;
  }//end while(count--)
  return result;
}
//end reverseLimb()*/

void mpn_print2(const mp_limb_t* limbs, size_t count)
{
  while(count--)
  {
    mp_limb_t limb = limbs[count];
    mp_limb_t mask = 1ULL<<(mp_bits_per_limb-1);
    while(mask)
    {
      printf("%c", !(limb&mask) ? '0' : '1');
      mask >>= 1;
    }
    printf(" ");
  }
  printf("\n\n");
}

BOOL isPowerOfTwo(NSUInteger x)
{
  BOOL result = x && !(x & (x-1));
  return result;
}
//end isPowerOfTwo()

NSUInteger nextPowerOfTwo(NSUInteger x, BOOL strict)
{
  NSUInteger result = x;
  const NSUInteger one = 1UL;
  BOOL isAlreadyPowerOfTwo = isPowerOfTwo(x);
  if (!x)
    result = one;
  else if (isAlreadyPowerOfTwo && strict)
    result <<= one;
  else if (!isAlreadyPowerOfTwo)
  {
    NSUInteger count = one;
    while(x >>= one)
      ++count;
    result = one<<count;
  }//end if (!isAlreadyPowerOfTwo)
  return result;
}
//end nextPowerOfTwo()

NSUInteger prevPowerOfTwo(NSUInteger x, BOOL strict)
{
  NSUInteger result = x;
  const NSUInteger one = 1UL;
  BOOL isAlreadyPowerOfTwo = isPowerOfTwo(x);
  if (!x)
    result = one;
  else if (isAlreadyPowerOfTwo && strict)
    result >>= one;
  else if (!isAlreadyPowerOfTwo)
  {
    NSUInteger count = 0;
    while(x >>= one)
      ++count;
    result = one<<count;
  }//end if (!isAlreadyPowerOfTwo)
  return result;
}
//end pevPowerOfTwo()

NSUInteger getPowerOfTwo(NSUInteger x)
{
  NSUInteger result = 0;
  if (isPowerOfTwo(x))
  {
    while((x >>= 1))
      ++result;
  }//end if (isPowerOfTwo(x))
  return result;
}
//end getPowerOfTwo()

static mp_limb_t* mpz_limbs_modify_safe(mpz_ptr op, mp_size_t count)
{
  mp_limb_t* result = 0;
  if ((count <= ULONG_MAX / GMP_NUMB_BITS) && (count <= INT_MAX))
    result = mpz_limbs_modify(op, count);
  return result;
}

mp_bitcnt_t mpz_scan1_r(mpz_srcptr op, mp_bitcnt_t starting_bit)
{
  mp_bitcnt_t result = MP_BITCNT_MAX;
  const mp_limb_t* srcLimbs = !op ? 0 : mpz_limbs_read(op);
  if (srcLimbs)
  {
    if (mpz_cmp_ui(op, 0) != 0)
    {
      size_t limbsCount = mpz_size(op);
      if (starting_bit >= limbsCount*mp_bits_per_limb)
        result = mpz_sizeinbase(op, 2)-1;
      else//if (starting_bit < limbsCount*mp_bits_per_limb)
      {
        size_t startLimbIndex = MIN(limbsCount, starting_bit/mp_bits_per_limb+1);
        size_t currentLimbIndex = startLimbIndex;
        while((result == MP_BITCNT_MAX) && currentLimbIndex--)
        {
          const mp_limb_t limb = srcLimbs[currentLimbIndex];
          if (limb)
          {
            mp_limb_t localMaskIndex = (currentLimbIndex+1 == startLimbIndex) ? (starting_bit%mp_bits_per_limb) :
              (mp_bits_per_limb-1);
            mp_limb_t mask = ((mp_limb_t)1UL)<<localMaskIndex;
            while(mask && !(mask & localMaskIndex))
            {
              mask >>= 1UL;
              --localMaskIndex;
            }//end while(mask && !(mask & localMaskIndex))
            if (mask)
              result = currentLimbIndex*mp_bits_per_limb+localMaskIndex;
          }//end if (limb)
        }//end while((result == MP_BITCNT_MAX) && currentLimbIndex--)
      }//end if (starting_bit < limbsCount*mp_bits_per_limb)
    }//end if (mpz_cmp_ui(op, 0) != 0)
  }//end if (srcLimbs)
  mpz_limbs_read(op);
  return result;
}
//end mpz_scan1_r()

void mpzCopy(mpz_ptr dst, __mpz_struct src)    {memcpy(dst, &src, sizeof(src));}
void mpqCopy(mpq_ptr dst, __mpq_struct src)    {memcpy(dst, &src, sizeof(src));}
void mpfrCopy(mpfr_ptr dst, __mpfr_struct src) {memcpy(dst, &src, sizeof(src));}
void mpfiCopy(mpfi_ptr dst, __mpfi_struct src) {memcpy(dst, &src, sizeof(src));}
void mpfirCopy(mpfir_ptr dst, __mpfir_struct src) {memcpy(dst, &src, sizeof(src));}
void arbCopy(arb_ptr dst, arb_struct src) {memcpy(dst, &src, sizeof(src));}
void mpzDepool(mpz_ptr dst, CHGmpPool* pool) {if (!pool) mpz_init(dst); else mpzCopy(dst, [pool depoolMpz]);}
void mpqDepool(mpq_ptr dst, CHGmpPool* pool) {if (!pool) mpq_init(dst); else mpqCopy(dst, [pool depoolMpq]);}
void mpfrDepool(mpfr_ptr dst, mpfr_prec_t prec, CHGmpPool* pool) {if (!pool) mpfr_init2(dst, prec); else mpfrCopy(dst, [pool depoolMpfr:prec]);}
void mpfiDepool(mpfi_ptr dst, mpfr_prec_t prec, CHGmpPool* pool) {if (!pool) mpfi_init2(dst, prec); else mpfiCopy(dst, [pool depoolMpfi:prec]);}
void mpfirDepool(mpfir_ptr dst, mpfr_prec_t prec, CHGmpPool* pool) {if (!pool) mpfir_init2(dst, prec); else mpfirCopy(dst, [pool depoolMpfir:prec]);}
void arbDepool(arb_ptr dst, CHGmpPool* pool) {if (!pool) arb_init(dst); else arbCopy(dst, [pool depoolArb]);}
void mpzRepool(mpz_ptr dst, CHGmpPool* pool) {if (!pool) mpz_clear(dst); else [pool repoolMpz:dst];}
void mpqRepool(mpq_ptr dst, CHGmpPool* pool) {if (!pool) mpq_clear(dst); else [pool repoolMpq:dst];}
void mpfrRepool(mpfr_ptr dst, CHGmpPool* pool) {if (!pool) mpfr_clear(dst); else [pool repoolMpfr:dst];}
void mpfiRepool(mpfi_ptr dst, CHGmpPool* pool) {if (!pool) mpfi_clear(dst); else [pool repoolMpfi:dst];}
void mpfirRepool(mpfir_ptr dst, CHGmpPool* pool) {if (!pool) mpfir_clear(dst); else [pool repoolMpfir:dst];}
void arbRepool(arb_ptr dst, CHGmpPool* pool) {if (!pool) arb_clear(dst); else [pool repoolArb:dst];}

BOOL chalkBoolIsCertain(chalk_bool_t value)
{
  BOOL result = (value == CHALK_BOOL_NO) || (value == CHALK_BOOL_YES);
  return result;
}
//end chalkBoolIsCertain()

chalk_bool_t chalkBoolNot(chalk_bool_t value)
{
  chalk_bool_t result = value;
  switch(value)
  {
    case CHALK_BOOL_NO:        result = CHALK_BOOL_YES;       break;
    case CHALK_BOOL_UNLIKELY:  result = CHALK_BOOL_CERTAINLY; break;
    case CHALK_BOOL_MAYBE:     result = CHALK_BOOL_MAYBE;     break;
    case CHALK_BOOL_CERTAINLY: result = CHALK_BOOL_UNLIKELY;  break;
    case CHALK_BOOL_YES:       result = CHALK_BOOL_NO;        break;
  }//end switch(value)
  return result;
}
//end chalkBoolNot()

chalk_bool_t chalkBoolAnd(chalk_bool_t op1, chalk_bool_t op2)
{
  chalk_bool_t result = (chalk_bool_t)(MIN((NSUInteger)op1,(NSUInteger)op2));
  return result;
}
//end chalkBoolAnd()

chalk_bool_t chalkBoolOr(chalk_bool_t op1, chalk_bool_t op2)
{
  chalk_bool_t result = (chalk_bool_t)(MAX((NSUInteger)op1,(NSUInteger)op2));
  return result;
}
//end chalkBoolOr()

chalk_bool_t chalkBoolXor(chalk_bool_t op1, chalk_bool_t op2)
{
  chalk_bool_t result =
    chalkBoolOr(
      chalkBoolAnd(op1, chalkBoolNot(op2)),
      chalkBoolAnd(chalkBoolNot(op1), op2)
    );
  return result;
}
//end chalkBoolXor()

chalk_bool_t chalkBoolCombine(chalk_bool_t op1, chalk_bool_t op2)
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  chalk_bool_t inf = MIN(op1, op2);
  chalk_bool_t sup = MAX(op1, op2);
  if (inf >= CHALK_BOOL_MAYBE)
    result = inf;
  else if (sup <= CHALK_BOOL_MAYBE)
    result = sup;
  else
    result = CHALK_BOOL_MAYBE;
  return result;
}
//end chalkBoolCombine()

BOOL chalkDigitsMatchBase(NSString* digits, NSRange range, int base, BOOL allowSpace, NSIndexSet** outFailures)
{
  BOOL result = NO;
  NSMutableIndexSet* failures = nil;
  NSString* input = [digits substringWithRange:range];
  if ([NSString isNilOrEmpty:input])
    result = YES;
  else//if (![NSString isNilOrEmpty:suffix])
  {
    NSCharacterSet* allowedCharacters = chalkGmpGetCharacterSetForBase(base);
    if (allowSpace)
    {
      NSMutableCharacterSet* allowedCharactersMutable = [[[NSMutableCharacterSet alloc] init] autorelease];
      [allowedCharactersMutable formUnionWithCharacterSet:allowedCharacters];
      [allowedCharactersMutable formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
      allowedCharacters = allowedCharactersMutable;
    }//end if (allowSpace)
    NSCharacterSet* disallowedCharacters = !allowedCharacters ? nil : [allowedCharacters invertedSet];
    NSUInteger firstFailureLocation = !disallowedCharacters ? NSNotFound : [input rangeOfCharacterFromSet:disallowedCharacters].location;
    result = (firstFailureLocation == NSNotFound);
    NSUInteger currentFailureLocation = firstFailureLocation;
    if (!result && outFailures)
    {
      failures = [NSMutableIndexSet indexSet];
      while(currentFailureLocation != NSNotFound)
      {
        NSRange endRange = NSMakeRange(currentFailureLocation, input.length-currentFailureLocation);
        NSUInteger nextNonFailureLocation = [input rangeOfCharacterFromSet:allowedCharacters options:0 range:endRange].location;
        NSRange nextFailure =
          (nextNonFailureLocation == NSNotFound) ? endRange :
          NSMakeRange(currentFailureLocation, nextNonFailureLocation-currentFailureLocation);
        [failures addIndexesInRange:nextFailure];
        currentFailureLocation = (nextNonFailureLocation == NSNotFound) ? NSNotFound :
          [input rangeOfCharacterFromSet:disallowedCharacters options:0 range:NSMakeRange(nextNonFailureLocation, input.length-nextNonFailureLocation)].location;
      }//end while(currentFailureLocation != NSNotFound)
    }//end if (!result && outFirstFailure)
    [failures shiftIndexesStartingAtIndex:0 by:range.location];
  }//end if (![NSString isNilOrEmpty:suffix])
  if (outFailures)
    *outFailures = [[failures copy] autorelease];
  return result;
}
//end chalkDigitsMatchBase()

BOOL chalkGmpBaseIsValid(int base)
{
  BOOL result = NSIntegerBetween(GMP_BASE_MIN, base, GMP_BASE_MAX);
  return result;
}
//end chalkGmpBaseIsValid()

int chalkGmpBaseMakeValid(int base)
{
  int result = chalkGmpBaseIsValid(base) ? base : 10;
  return result;
}
//end chalkGmpBaseMakeValid()

BOOL chalkGmpBaseIsValidPrefix(NSString* value) {return chalkGmpBaseIsValidSuffix(value);}
BOOL chalkGmpBaseIsValidSuffix(NSString* value)
{
  BOOL result = [value isMatchedByRegex:@"([0-9a-zA-Z#&_$]*[a-zA-Z#&_$]+)+"];
  return result;
}
//end chalkGmpBaseIsValidSuffix()

int mpn_zero_range_p(const mp_limb_t* limbs, size_t limbsCount, NSRange bitsRange)
{
  int result = 1;
  if (limbs && limbsCount && bitsRange.length)
  {
    NSUInteger firstRangeIndex = (bitsRange.location+mp_bits_per_limb-1)/mp_bits_per_limb;
    NSUInteger endRangeIndex = (NSMaxRange(bitsRange)+mp_bits_per_limb-1)/mp_bits_per_limb;
    for(NSUInteger i = firstRangeIndex ; result && (i<MIN(endRangeIndex, limbsCount)) ; ++i)
    {
      mp_limb_t limb = *limbs++;
      NSRange limbRange = NSMakeRange(i*mp_bits_per_limb, mp_bits_per_limb);
      NSRange interestingLimbRange = NSIntersectionRange(limbRange, bitsRange);
      NSRange maskRange = NSMakeRange(interestingLimbRange.location%mp_bits_per_limb, interestingLimbRange.length);
      mp_limb_t mask =
        !maskRange.length ? 0 :
        (maskRange.length == mp_bits_per_limb) ? MP_LIMB_MAX :
        (((MP_LIMB_ONE<<maskRange.length)-1)<<maskRange.location);
      result &= !(limb & mask) ? 1 : 0;
    }//end for each range
  }//end if (limbs && limbsCount && bitsRange.length)
  return result;
}
//end mpn_zero_range_p()

void mpn_set_zero(mp_limb_t* limbs, size_t limbsCount)
{
  if (limbs)
    memset(limbs, 0, limbsCount*sizeof(mp_limb_t));
}
//end mpn_set_zero()

mp_bitcnt_t mpn_rscan1(const mp_limb_t* limbs, size_t limbsCount)
{
  mp_bitcnt_t result = limbsCount*mp_bits_per_limb;
  size_t currentLimbIndex = limbsCount;
  const mp_limb_t* currentLimb = limbs+currentLimbIndex;
  while(currentLimbIndex--)
  {
    mp_limb_t limb = *(--currentLimb);
    if (limb != 0)
    {
      for(mp_bitcnt_t i = 0 ; i<mp_bits_per_limb ; ++i, limb >>= 1)
      {
        if ((limb & 0x1) != 0)
          result = i;
      }
      result += currentLimbIndex*mp_bits_per_limb;
      break;
    }//end if (limb != 0)
  }//end while(currentLimbIndex--)
  return result;
}
//end mpn_rscan1()

mp_bitcnt_t mpn_rscan1_range(const mp_limb_t* limbs, size_t limbsCount, NSRange bitsRange)
{
  mp_bitcnt_t result = 0;
  NSRange maxRange = NSMakeRange(0, limbsCount*mp_bits_per_limb);
  NSRange safeRange = NSIntersectionRange(bitsRange, maxRange);
  result = NSMaxRange(safeRange);
  if (safeRange.length > 0)
  {
    size_t limbIndex = (NSMaxRange(safeRange)-1+mp_bits_per_limb-1)/mp_bits_per_limb;
    const mp_limb_t* currentLimb = limbs+limbIndex;
    for(size_t i = NSMaxRange(safeRange) ; i>0 ; --i)
    {
      mp_bitcnt_t bitIndex = i-1;
      size_t newLimbIndex = (bitIndex+mp_bits_per_limb-1)/mp_bits_per_limb;
      if (newLimbIndex != limbIndex)
        --currentLimb;
      if (!*currentLimb)
      {
        if (!limbIndex)
          break;
        else//if (limbIndex)
        {
          i = limbIndex*mp_bits_per_limb;
          --limbIndex;
        }//end if (limbIndex)
      }//end if (!*currentLimb)
      else//if (*currentLimb)
      {
        limbIndex = newLimbIndex;
        BOOL bit = (((*currentLimb) & (0x1UL << (bitIndex%mp_bits_per_limb))) != 0);
        if (bit)
        {
          result = bitIndex;
          break;
        }//end if (bit)
      }//end if (*currentLimb)
    }//end for each bit in range
  }//end if (safeRange.length > 0)
  return result;
}
//end mpn_rscan1_range()

void mpz_set_zero_raw(mpz_ptr value)
{
  mpn_set_zero(mpz_limbs_modify(value, mpz_size(value)), mpz_size(value));
}
//end mpz_set_zero_raw()

void mpz_init_set_nsui(mpz_t rop, const NSUInteger op)
{
  if (op <= ULONG_MAX)
    mpz_init_set_ui(rop, op);
  else//if (op > ULONG_MAX)
  {
    mpz_init(rop);
    mpz_set_str(rop, [[[NSNumber numberWithUnsignedInteger:op] stringValue] UTF8String], 10);
  }//end if (op > ULONG_MAX)
}
//end mpz_init_set_nsui()

void mpz_set_nsui(mpz_t rop, const NSUInteger op)
{
  if (op <= ULONG_MAX)
    mpz_set_ui(rop, op);
  else//if (op > ULONG_MAX)
    mpz_set_str(rop, [[[NSNumber numberWithUnsignedInteger:op] stringValue] UTF8String], 10);
}
//end mpz_set_nsui()
  
void mpz_init_set_nssi(mpz_t rop, const NSInteger op)
{
  if ((LONG_MIN <= op) && (op <= LONG_MAX))
    mpz_init_set_si(rop, op);
  else//if op larger than signed int
  {
    mpz_init(rop);
    mpz_set_str(rop, [[[NSNumber numberWithInteger:op] stringValue] UTF8String], 10);
  }//end if op larger than signed int
}
//end mpz_init_set_nssi()

void mpz_set_nssi(mpz_t rop, const NSInteger op)
{
  if ((LONG_MIN <= op) && (op <= LONG_MAX))
    mpz_set_si(rop, op);
  else//if op larger than signed int
    mpz_set_str(rop, [[[NSNumber numberWithInteger:op] stringValue] UTF8String], 10);
}
//end mpz_set_nssi()

void mpz_init_set_nsdecimal(mpz_t rop, const NSDecimal* op)
{
  if (!op)
    mpz_init_set_si(rop, 0);
  else//if (op)
  {
    @autoreleasepool {
      NSDecimalNumber* infObject = [[NSDecimalNumber alloc] initWithLong:LONG_MIN];
      NSDecimal inf = [infObject decimalValue];
      [infObject release];
      NSDecimalNumber* supObject = [[NSDecimalNumber alloc] initWithLong:LONG_MAX];
      NSDecimal sup = [supObject decimalValue];
      [supObject release];
      if ((NSDecimalCompare(&inf, op) != NSOrderedDescending) && (NSDecimalCompare(op, &sup) != NSOrderedDescending))
      {
        NSDecimalNumber* opObject = [[NSDecimalNumber alloc] initWithDecimal:*op];
        mpz_init_set_si(rop, [opObject longValue]);
        [opObject release];
      }//if ((NSDecimalCompare(&inf, op) != NSOrderedDescending) && (NSDecimalCompare(op, &sup) != NSOrderedDescending))
      else//if op larger than signed int
      {
        mpz_init(rop);
        mpz_set_str(rop, [NSDecimalString(op, nil) UTF8String], 10);
      }//end if op larger than signed int
    }//end @autoreleasepool {
  }//end if (op)
}
//end mpz_init_set_nsdecimal()

void mpz_set_nsdecimal(mpz_t rop, const NSDecimal* op)
{
  if (!op)
    mpz_set_si(rop, 0);
  else//if (op)
  {
    @autoreleasepool {
      NSDecimalNumber* infObject = [[NSDecimalNumber alloc] initWithLong:LONG_MIN];
      NSDecimal inf = [infObject decimalValue];
      [infObject release];
      NSDecimalNumber* supObject = [[NSDecimalNumber alloc] initWithLong:LONG_MAX];
      NSDecimal sup = [supObject decimalValue];
      [supObject release];
      if ((NSDecimalCompare(&inf, op) != NSOrderedDescending) && (NSDecimalCompare(op, &sup) != NSOrderedDescending))
      {
        NSDecimalNumber* opObject = [[NSDecimalNumber alloc] initWithDecimal:*op];
        mpz_set_si(rop, [opObject longValue]);
        [opObject release];
      }//if ((NSDecimalCompare(&inf, op) != NSOrderedDescending) && (NSDecimalCompare(op, &sup) != NSOrderedDescending))
      else//if op larger than signed int
      {
        mpz_set_str(rop, [NSDecimalString(op, nil) UTF8String], 10);
      }//end if op larger than signed int
    }//end @autoreleasepool {
  }//end if (op)
}
//end mpz_set_nsdecimal()
  
NSUInteger mpz_get_nsui(mpz_srcptr op)
{
  NSUInteger result = 0;
  if (sizeof(NSUInteger) <= sizeof(unsigned long int))
    result = mpz_get_ui(op);
  else//if (sizeof(NSUInteger) > sizeof(unsigned long int))
  {
    if (!mpz_sgn(op))
      result = 0;
    else if (mpz_fits_uint_p(op))
      result = mpz_get_ui(op);
    else if (!mpz_fits_nsui_p(op))
      result = NSUIntegerMax;
    else//if (mpz_fits_nsui_p(op))
    {
      char buffer[8*sizeof(NSUInteger)+1] = {0};
      mpz_get_str(buffer, 10, op);
      NSString* stringWrapper =
        [[NSString alloc] initWithBytesNoCopy:buffer length:sizeof(buffer) encoding:NSUTF8StringEncoding freeWhenDone:NO];
      result = [[NSNumber numberWithString:stringWrapper] unsignedIntegerValue];
      [stringWrapper release];
    }//end if (mpz_fits_nsui_p(op))
  }//end if (sizeof(NSUInteger) > sizeof(unsigned long int))
  return result;
}
//end mpz_get_nsui()
  
NSInteger mpz_get_nssi(mpz_srcptr op)
{
  NSInteger result = 0;
  if (sizeof(NSInteger) <= sizeof(signed long int))
    result = mpz_get_si(op);
  else//if (sizeof(NSInteger) > sizeof(signed long int))
  {
    int sgn = mpz_sgn(op);
    if (!sgn)
      result = 0;
    else if (mpz_fits_sint_p(op))
      result = mpz_get_si(op);
    else if (!mpz_fits_nssi_p(op))
      result = (sgn < 0) ? NSIntegerMin : NSIntegerMax;
    else//if (mpz_fits_nssi_p(op))
    {
      char buffer[8*sizeof(NSInteger)+1+1] = {0};//+1 for the sign
      mpz_get_str(buffer, 10, op);
      NSString* stringWrapper =
        [[NSString alloc] initWithBytesNoCopy:buffer length:sizeof(buffer) encoding:NSUTF8StringEncoding freeWhenDone:NO];
      result = [[NSNumber numberWithString:stringWrapper] integerValue];
      [stringWrapper release];
    }//end if (mpz_fits_nsui_p(op))
  }//end if (sizeof(NSInteger) > sizeof(signed long int))
  return result;
}
//end mpz_get_nssi()

NSDecimal mpz_get_nsdecimal(mpz_srcptr op)
{
  NSDecimal result = {0};
  if (mpz_fits_sint_p(op) || mpz_fits_nssi_p(op))
    result = [[NSDecimalNumber numberWithInteger:mpz_get_si(op)] decimalValue];
  else//if does not fit in small types
  {
    int sgn = mpz_sgn(op);
    if (!mpz_fits_nsdecimal_p(op))
      result = (sgn<0) ? [[NSDecimalNumber minimumDecimalNumber] decimalValue] : [[NSDecimalNumber maximumDecimalNumber] decimalValue];
    else//if (mpz_fits_nsdecimal_p(op))
    {
      char buffer[8*sizeof(result._mantissa)+1+1] = {0};//+1 for the sign
      mpz_get_str(buffer, 10, op);
      NSString* stringWrapper =
        [[NSString alloc] initWithBytesNoCopy:buffer length:sizeof(buffer) encoding:NSUTF8StringEncoding freeWhenDone:NO];
      result = [[NSDecimalNumber decimalNumberWithString:stringWrapper] decimalValue];
      [stringWrapper release];
    }//end if (mpz_fits_nsdecimal_p(op))
  }//end if does not fit in small types
  return result;
}
//end mpz_get_nsdecimal()

int mpz_fits_nsui_p(mpz_srcptr op)
{
  int result = ((mpz_sgn(op)>=0) && mpz_fits_ulong_p(op)) ? 1 : 0;
  if (!result && (sizeof(NSUInteger) > sizeof(unsigned long)))
  {
    mpz_t sup;
    mpz_init_set_nsui(sup, NSUIntegerMax);
    result = (mpz_cmp(op, sup) <= 0) ? 1 : 0;
    mpz_clear(sup);
  }//end if (!result && (sizeof(NSUInteger) > sizeof(unsigned long)))
  return result;
}
//end mpz_fits_nsui_p()

int mpz_fits_nssi_p(mpz_srcptr op)
{
  int result = mpz_fits_slong_p(op);
  if (sizeof(NSInteger) > sizeof(signed long))
  {
    mpz_t sup;
    mpz_init_set_nssi(sup, NSIntegerMax);
    result = (mpz_cmp(op, sup) <= 0) ? 1 : 0;
    mpz_clear(sup);
  }//end if (sizeof(NSUInteger) > sizeof(signed long))
  return result;
}
//end mpz_fits_nssi_p()

int mpz_fits_nsdecimal_p(mpz_srcptr op)
{
  int result = 0;
  if (!result)
    result = mpz_fits_sint_p(op);
  if (!result)
    result = mpz_fits_nssi_p(op);
  if (!result)
  {
    NSUInteger nbBits = mpz_sizeinbase(op, 2);
    result = (nbBits <= 8*sizeof(((NSDecimal*)0)->_mantissa)) ? 1 : 0;
  }//end if (!result)
  return result;
}
//end mpz_fits_nssi_p()

BOOL getEncodingIsStandard(chalk_number_encoding_t encoding)
{
  BOOL result =
    (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) ||
    (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD) ||
    (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD);
  return result;
}
//end getEncodingIsStandard()

BOOL getEncodingIsInteger(chalk_number_encoding_t encoding)
{
  BOOL result = NO;
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) &&
    (encoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z);
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
    (encoding.encodingVariant.gmpCustomVariantEncoding == CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z);
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD);
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM);
  return result;
}
//end getEncodingIsInteger()

BOOL getEncodingIsUnsignedInteger(chalk_number_encoding_t encoding)
{
  BOOL result = NO;
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD) &&
    ((encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U));
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) &&
    (encoding.encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED);
  return result;
}
//end getEncodingIsUnsignedInteger()

BOOL getEncodingIsSignedInteger(chalk_number_encoding_t encoding)
{
  BOOL result = NO;
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) &&
    (encoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z);
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
    (encoding.encodingVariant.gmpCustomVariantEncoding == CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z);
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD) &&
    ((encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S) ||
     (encoding.encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S));
  result |= (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) &&
    (encoding.encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED);
  return result;
}
//end getEncodingIsSignedInteger()

NSUInteger getMinorPartOrderedCountForEncoding(chalk_number_encoding_t encoding)
{
  NSUInteger result = 0;
  chalk_number_encoding_type_t encodingType = encoding.encodingType;
  chalk_number_encoding_variant_t encodingVariant = encoding.encodingVariant;
  switch(encodingType)
  {
    case CHALK_NUMBER_ENCODING_UNDEFINED:
      break;
    case CHALK_NUMBER_ENCODING_GMP_STANDARD:
    case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
      if (encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z)
        result = 2;
      else if (encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR)
        result = 3;
      break;
    case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
      result = 3;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
      if ((encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U))
        result = 1;
      else if ((encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S))
        result = 2;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
      if (encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED)
        result = 1;
      else if (encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED)
        result = 2;
      break;
  }//end switch(encodingType)
  return result;
}
//end getMinorPartOrderedCountForEncoding()

chalk_number_part_minor_type_t getMinorPartOrderedForEncoding(chalk_number_encoding_t encoding, NSUInteger index)
{
  chalk_number_part_minor_type_t result = CHALK_NUMBER_PART_MINOR_UNDEFINED;
  chalk_number_encoding_type_t encodingType = encoding.encodingType;
  chalk_number_encoding_variant_t encodingVariant = encoding.encodingVariant;
  switch(encodingType)
  {
    case CHALK_NUMBER_ENCODING_UNDEFINED:
      break;
    case CHALK_NUMBER_ENCODING_GMP_STANDARD:
    case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
      if (encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z)
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 (index == 1) ? CHALK_NUMBER_PART_MINOR_SIGN :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      else if (encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR)
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 (index == 1) ? CHALK_NUMBER_PART_MINOR_EXPONENT :
                 (index == 2) ? CHALK_NUMBER_PART_MINOR_SIGN :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      break;
    case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
      result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
               (index == 1) ? CHALK_NUMBER_PART_MINOR_EXPONENT :
               (index == 2) ? CHALK_NUMBER_PART_MINOR_SIGN :
               CHALK_NUMBER_PART_MINOR_UNDEFINED;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
      if ((encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U) ||
          (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U))
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      else if ((encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S) ||
               (encodingVariant.integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S))
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 (index == 1) ? CHALK_NUMBER_PART_MINOR_SIGN :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
      if (encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED)
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      else if (encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED)
        result = (index == 0) ? CHALK_NUMBER_PART_MINOR_SIGNIFICAND :
                 (index == 1) ? CHALK_NUMBER_PART_MINOR_SIGN :
                 CHALK_NUMBER_PART_MINOR_UNDEFINED;
      break;
  }//end switch(encodingType)
  return result;
}
//end getMinorPartOrderedForEncoding()

NSUInteger getMinorPartBitsCountForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorPart)
{
  NSUInteger result = 0;
  if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
    result = getSignBitsCountForEncoding(encoding);
  else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
    result = getExponentBitsCountForEncoding(encoding);
  else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    result = getSignificandBitsCountForEncoding(encoding, NO);
  return result;
}
//end getMinorPartBitsCountForEncoding()

NSUInteger getMultipleMinorPartsBitsCountForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorParts)
{
  NSUInteger result = 0;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    if ((minorParts & minorPart) != 0)
    {
      NSUInteger minorPartBitsCount = getMinorPartBitsCountForEncoding(encoding, minorPart);
      result = NSUIntegerAdd(result, minorPartBitsCount);
    }//end if ((minorParts & minorPart) != 0)
  }//end for each minorPart
  return result;
}
//end getMultipleMinorPartsBitsRangeForEncoding()

NSUInteger getTotalBitsCountForEncoding(chalk_number_encoding_t encoding)
{
  NSUInteger result = 0;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    NSUInteger minorPartBitsCount = getMinorPartBitsCountForEncoding(encoding, minorPart);
    result = NSUIntegerAdd(result, minorPartBitsCount);
  }//end for each minorPart
  return result;
}
//end getTotalBitsCountForEncoding()

NSUInteger getSignBitsCountForEncoding(chalk_number_encoding_t encoding)
{
  NSUInteger result = 0;
  if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
  {
    switch(encoding.encodingVariant.gmpStandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
        result = 1;//mp_bits_per_limb;
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
        result = 8*sizeof(mpfr_sign_t);
        break;
    }//end switch(encoding.encodingVariant.gmpStandardVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
  {
    switch(encoding.encodingVariant.gmpCustomVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z:
        break;
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR:
        break;
    }//end switch(encoding.encodingVariant.gmpCustomVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD)
    result = 1;
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD)
  {
    switch(encoding.encodingVariant.integerStandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
        result = 1;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
        break;
    }//end switch(encoding.encodingVariant.integerStandardVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM)
  {
    switch(encoding.encodingVariant.integerCustomVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
        result = 1;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
        break;
    }//end switch(encoding.encodingVariant.integerCustomVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM)
  return result;
}
//end getSignBitsCountForEncoding()

NSUInteger getExponentBitsCountForEncoding(chalk_number_encoding_t encoding)
{
  NSUInteger result = 0;
  if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
  {
    switch(encoding.encodingVariant.gmpStandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
        result = 8*sizeof(mpfr_exp_t);
        break;
    }//end switch(encoding.encodingVariant.gmpStandardVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
  {
    switch(encoding.encodingVariant.gmpCustomVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z:
        break;
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR:
        break;
    }//end switch(encoding.encodingVariant.gmpCustomVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD)
  {
    switch(encoding.encodingVariant.ieee754StandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
        result = 5;
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
        result = 8;
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
        result = 11;
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
        result = 15;
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
        result = 15;
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
        result = 19;
        break;
    }//end switch(ieee754StandardVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD) {
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) {
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM)
  return result;
}
//end getExponentBitsCountForEncoding()

NSUInteger getSignificandBitsCountForEncoding(chalk_number_encoding_t encoding, BOOL addImplicitBits)
{
  NSUInteger result = 0;
  if (encoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
    result = MP_BITCNT_MAX;
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD)
  {
    switch(encoding.encodingVariant.ieee754StandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
        result = 10+(addImplicitBits ? 1 : 0);
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
        result = 23+(addImplicitBits ? 1 : 0);
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
        result = 52+(addImplicitBits ? 1 : 0);
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
        result = 64+(addImplicitBits ? 1 : 0);
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
        result = 112+(addImplicitBits ? 1 : 0);
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
        result = 236+(addImplicitBits ? 1 : 0);
        break;
    }//end switch(ieee754StandardVariantEncoding)
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_IEEE754_STANDARD)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_STANDARD)
  {
    switch(encoding.encodingVariant.integerStandardVariantEncoding)
    {
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
        result = 7;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
        result = 8;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
        result = 15;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
        result = 16;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
        result = 31;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
        result = 32;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
        result = 63;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
        result = 64;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
        result = 127;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
        result = 128;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
        result = 255;
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
        result = 256;
        break;
    }//end switch(encoding)
  }//end if (encoding.encodingVariant.integerStandardVariantEncoding)
  else if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) {
  }//end if (encoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM)
  return result;
}
//end getSignificandBitsCountForEncoding()

NSRange getMinorPartBitsRangeForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorPart)
{
  NSRange result = NSRangeZero;
  if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
    result = getSignBitsRangeForEncoding(encoding);
  else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
    result = getExponentBitsRangeForEncoding(encoding);
  else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    result = getSignificandBitsRangeForEncoding(encoding, NO);
  return result;
}
//end getMinorPartBitsRangeForEncoding()

NSRange getMultipleMinorPartsBitsRangeForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorParts)
{
  NSRange result = NSRangeZero;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    if ((minorParts & minorPart) != 0)
    {
      NSRange minorPartBitsRange = getMinorPartBitsRangeForEncoding(encoding, minorPart);
      result = NSRangeUnion(result, minorPartBitsRange);
    }//end if ((minorParts & minorPart) != 0)
  }//end for each minorPart
  return result;
}
//end getMultipleMinorPartsBitsRangeForEncoding()

NSRange getTotalBitsRangeForEncoding(chalk_number_encoding_t encoding)
{
  NSRange result = NSRangeZero;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    NSRange minorPartBitsRange = getMinorPartBitsRangeForEncoding(encoding, minorPart);
    result = NSRangeUnion(result, minorPartBitsRange);
  }//end for each minorPart
  return result;
}
//end getTotalBitsRangeForEncoding()

NSRange getSignBitsRangeForEncoding(chalk_number_encoding_t encoding)
{
  NSRange result = NSRangeZero;
  NSUInteger length = getSignBitsCountForEncoding(encoding);
  NSRange resultWithoutOffset = NSMakeRange(0, length);
  result = resultWithoutOffset;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    if (minorPart != CHALK_NUMBER_PART_MINOR_SIGN)
      result = NSRangeShift(result, getMinorPartBitsCountForEncoding(encoding, minorPart));
    else
      i = minorPartsOrdered;//force stop
  }//end for each minorPart
  return result;
}
//end getSignBitsRangeForEncoding()

NSRange getExponentBitsRangeForEncoding(chalk_number_encoding_t encoding)
{
  NSRange result = NSRangeZero;
  NSUInteger length = getExponentBitsCountForEncoding(encoding);
  NSRange resultWithoutOffset = NSMakeRange(0, length);
  result = resultWithoutOffset;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    if (minorPart != CHALK_NUMBER_PART_MINOR_EXPONENT)
      result = NSRangeShift(result, getMinorPartBitsCountForEncoding(encoding, minorPart));
    else
      i = minorPartsOrdered;//force stop
  }//end for each minorPart
  return result;
}
//end getExponentBitsRangeForEncoding()

NSRange getSignificandBitsRangeForEncoding(chalk_number_encoding_t encoding, BOOL addImplicitBits)
{
  NSRange result = NSRangeZero;
  NSUInteger length = getSignificandBitsCountForEncoding(encoding, addImplicitBits);
  NSRange resultWithoutOffset = NSMakeRange(0, length);
  result = resultWithoutOffset;
  NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
  for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
    if (minorPart != CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
      result = NSRangeShift(result, getMinorPartBitsCountForEncoding(encoding, minorPart));
    else
      i = minorPartsOrdered;//force stop
  }//end for each minorPart
  return result;
}
//end getSignificandBitsRangeForEncoding()

NSUInteger getMinorPartOrderedCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSUInteger result = !bitInterpretation ? 0 :
    getMinorPartOrderedCountForEncoding(bitInterpretation->numberEncoding);
  return result;
}
//end getMinorPartOrderedCountForBitInterpretation()

chalk_number_part_minor_type_t getMinorPartOrderedForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, NSUInteger index)
{
  chalk_number_part_minor_type_t result = !bitInterpretation ? 0 :
    getMinorPartOrderedForEncoding(bitInterpretation->numberEncoding, index);
  return result;
}
//end getMinorPartOrderedForBitInterpretation()

NSUInteger getMinorPartBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      result = getSignBitsCountForBitInterpretation(bitInterpretation);
    else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      result = getExponentBitsCountForBitInterpretation(bitInterpretation);
    else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
      result = getSignificandBitsCountForBitInterpretation(bitInterpretation, NO);
  }//end if (bitInterpretation)
  return result;
}
//end getMinorPartBitsCountForBitInterpretation()

NSUInteger getMultipleMinorPartsBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
      if ((minorParts & minorPart) != 0)
      {
        NSUInteger minorPartBitsCount = getMinorPartBitsCountForBitInterpretation(bitInterpretation, minorPart);
        result = NSUIntegerAdd(result, minorPartBitsCount);
      }//end if ((minorParts & minorPart) != 0)
    }//end for each minorPart
  }//end if (bitInterpretation)
  return result;
}
//end getMultipleMinorPartsBitsCountForBitInterpretation()

NSUInteger getTotalBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
      NSUInteger minorPartBitsCount = getMinorPartBitsCountForBitInterpretation(bitInterpretation, minorPart);
      result = NSUIntegerAdd(result, minorPartBitsCount);
    }//end for each minorPart
  }//end if (bitInterpretation)
  return result;
}
//end getTotalBitsCountForBitInterpretation()

NSUInteger getSignBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getSignBitsCountForEncoding(encoding);
    else//if (!getEncodingIsStandard(encoding))
      result = bitInterpretation->signCustomBitsCount;
  }//end if (bitInterpretation)
  return result;
}
//end getSignBitsCountForBitInterpretation()

NSUInteger getExponentBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getExponentBitsCountForEncoding(encoding);
    else//if (!getEncodingIsStandard(encoding))
      result = bitInterpretation->exponentCustomBitsCount;
  }//end if (bitInterpretation)
  return result;
}
//end getExponentBitsCountForBitInterpretation()

NSUInteger getSignificandBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, BOOL addImplicitBits)
{
  NSUInteger result = 0;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getSignificandBitsCountForEncoding(encoding, addImplicitBits);
    else//if (!getEncodingIsStandard(encoding))
      result = bitInterpretation->significandCustomBitsCount;
  }//end if (bitInterpretation)
  return result;
}
//end getSignificandBitsCountForBitInterpretation()

NSRange getMinorPartBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      result = getSignBitsRangeForBitInterpretation(bitInterpretation);
    else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      result = getExponentBitsRangeForBitInterpretation(bitInterpretation);
    else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
      result = getSignificandBitsRangeForBitInterpretation(bitInterpretation, NO);
  }//end if (bitInterpretation)
  return result;
}
//end getMinorPartBitsRangeForBitInterpretation()

NSRange getMultipleMinorPartsBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
      if ((minorParts & minorPart) != 0)
      {
        NSRange minorPartBitsRange = getMinorPartBitsRangeForBitInterpretation(bitInterpretation, minorPart);
        result = NSRangeUnion(result, minorPartBitsRange);
      }//end if ((minorParts & minorPart) != 0)
    }//end for each minorPart
  }//end if (bitInterpretation)
  return result;
}
//end getMultipleMinorPartsBitsRangeForBitInterpretation()

NSRange getTotalBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
      NSRange minorPartBitsRange = getMinorPartBitsRangeForBitInterpretation(bitInterpretation, minorPart);
      result = NSRangeUnion(result, minorPartBitsRange);
    }//end for each minorPart
  }//end if (bitInterpretation)
  return result;
}
//end getTotalBitsRangeForBitInterpretation()

NSRange getSignBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getSignBitsRangeForEncoding(encoding);
    else//if (!getEncodingIsStandard(encoding))
    {
      result = NSMakeRange(0, bitInterpretation->signCustomBitsCount);
      NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
      for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
      {
        chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
        if (minorPart != CHALK_NUMBER_PART_MINOR_SIGN)
          result = NSRangeShift(result, getMinorPartBitsCountForBitInterpretation(bitInterpretation, minorPart));
        else
          i = minorPartsOrdered;//force stop
      }//end for each minorPart
    }//end if (!getEncodingIsStandard(encoding))
  }//end if (bitInterpretation)
  return result;
}
//end getSignBitsRangeForBitInterpretation()

NSRange getExponentBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getExponentBitsRangeForEncoding(encoding);
    else//if (!getEncodingIsStandard(encoding))
    {
      result = NSMakeRange(0, bitInterpretation->exponentCustomBitsCount);
      NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
      for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
      {
        chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
        if (minorPart != CHALK_NUMBER_PART_MINOR_EXPONENT)
          result = NSRangeShift(result, getMinorPartBitsCountForBitInterpretation(bitInterpretation, minorPart));
        else
          i = minorPartsOrdered;//force stop
      }//end for each minorPart
    }//end if (!getEncodingIsStandard(encoding))
  }//end if (bitInterpretation)
  return result;
}
//end getExponentBitsRangeForBitInterpretation()

NSRange getSignificandBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, BOOL addImplicitBits)
{
  NSRange result = NSRangeZero;
  if (bitInterpretation)
  {
    chalk_number_encoding_t encoding = bitInterpretation->numberEncoding;
    if (getEncodingIsStandard(encoding))
      result = getSignificandBitsRangeForEncoding(encoding, addImplicitBits);
    else//if (!getEncodingIsStandard(encoding))
    {
      result = NSMakeRange(0, bitInterpretation->significandCustomBitsCount);
      NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(encoding);
      for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
      {
        chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(encoding, i);
        if (minorPart != CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
          result = NSRangeShift(result, getMinorPartBitsCountForBitInterpretation(bitInterpretation, minorPart));
        else
          i = minorPartsOrdered;//force stop
      }//end for each minorPart
    }//end if (!getEncodingIsStandard(encoding))
  }//end if (bitInterpretation)
  return result;
}
//end getSignificandBitsRangeForBitInterpretation()

NSRange getMinorPartBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getMinorPartBitsRangeForValueZ(value->integer, bitInterpretation, minorPart);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getMinorPartBitsRangeForValueQ(value->fraction, bitInterpretation, minorPart);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getMinorPartBitsRangeForValueFR(value->realExact, bitInterpretation, minorPart);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getMinorPartBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation, minorPart);
      else
        result = getMinorPartBitsRangeForValueFIR(value->realApprox, bitInterpretation, minorPart);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getMinorPartBitsRangeForValue()

NSRange getMinorPartBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result = getMinorPartBitsRangeForBitInterpretation(bitInterpretation, minorPart);
  return result;
}
//end getMinorPartBitsRangeForValueZ()

NSRange getMinorPartBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getMinorPartBitsRangeForValueZ(mpq_numref(value), bitInterpretation, minorPart) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getMinorPartBitsRangeForValueZ(mpq_denref(value), bitInterpretation, minorPart) :
    NSRangeZero;
  return result;
}
//end getMinorPartBitsRangeForValueQ()

NSRange getMinorPartBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result = getMinorPartBitsRangeForBitInterpretation(bitInterpretation, minorPart);
  return result;
}
//end getMinorPartBitsRangeForValueFR()

NSRange getMinorPartBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getMinorPartBitsRangeForValueFR(&value->interval.left, bitInterpretation, minorPart) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getMinorPartBitsRangeForValueFR(&value->interval.right, bitInterpretation, minorPart) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getMinorPartBitsRangeForValueFR(&value->estimation, bitInterpretation, minorPart) :
    NSRangeZero;
  return result;
}
//end getMinorPartBitsRangeForValueFIR()

NSRange getMultipleMinorPartsBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getMultipleMinorPartsBitsRangeForValueZ(value->integer, bitInterpretation, minorParts);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getMultipleMinorPartsBitsRangeForValueQ(value->fraction, bitInterpretation, minorParts);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getMultipleMinorPartsBitsRangeForValueFR(value->realExact, bitInterpretation, minorParts);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getMultipleMinorPartsBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation, minorParts);
      else
        result = getMultipleMinorPartsBitsRangeForValueFIR(value->realApprox, bitInterpretation, minorParts);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getMultipleMinorPartsBitsRangeForValue()

NSRange getMultipleMinorPartsBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result = getMultipleMinorPartsBitsRangeForBitInterpretation(bitInterpretation, minorParts);
  return result;
}
//end getMultipleMinorPartsBitsRangeForValueZ()

NSRange getMultipleMinorPartsBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getMultipleMinorPartsBitsRangeForValueZ(mpq_numref(value), bitInterpretation, minorParts) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getMultipleMinorPartsBitsRangeForValueZ(mpq_denref(value), bitInterpretation, minorParts) :
    NSRangeZero;
  return result;
}
//end getMultipleMinorPartsBitsRangeForValueQ()

NSRange getMultipleMinorPartsBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result = getMultipleMinorPartsBitsRangeForBitInterpretation(bitInterpretation, minorParts);
  return result;
}
//end getMultipleMinorPartsBitsRangeForValueFR()

NSRange getMultipleMinorPartsBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getMultipleMinorPartsBitsRangeForValueFR(&value->interval.left, bitInterpretation, minorParts) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getMultipleMinorPartsBitsRangeForValueFR(&value->interval.right, bitInterpretation, minorParts) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getMultipleMinorPartsBitsRangeForValueFR(&value->estimation, bitInterpretation, minorParts) :
    NSRangeZero;
  return result;
}
//end getMultipleMinorPartsBitsRangeForValueFIR()

NSRange getTotalBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getTotalBitsRangeForValueZ(value->integer, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getTotalBitsRangeForValueQ(value->fraction, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getTotalBitsRangeForValueFR(value->realExact, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getTotalBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation);
      else
        result = getTotalBitsRangeForValueFIR(value->realApprox, bitInterpretation);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getTotalBitsRangeForValue()

NSRange getTotalBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getTotalBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getTotalBitsRangeForValueZ()

NSRange getTotalBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getTotalBitsRangeForValueZ(mpq_numref(value), bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getTotalBitsRangeForValueZ(mpq_denref(value), bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getTotalBitsRangeForValueQ()

NSRange getTotalBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getTotalBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getTotalBitsRangeForValueFR()

NSRange getTotalBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getTotalBitsRangeForValueFR(&value->interval.left, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getTotalBitsRangeForValueFR(&value->interval.right, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getTotalBitsRangeForValueFR(&value->estimation, bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getTotalBitsRangeForValueFIR()

NSRange getSignBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getSignBitsRangeForValueZ(value->integer, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getSignBitsRangeForValueQ(value->fraction, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getSignBitsRangeForValueFR(value->realExact, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getSignBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation);
      else
        result = getSignBitsRangeForValueFIR(value->realApprox, bitInterpretation);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getSignBitsRangeForValue()

NSRange getSignBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getSignBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getSignBitsRangeForValueZ()

NSRange getSignBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getSignBitsRangeForValueZ(mpq_numref(value), bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getSignBitsRangeForValueZ(mpq_denref(value), bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getSignBitsRangeForValueQ()

NSRange getSignBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getSignBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getSignBitsRangeForValueFR()

NSRange getSignBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getSignBitsRangeForValueFR(&value->interval.left, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getSignBitsRangeForValueFR(&value->interval.right, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getSignBitsRangeForValueFR(&value->estimation, bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getSignBitsRangeForValueFIR()

NSRange getExponentBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getExponentBitsRangeForValueZ(value->integer, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getExponentBitsRangeForValueQ(value->fraction, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getExponentBitsRangeForValueFR(value->realExact, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getExponentBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation);
      else
        result = getExponentBitsRangeForValueFIR(value->realApprox, bitInterpretation);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getExponentBitsRangeForValue()

NSRange getExponentBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getExponentBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getExponentBitsRangeForValueZ()

NSRange getExponentBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getExponentBitsRangeForValueZ(mpq_numref(value), bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getExponentBitsRangeForValueZ(mpq_denref(value), bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getExponentBitsRangeForValueQ()

NSRange getExponentBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getExponentBitsRangeForBitInterpretation(bitInterpretation);
  return result;
}
//end getExponentBitsRangeForValueFR()

NSRange getExponentBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getExponentBitsRangeForValueFR(&value->interval.left, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getExponentBitsRangeForValueFR(&value->interval.right, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getExponentBitsRangeForValueFR(&value->estimation, bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getExponentBitsRangeForValueFIR()

NSRange getSignificandBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = NSRangeZero;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = getSignificandBitsRangeForValueZ(value->integer, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = getSignificandBitsRangeForValueQ(value->fraction, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = getSignificandBitsRangeForValueFR(value->realExact, bitInterpretation);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = getSignificandBitsRangeForValueFR(&value->realApprox->estimation, bitInterpretation);
      else
        result = getSignificandBitsRangeForValueFIR(value->realApprox, bitInterpretation);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end getSignificandBitsRangeForValue()

NSRange getSignificandBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getSignificandBitsRangeForBitInterpretation(bitInterpretation, NO);
  return result;
}
//end getSignificandBitsRangeForValueZ()

NSRange getSignificandBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR) ?
      getSignificandBitsRangeForValueZ(mpq_numref(value), bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR) ?
      getSignificandBitsRangeForValueZ(mpq_denref(value), bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getSignificandBitsRangeForValueQ()

NSRange getSignificandBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result = getSignificandBitsRangeForBitInterpretation(bitInterpretation, NO);
  return result;
}
//end getSignificandBitsRangeForValueFR()

NSRange getSignificandBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation)
{
  NSRange result =
    !bitInterpretation ? NSRangeZero :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND) ?
      getSignificandBitsRangeForValueFR(&value->interval.left, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND) ?
      getSignificandBitsRangeForValueFR(&value->interval.right, bitInterpretation) :
    (bitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE) ?
      getSignificandBitsRangeForValueFR(&value->estimation, bitInterpretation) :
    NSRangeZero;
  return result;
}
//end getSignificandBitsRangeForValueFIR()

chalk_number_part_minor_type_t getMinorPartForBit(NSUInteger bitIndex, const chalk_bit_interpretation_t* bitInterpretation)
{
  chalk_number_part_minor_type_t result = CHALK_NUMBER_PART_MINOR_UNDEFINED;
  NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(bitInterpretation);
  for(NSUInteger i = 0 ; (result == CHALK_NUMBER_PART_MINOR_UNDEFINED) && (i<minorPartsCount) ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(bitInterpretation, i);
    NSRange minorPartRange = getMinorPartBitsRangeForBitInterpretation(bitInterpretation, minorPart);
    if (NSRangeContains(minorPartRange, bitIndex))
      result = minorPart;
  }//end for each minorPart
  return result;
}
//end getMinorPartForBit()

BOOL bitInterpretationEquals(const chalk_bit_interpretation_t* op1, const chalk_bit_interpretation_t* op2)
{
  BOOL result = op1 && op2 && !memcmp(op1, op2, sizeof(chalk_bit_interpretation_t));
  return result;
}
//end bitInterpretationEquals()

chalk_conversion_result_t convertFromValueToRaw(chalk_raw_value_t* dst, const chalk_gmp_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (src->type == CHALK_VALUE_TYPE_INTEGER)
      result = convertFromValueToRawZ(dst, src->integer, dstBitInterpretation, chalkContext);
    else if (src->type == CHALK_VALUE_TYPE_FRACTION)
      result = convertFromValueToRawQ(dst, src->fraction, dstBitInterpretation, chalkContext);
    else if (src->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = convertFromValueToRawFR(dst, src->realExact, dstBitInterpretation, chalkContext);
    else if (src->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = convertFromValueToRawFR(dst, &src->realApprox->estimation, dstBitInterpretation, chalkContext);
      else
        result = convertFromValueToRawFIR(dst, src->realApprox, dstBitInterpretation, chalkContext);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromValueToRaw()

chalk_conversion_result_t convertFromValueToRawZ(chalk_raw_value_t* dst, mpz_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    chalk_number_encoding_t dstNumberEncoding = dstBitInterpretation->numberEncoding;
    chalk_number_encoding_type_t dstEncodingType = dstNumberEncoding.encodingType;
    chalk_number_encoding_variant_t dstEncodingVariant = dstNumberEncoding.encodingVariant;
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    chalkRawValueSetZero(dst, 0);
    if (mpz_sgn(src) > 0)
      dst->flags |= CHALK_RAW_VALUE_FLAG_POSITIVE;
    if (mpz_sgn(src) < 0)
      dst->flags |= CHALK_RAW_VALUE_FLAG_NEGATIVE;
    
    BOOL isIntegerUnsigned = getEncodingIsUnsignedInteger(dstNumberEncoding);
    if (!result.error && isIntegerUnsigned && (dst->flags & CHALK_RAW_VALUE_FLAG_NEGATIVE))
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;

    mpfr_t srcFr;
    BOOL srcFrInitialized = NO;

    mp_bitcnt_t dstBitIndex = 0;
    NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(dstBitInterpretation);
    for(NSUInteger i = 0 ; !result.error && (i<minorPartsCount) ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(dstBitInterpretation, i);
      if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      {
        switch(dstEncodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(dstEncodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  {
                    mp_limb_t dummyLimb = (mpz_sgn(src) < 0) ? 1 : 0;
                    NSRange bitsRange = NSMakeRange(0, getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart));
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, &dummyLimb, 1, bitsRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  {
                    mp_limb_t dummyLimbs[(sizeof(mpfr_sign_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_sign_t* dummyLimbsAsSign = (mpfr_sign_t*)dummyLimbs;
                    *dummyLimbsAsSign = (mpz_sgn(src) < 0) ? -1 : (mpz_sgn(src) > 0) ? 1 : 0;
                    NSRange bitsRange = getMinorPartBitsRangeForValueZ(src, dstBitInterpretation, minorPart);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), bitsRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
              }//end switch(dstEncodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(dstEncodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpz_sgn(src)<0));
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpz_sgn(src)<0));
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(dstEncodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            {
              switch(dstEncodingVariant.integerStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpz_sgn(src) < 0));
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
                  if (mpz_sgn(src)<0)
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(dstEncodingVariant.integerStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            {
              switch(dstEncodingVariant.integerCustomVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
                  {
                    mp_limb_t dummyLimb = (mpz_sgn(src) < 0) ? 1 : 0;
                    NSRange bitsRange = NSMakeRange(0, getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart));
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, &dummyLimb, 1, bitsRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
                  if (mpz_sgn(src)<0)
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(dstEncodingVariant.integerCustomVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      {
        switch(dstEncodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(dstEncodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = MIN(mpz_sizeinbase(src, 2), [chalkContext softFloatSignificandDigitsWithBase:2]);
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    mpfr_set_z(srcFr, src, MPFR_RNDN);
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    mp_limb_t dummyLimbs[(sizeof(mpfr_exp_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_exp_t* dummyLimbsAsExp = (mpfr_exp_t*)dummyLimbs;
                    *dummyLimbsAsExp = mpfr_get_exp(srcFr);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, 8*sizeof(mpfr_exp_t)), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
              }//end switch(dstEncodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(dstEncodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = getSignificandBitsCountForEncoding(dstNumberEncoding, YES);
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    NSUInteger exponentBias = (1UL<<(exponentBitsCount-1UL))-1UL;
                    mp_limb_t dummyLimbs[(sizeof(mpfr_exp_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_exp_t* dummyLimbsAsExp = (mpfr_exp_t*)dummyLimbs;
                    if (mpfr_inf_p(srcFr) || mpfr_nan_p(srcFr))
                      *dummyLimbsAsExp = ~((mpfr_exp_t)0);
                    else if (ABS(mpfr_get_exp(srcFr))>exponentBias)
                    {
                      *dummyLimbsAsExp = ~((mpfr_exp_t)0);
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                      result.computeFlags |= (mpfr_get_exp(srcFr)>0) ? CHALK_COMPUTE_FLAG_OVERFLOW : CHALK_COMPUTE_FLAG_UNDERFLOW;
                    }//end if (ABS(mpfr_get_exp(srcFr))>exponentBias)
                    else
                      *dummyLimbsAsExp = mpfr_get_exp(srcFr)+exponentBias-1;//-1 because GMP MSB
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, exponentBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = getSignificandBitsCountForEncoding(dstNumberEncoding, YES);
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    NSUInteger exponentBias = (1UL<<(exponentBitsCount-1UL))-1UL;
                    mp_limb_t dummyLimbs[(sizeof(mpfr_exp_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_exp_t* dummyLimbsAsExp = (mpfr_exp_t*)dummyLimbs;
                    if (mpfr_inf_p(srcFr) || mpfr_nan_p(srcFr))
                      *dummyLimbsAsExp = ~((mpfr_exp_t)0);
                    else if (ABS(mpfr_get_exp(srcFr))>exponentBias)
                    {
                      *dummyLimbsAsExp = ~((mpfr_exp_t)0);
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                      result.computeFlags |= (mpfr_get_exp(srcFr)>0) ? CHALK_COMPUTE_FLAG_OVERFLOW : CHALK_COMPUTE_FLAG_UNDERFLOW;
                    }//end if (ABS(mpfr_get_exp(srcFr))>exponentBias)
                    else
                      *dummyLimbsAsExp = mpfr_get_exp(srcFr)+exponentBias-1;//-1 because GMP MSB
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, exponentBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(dstEncodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
      {
        switch(dstEncodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(dstEncodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  {
                    mp_size_t srcLimbsCount = mpz_size(src);
                    mp_size_t srcBitsCount = srcLimbsCount*mp_bits_per_limb;
                    const mp_limb_t* srcLimbs = mpz_limbs_read(src);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, srcLimbs, srcLimbsCount, NSMakeRange(0, srcBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = [chalkContext softFloatSignificandDigitsWithBase:2];
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    mpfr_set_z(srcFr, src, MPFR_RNDN);
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    mpfr_prec_t prec = mpfr_get_prec(srcFr);
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t limbsBitsCount = limbsCount*mp_bits_per_limb;
                    size_t paddingBitsCount = limbsBitsCount-prec;
                    size_t significandBitsCount = limbsBitsCount-paddingBitsCount;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, srcFr->_mpfr_d, limbsCount, NSMakeRange(paddingBitsCount, significandBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
              }//end switch(dstEncodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(dstEncodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = getSignificandBitsCountForEncoding(dstNumberEncoding, YES);
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    mpfr_set_z(srcFr, src, MPFR_RNDN);
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    mpfr_prec_t prec = mpfr_get_prec(srcFr);
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t limbsBitsCount = limbsCount*mp_bits_per_limb;
                    size_t significandBitsCount = prec-1;//-1 because GMP MSB
                    size_t paddingBitsCount = limbsBitsCount-prec;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, srcFr->_mpfr_d, limbsCount, NSMakeRange(paddingBitsCount, significandBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  if (!srcFrInitialized)
                  {
                    NSUInteger prec = getSignificandBitsCountForEncoding(dstNumberEncoding, YES);
                    mpfrDepool(srcFr, prec, chalkContext.gmpPool);
                    srcFrInitialized = YES;
                    mpfr_set_z(srcFr, src, MPFR_RNDN);
                    if (mpfr_inf_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    if (mpfr_nan_p(srcFr))
                      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
                  }//end if (!srcFrInitialized)
                  if (!srcFrInitialized)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else//if (srcFrInitialized)
                  {
                    mpfr_prec_t prec = mpfr_get_prec(srcFr);
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t limbsBitsCount = limbsCount*mp_bits_per_limb;
                    size_t significandBitsCount = prec-1;//-1 because GMP MSB
                    size_t paddingBitsCount = limbsBitsCount-prec;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, srcFr->_mpfr_d, limbsCount, NSMakeRange(paddingBitsCount, significandBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (srcFrInitialized)
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(dstEncodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            {
              NSRange significandBitsRange = getSignificandBitsRangeForBitInterpretation(dstBitInterpretation, NO);
              if (mpz_sizeinbase(src, 2)>significandBitsRange.length)
                result.error = CHALK_CONVERSION_ERROR_OVERFLOW;
              else//if (mpz_sizeinbase(src, 2)>=significandBitsRange)
              {
                switch(dstEncodingVariant.integerStandardVariantEncoding)
                {
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
                    {
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(src), mpz_size(src), significandBitsRange, &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    }
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
                    {
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(src), mpz_size(src), significandBitsRange, &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    }
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
                    result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                    break;
                }//end switch(dstEncodingVariant.integerStandardVariantEncoding)
              }//end if (mpz_sizeinbase(src, 2)>=significandBitsRange)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            {
              NSRange significandBitsRange = getSignificandBitsRangeForBitInterpretation(dstBitInterpretation, NO);
              if (mpz_sizeinbase(src, 2)>significandBitsRange.length)
                result.error = CHALK_CONVERSION_ERROR_OVERFLOW;
              else//if (mpz_sizeinbase(src, 2)>=significandBitsRange)
              {
                switch(dstEncodingVariant.integerCustomVariantEncoding)
                {
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
                    {
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(src), mpz_size(src), significandBitsRange, &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    }
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
                    {
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(src), mpz_size(src), significandBitsRange, &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    }
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
                    result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                    break;
                }//end switch(dstEncodingVariant.integerCustomVariantEncoding)
              }//end if (mpz_sizeinbase(src, 2)>=significandBitsRange)
            }
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    }//end for each minorPartOrdered
    
    if (!result.error)
    {
      BOOL isIntegerSigned = getEncodingIsSignedInteger(dstNumberEncoding);
      BOOL isChalkInteger =
        (dstNumberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) ||
        (dstNumberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM);
      if (isIntegerSigned && !isChalkInteger)
      {
        BOOL isNegative = mpz_tstbit(dst->bits, getSignBitsRangeForEncoding(dstNumberEncoding).location);
        if (isNegative)
        {
          NSRange dstSignificandBitsRange = getSignificandBitsRangeForBitInterpretation(dstBitInterpretation, NO);
          mpz_complement2(dst->bits, dstSignificandBitsRange);
        }//end if (isNegative)
      }//end if (isIntegerSigned && !isChalkInteger)
    }//end if (!result.error)

    if (dst->flags & CHALK_RAW_VALUE_FLAG_INFINITY)
      mpz_set_zero(dst->bits, getSignificandBitsRangeForBitInterpretation(dstBitInterpretation, NO));

    if (srcFrInitialized)
      mpfrRepool(srcFr, chalkContext.gmpPool);
    result.computeFlags |= chalkGmpFlagsMake();
    chalkGmpFlagsRestore(oldFlags);
  }//end if (src && dst && bitInterpretation)
  return result;
}
//end convertFromValueToRawZ()

chalk_conversion_result_t convertFromValueToRawQ(chalk_raw_value_t* dst, mpq_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR)
      result = convertFromValueToRawZ(dst, mpq_numref(src), dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR)
      result = convertFromValueToRawZ(dst, mpq_denref(src), dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE)
    {
      if (!mpz_cmp_si(mpq_denref(src), 1))
        result = convertFromValueToRawZ(dst, mpq_numref(src), dstBitInterpretation, chalkContext);
      else//if (mpz_cmp_si(mpq_denref(src), 1) != 0)
      {
        mpfr_t fr;
        mpfrDepool(fr, [chalkContext softFloatSignificandDigitsWithBase:2], chalkContext.gmpPool);
        mpfr_set_q(fr, src, MPFR_RNDN);
        result = convertFromValueToRawFR(dst, fr, dstBitInterpretation, chalkContext);
        mpfrRepool(fr, chalkContext.gmpPool);
      }//end if (mpz_cmp_si(mpq_denref(src), 1) != 0)
    }//end if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE)
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromValueToRawQ()

chalk_conversion_result_t convertFromValueToRawFR(chalk_raw_value_t* dst, mpfr_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  __block chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    chalk_number_encoding_t dstNumberEncoding = dstBitInterpretation->numberEncoding;
    chalk_number_encoding_type_t encodingType = dstNumberEncoding.encodingType;
    chalk_number_encoding_variant_t encodingVariant = dstNumberEncoding.encodingVariant;
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    chalkRawValueSetZero(dst, 0);
    
    if (mpfr_sgn(src) > 0)
      dst->flags |= CHALK_RAW_VALUE_FLAG_POSITIVE;
    if (mpfr_sgn(src) < 0)
      dst->flags |= CHALK_RAW_VALUE_FLAG_NEGATIVE;
    if (mpfr_inf_p(src))
      dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
    if (mpfr_nan_p(src))
      dst->flags |= CHALK_RAW_VALUE_FLAG_NAN;
    
    BOOL isIntegerUnsigned = getEncodingIsUnsignedInteger(dstNumberEncoding);
    BOOL isInteger = getEncodingIsInteger(dstNumberEncoding);
    if (!result.error && isIntegerUnsigned && (dst->flags & CHALK_RAW_VALUE_FLAG_NEGATIVE))
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
    if (!result.error && isInteger && (dst->flags & CHALK_RAW_VALUE_FLAG_INFINITY))
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_INFINITY;
    if (!result.error && isInteger && (dst->flags & CHALK_RAW_VALUE_FLAG_NAN))
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_NAN;

    mpz_t srcZ;
    BOOL srcZInitialized = NO;

    __block mp_bitcnt_t dstBitIndex = 0;
    
    void (^convert_significand_integer)(mpz_ptr, size_t, BOOL) = ^(mpz_ptr _srcZ, size_t nativeBitsCount, BOOL hasSignBit){
      size_t significandBitsCount = nativeBitsCount-(hasSignBit ? 1 : 0);
      BOOL negativeOverflow = NO;
      BOOL positiveOverflow = NO;
      mpz_set_si(_srcZ, 1);
      mpz_mul_2exp(_srcZ, _srcZ, significandBitsCount);
      positiveOverflow = (mpfr_cmp_z(src, _srcZ) >= 0);
      if (hasSignBit)
      {
        mpz_neg(_srcZ, _srcZ);
        negativeOverflow = (mpfr_cmp_z(src, _srcZ) < 0);
      }//end if (hasSignBit)
      if (!hasSignBit && (mpfr_sgn(src)<0))
        result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
      else if (positiveOverflow || negativeOverflow)
        result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW;
      else//if (!positiveOverflow && !negativeOverflow)
      {
        mpz_set_fr(_srcZ, src, MPFR_RNDN);
        BOOL error = NO;
        mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(_srcZ), mpz_size(_srcZ), NSMakeRange(0, significandBitsCount), &error);
        if (error)
          result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
        if (mpfr_sgn(src)<0)
          mpz_complement2(dst->bits, NSMakeRange(dstBitIndex, significandBitsCount));
        dstBitIndex += significandBitsCount;
      }
    };//end ^convert_significand_integer()

    NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(dstBitInterpretation);
    for(NSUInteger i = 0 ; !result.error && (i<minorPartsCount) ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(dstBitInterpretation, i);
      if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      {
        switch(encodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(encodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  {
                    mp_limb_t dummyLimbs[1] = {0};
                    dummyLimbs[0] = (mpfr_sgn(src) < 0) ? 1 : 0;
                    mp_bitcnt_t signBitsCount = getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, signBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  {
                    mp_limb_t dummyLimbs[(sizeof(mpfr_sign_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_sign_t* dummyLimbsAsSign = (mpfr_sign_t*)dummyLimbs;
                    *dummyLimbsAsSign = src->_mpfr_sign;
                    mp_bitcnt_t signBitsCount = getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, signBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
              }//end switch(encodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(encodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpfr_sgn(src)<0));
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpfr_sgn(src)<0));
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(encodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            {
              switch(encodingVariant.integerStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
                  mpz_changeBit(dst->bits, dstBitIndex++, (mpfr_sgn(src) < 0));
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
                  if (mpfr_sgn(src)<0)
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(encodingVariant.integerStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            {
              switch(encodingVariant.integerCustomVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
                  {
                    size_t dummyLimbsCount = (dstBitInterpretation->signCustomBitsCount+mp_bits_per_limb-1)/mp_bits_per_limb;
                    mp_limb_t* dummyLimbs = calloc(dummyLimbsCount, sizeof(mp_limb_t));
                    if (!dummyLimbs)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (dummyLimbs)
                    {
                      memcpy(dummyLimbs, &src->_mpfr_sign, MIN(sizeof(mpfr_sign_t), dummyLimbsCount*sizeof(mp_limb_t)));
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, dummyLimbsCount, NSMakeRange(0, dstBitInterpretation->signCustomBitsCount), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                      free(dummyLimbs);
                    }//end if (dummyLimb)
                  }
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
                  if (mpfr_sgn(src)<0)
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
                  break;
                case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(encodingVariant.integerCustomVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      {
        switch(encodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(encodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  {
                    mp_limb_t dummyLimbs[(sizeof(mpfr_exp_t)+sizeof(mp_limb_t)-1)/sizeof(mp_limb_t)] = {0};
                    mpfr_exp_t* dummyLimbsAsExp = (mpfr_exp_t*)dummyLimbs;
                    *dummyLimbsAsExp = mpfr_get_exp(src);
                    mp_bitcnt_t exponentBitsCount = getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, exponentBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
              }//end switch(encodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(encodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  if (mpfr_inf_p(src) || mpfr_nan_p(src))
                  {
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    size_t dummyLimbsCount = (exponentBitsCount+mp_bits_per_limb-1)/mp_bits_per_limb;
                    mp_limb_t* dummyLimbs = calloc(dummyLimbsCount, sizeof(mp_limb_t));
                    if (!dummyLimbs)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (dummyLimbs)
                    {
                      memset(dummyLimbs, 0xFF, dummyLimbsCount*sizeof(mp_limb_t));
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, dummyLimbsCount, NSMakeRange(0, exponentBitsCount), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                      free(dummyLimbs);
                    }//end if (dummyLimbs)
                  }//end if (mpfr_inf_p(src) || mpfr_nan_p(src))
                  else//if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  {
                    mpfr_exp_t exponent = mpfr_get_exp(src);
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    NSInteger  exponentMax = (1<<exponentBitsCount)-1;
                    NSInteger  exponentBias = (1<<(exponentBitsCount-1))-1;
                    NSInteger  exponentMin = -exponentBias;
                    size_t dummyLimbsCount = (MAX(8*sizeof(mpfr_exp_t), exponentBitsCount)+mp_bits_per_limb-1)/mp_bits_per_limb;
                    mp_limb_t* dummyLimbs = calloc(dummyLimbsCount, sizeof(mp_limb_t));
                    if (!dummyLimbs)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (dummyLimbs)
                    {
                      if (exponent-1 < exponentMin)
                      {
                        memset(dummyLimbs, 0, sizeof(mp_limb_t));
                        result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW;
                      }//end if (exponent-1 < exponentMin)
                      else if (exponent-1 > exponentMax)
                      {
                        memset(dummyLimbs, 0xFF, sizeof(mp_limb_t));
                        dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                        result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                      }//end if (exponent-1 > exponentMax)
                      else
                      {
                        mpfr_exp_t tmp = exponent-1+exponentBias;
                        memcpy(dummyLimbs, &tmp, MIN(sizeof(mp_limb_t), sizeof(mpfr_exp_t)));
                      }
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, dummyLimbsCount, NSMakeRange(0, exponentBitsCount), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                      free(dummyLimbs);
                    }//end if (dummyLimbs)
                  }//end if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  if (mpfr_inf_p(src) || mpfr_nan_p(src))
                  {
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    size_t dummyLimbsCount = (exponentBitsCount+mp_bits_per_limb-1)/mp_bits_per_limb;
                    mp_limb_t* dummyLimbs = calloc(dummyLimbsCount, sizeof(mp_limb_t));
                    if (!dummyLimbs)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (dummyLimbs)
                    {
                      memset(dummyLimbs, 0xFF, dummyLimbsCount*sizeof(mp_limb_t));
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, dummyLimbsCount, NSMakeRange(0, exponentBitsCount), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                      free(dummyLimbs);
                    }//end if (dummyLimbs)
                  }//end if (mpfr_inf_p(src) || mpfr_nan_p(src))
                  else//if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  {
                    mpfr_exp_t exponent = mpfr_get_exp(src);
                    NSUInteger exponentBitsCount = getExponentBitsCountForEncoding(dstNumberEncoding);
                    NSInteger  exponentMax = (1<<exponentBitsCount)-1;
                    NSInteger  exponentBias = (1<<(exponentBitsCount-1))-1;
                    NSInteger  exponentMin = -exponentBias;
                    size_t dummyLimbsCount = (MAX(8*sizeof(mpfr_exp_t), exponentBitsCount)+mp_bits_per_limb-1)/mp_bits_per_limb;
                    mp_limb_t* dummyLimbs = calloc(dummyLimbsCount, sizeof(mp_limb_t));
                    if (!dummyLimbs)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (dummyLimbs)
                    {
                      if (exponent-1 < exponentMin)
                      {
                        memset(dummyLimbs, 0, sizeof(mp_limb_t));
                        result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW;
                      }//end if (exponent-1 < exponentMin)
                      else if (exponent-1 > exponentMax)
                      {
                        memset(dummyLimbs, 0xFF, sizeof(mp_limb_t));
                        result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                      }//end if (exponent-1 > exponentMax)
                      else
                      {
                        mpfr_exp_t tmp = exponent-1+exponentBias;
                        memcpy(dummyLimbs, &tmp, MIN(sizeof(mp_limb_t), sizeof(mpfr_exp_t)));
                      }
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, dummyLimbs, dummyLimbsCount, NSMakeRange(0, exponentBitsCount), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                      free(dummyLimbs);
                    }//end if (dummyLimbs)
                  }//end if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(encodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            result.error = CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT;
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
      else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
      {
        switch(encodingType)
        {
          case CHALK_NUMBER_ENCODING_GMP_STANDARD:
          case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
            {
              switch(encodingVariant.gmpStandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
                  if (mpfr_nan_p(src))
                    result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                  else if (mpfr_inf_p(src))
                    result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                  else if (mpfr_get_exp(src)<0)
                    result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW | CHALK_COMPUTE_FLAG_ERANGE;
                  else if (mpfr_get_exp(src) > [chalkContext softIntegerMaxDigitsWithBase:2])
                  {
                    dst->flags |= CHALK_RAW_VALUE_FLAG_INFINITY;
                    result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW | CHALK_COMPUTE_FLAG_ERANGE;
                  }//end if (mpfr_get_exp(src) > [chalkContext softIntegerMaxDigitsWithBase:2])
                  else//if (mpfr_get_exp(src) <= [chalkContext softIntegerMaxDigitsWithBase:2])
                  {
                    if (!srcZInitialized)
                    {
                      mpzDepool(srcZ, chalkContext.gmpPool);
                      srcZInitialized = YES;
                    }//end if (!srcZInitialized)
                    if (!srcZInitialized)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else//if (srcZInitialized)
                    {
                      mpz_set_fr(srcZ, src, MPFR_RNDN);
                      mpfr_prec_t prec = mpfr_get_prec(src);
                      prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                      BOOL error = NO;
                      mpz_copyBits(dst->bits, dstBitIndex, mpz_limbs_read(srcZ), mpz_size(srcZ), NSMakeRange(0, prec), &error);
                      if (error)
                        result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                      dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                    }//end if (srcZInitialized)
                  }//end if (mpfr_get_exp(src) <= [chalkContext softIntegerMaxDigitsWithBase:2])
                  break;
                case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
                  {
                    mpfr_prec_t prec = mpfr_get_prec(src);
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t limbsBitsCount = limbsCount*mp_bits_per_limb;
                    size_t paddingBitsCount = limbsBitsCount-prec;
                    size_t significandBitsCount = limbsBitsCount-paddingBitsCount;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, src->_mpfr_d, limbsCount, NSMakeRange(paddingBitsCount, significandBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }
                  break;
              }//end switch(encodingVariant.gmpStandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
            {
              switch(encodingVariant.ieee754StandardVariantEncoding)
              {
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
                  if (mpfr_inf_p(src))
                  {
                    mp_limb_t dummyLimb = 0;//significand must be 0
                    NSRange bitsRange = NSMakeRange(0, getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart));
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, &dummyLimb, 1, bitsRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (mpfr_inf_p(src))
                  else if (mpfr_nan_p(src))
                  {//significand must *not* be 0
                    NSUInteger significandBits = getSignificandBitsCountForEncoding(dstNumberEncoding, NO);
                    size_t srcLimbsCount = (mpfr_get_prec(src)+mp_bits_per_limb-1)/mp_bits_per_limb;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, src->_mpfr_d, srcLimbsCount, NSMakeRange(0, significandBits), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    if (mpz_scan1(dst->bits, dstBitIndex)>=dstBitIndex+significandBits)//problem : all bits are 0
                      mpz_setbit(dst->bits, dstBitIndex);
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (mpfr_nan_p(src))
                  else//if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  {
                    NSUInteger significandBits = getSignificandBitsCountForEncoding(dstNumberEncoding, NO);
                    mpfr_prec_t prec = significandBits+1;//+1 because GMP MSB
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    mpfr_t rounded;
                    mpfrDepool(rounded, prec, chalkContext.gmpPool);
                    mpfr_set(rounded, src, MPFR_RNDN);
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t remains = limbsCount*mp_bits_per_limb-prec;
                    NSRange srcRange = NSMakeRange(remains, significandBits);
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, rounded->_mpfr_d, limbsCount, srcRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    NSUInteger srcLimbsCount = (src->_mpfr_prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    NSRange srcFullRange = NSMakeRange(0, srcLimbsCount*mp_bits_per_limb);
                    NSRange srcSignificandRange = NSIntersectionRange(srcFullRange,
                      NSMakeRange(NSMaxRange(srcFullRange)-src->_mpfr_prec, src->_mpfr_prec));
                    NSRange srcLostRange = (srcRange.length >= srcSignificandRange.length) ? NSRangeZero :
                      NSMakeRange(srcFullRange.location, srcFullRange.length-srcRange.length);
                    BOOL hasLostSignificandDigits = !mpn_zero_range_p(src->_mpfr_d, srcLimbsCount, srcLostRange);
                    if (hasLostSignificandDigits)
                    {
                      mpfr_set_inexflag();
                      mpfr_set_underflow();
                    }//end if (hasLostSignificandDigits)
                    mpfrRepool(rounded, chalkContext.gmpPool);
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
                  if (mpfr_inf_p(src))
                  {
                    mp_limb_t dummyLimb = 0;//significand must be 0
                    NSRange bitsRange = NSMakeRange(0, getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart));
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, &dummyLimb, 1, bitsRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (mpfr_inf_p(src))
                  else if (mpfr_nan_p(src))
                  {//significand must *not* be 0
                    NSUInteger significandBits = getSignificandBitsCountForEncoding(dstNumberEncoding, NO);
                    size_t srcLimbsCount = (mpfr_get_prec(src)+mp_bits_per_limb-1)/mp_bits_per_limb;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, src->_mpfr_d, srcLimbsCount, NSMakeRange(0, significandBits), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    if (mpz_scan1(dst->bits, dstBitIndex)>=dstBitIndex+significandBits)//problem : all bits are 0
                      mpz_setbit(dst->bits, dstBitIndex);
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (mpfr_nan_p(src))
                  else//if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  {
                    NSUInteger significandBits = getSignificandBitsCountForEncoding(dstNumberEncoding, NO);
                    mpfr_prec_t prec = significandBits+1;//+1 because GMP MSB
                    prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                    mpfr_t rounded;
                    mpfrDepool(rounded, prec, chalkContext.gmpPool);
                    mpfr_set(rounded, src, MPFR_RNDN);
                    size_t limbsCount = (prec+mp_bits_per_limb-1)/mp_bits_per_limb;
                    size_t remains = limbsCount*mp_bits_per_limb-prec;
                    BOOL error = NO;
                    mpz_copyBits(dst->bits, dstBitIndex, rounded->_mpfr_d, limbsCount, NSMakeRange(remains, significandBits), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    mpfrRepool(rounded, chalkContext.gmpPool);
                    dstBitIndex += getMinorPartBitsCountForBitInterpretation(dstBitInterpretation, minorPart);
                  }//end if (!mpfr_inf_p(src) && !mpfr_nan_p(src))
                  break;
                case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
                  result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                  break;
              }//end switch(encodingVariant.ieee754StandardVariantEncoding)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
            {
              if (!srcZInitialized)
              {
                mpzDepool(srcZ, chalkContext.gmpPool);
                srcZInitialized = YES;
              }//end if (!srcZInitialized)
              if (!srcZInitialized)
                result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
              else//if (srcZInitialized)
              {
                switch(encodingVariant.integerStandardVariantEncoding)
                {
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
                    convert_significand_integer(srcZ,
                      getTotalBitsCountForBitInterpretation(dstBitInterpretation),
                      (getSignBitsCountForBitInterpretation(dstBitInterpretation)>0));
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    break;
                }//end switch(encodingVariant.integerStandardVariantEncoding)
              }//end if (srcZInitialized)
            }
            break;
          case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
            {
              if (!srcZInitialized)
              {
                mpzDepool(srcZ, chalkContext.gmpPool);
                srcZInitialized = YES;
              }//end if (!srcZInitialized)
              if (!srcZInitialized)
                result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
              else//if (srcZInitialized)
              {
                switch(encodingVariant.integerCustomVariantEncoding)
                {
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
                    convert_significand_integer(srcZ,
                      getTotalBitsCountForBitInterpretation(dstBitInterpretation),
                      (getSignBitsCountForBitInterpretation(dstBitInterpretation)>0));
                    break;
                  case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    break;
                }//end switch(encodingVariant.integerCustomVariantEncoding)
              }//end if (srcZInitialized)
            }
            break;
          case CHALK_NUMBER_ENCODING_UNDEFINED:
            result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
            break;
        }//end switch(encodingType)
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    }//end for each minorPartOrdered
    
    if (dst->flags & CHALK_RAW_VALUE_FLAG_INFINITY)
      mpz_set_zero(dst->bits, getSignificandBitsRangeForBitInterpretation(dstBitInterpretation, NO));
    
    if (srcZInitialized)
      mpzRepool(srcZ, chalkContext.gmpPool);
    result.computeFlags |= chalkGmpFlagsMake();
    chalkGmpFlagsRestore(oldFlags);
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromValueToRawFR()

chalk_conversion_result_t convertFromValueToRawFIR(chalk_raw_value_t* dst, mpfir_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND)
      result = convertFromValueToRawFR(dst, &src->interval.left, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND)
      result = convertFromValueToRawFR(dst, &src->interval.right, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE)
      result = convertFromValueToRawFR(dst, &src->estimation, dstBitInterpretation, chalkContext);
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromValueToRawFIR()

chalk_conversion_result_t convertFromRawToValue(chalk_gmp_value_t* dst, const chalk_raw_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dst->type == CHALK_VALUE_TYPE_INTEGER)
      result = convertFromRawToValueZ(dst->integer, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_FRACTION)
      result = convertFromRawToValueQ(dst->fraction, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = convertFromRawToValueFR(dst->realExact, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = convertFromRawToValueFR(&dst->realApprox->estimation, src, dstBitInterpretation, chalkContext);
      else
        result = convertFromRawToValueFIR(dst->realApprox, src, dstBitInterpretation, chalkContext);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromRawToValue()

chalk_conversion_result_t convertFromRawToValueZ(mpz_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  __block chalk_conversion_result_t result = {0};
  const chalk_bit_interpretation_t* srcBitInterpretation = !src ? 0 : &src->bitInterpretation;
  if (src && dst && srcBitInterpretation && dstBitInterpretation)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);

    chalk_number_encoding_t srcNumberEncoding = srcBitInterpretation->numberEncoding;
    chalk_number_encoding_type_t srcEncodingType = srcNumberEncoding.encodingType;
    chalk_number_encoding_variant_t srcEncodingVariant = srcNumberEncoding.encodingVariant;
    chalk_number_encoding_t dstNumberEncoding = dstBitInterpretation->numberEncoding;
    BOOL isDstIntegerUnsigned = getEncodingIsUnsignedInteger(dstNumberEncoding);

    switch(srcEncodingType)
    {
      case CHALK_NUMBER_ENCODING_UNDEFINED:
        result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD:
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
        {
          switch(srcEncodingVariant.gmpStandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isNegative = (mpz_cmp_si(signZ, 0)>0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                if (!result.error)
                {
                  mpz_set_si(dst, 0);
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                }//end if (!result.error)
                
                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z
              break;
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mpfr_sign_t* limbAsSign = (mpfr_sign_t*)mpz_limbs_read(signZ);
                  isNegative = limbAsSign && (*limbAsSign<0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                if (!result.error)
                {
                  const mp_limb_t* srcLimbs = mpz_limbs_read(src->bits);
                  const size_t srcLimbsCount = mpz_size(src->bits);
                  const size_t limbIndexForMSB = (NSMaxRange(significandMinorPartRange_safe)-1)/mp_bits_per_limb;
                  const size_t MSBIndexInMSBLimb = (NSMaxRange(significandMinorPartRange_safe)-1)%mp_bits_per_limb;
                  BOOL msb = !srcLimbs || (limbIndexForMSB>=srcLimbsCount) ? NO :
                    ((srcLimbs[limbIndexForMSB]&(MP_LIMB_ONE<<MSBIndexInMSBLimb)) != 0);
                  if (!msb)
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND;
                  else//if (msb)
                  {
                    BOOL error = NO;
                    mpz_copyBits(dst, 0, srcLimbs, srcLimbsCount, significandMinorPartRange_safe, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  }//end if (msb)
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  mpfr_t exponentWrapper;
                  mpfrDepool(exponentWrapper, MPFR_PREC_MIN, chalkContext.gmpPool);
                  mpfr_set_si(exponentWrapper, 1, MPFR_RNDN);
                  mpz_t exponentZ;
                  mpzDepool(exponentZ, chalkContext.gmpPool);
                  mpz_set_ui(exponentZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else if (mpz_sizeinbase(exponentZ, 2)>8*sizeof(mpfr_exp_t))
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                  else//if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                  {
                    mpfr_exp_t exponent = (mpfr_exp_t)mpz_get_si(exponentZ);
                    exponentWrapper->_mpfr_exp = exponent;
                    if (mpfr_inf_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                    }//end if (mpfr_inf_p(exponentWrapper))
                    else if (mpfr_nan_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                    }//end if (mpfr_nan_p(exponentWrapper))
                    else if (mpfr_zero_p(exponentWrapper))//special zero exponent
                      mpz_set_si(dst, 0);
                    else//regular exponent
                    {
                      NSUInteger maxIntegerBits = [chalkContext softIntegerMaxDigitsWithBase:2];
                      mp_bitcnt_t firstOne = mpz_scan1(dst, 0);
                      mp_bitcnt_t dstTotalBits = mpz_sizeinbase(dst, 2);
                      mp_bitcnt_t fracPartBits = ((exponent>=0) && (dstTotalBits<(mpfr_uexp_t)(exponent))) ? 0 :
                        (exponent>=0) ? (dstTotalBits-exponent) : (dstTotalBits+((mpfr_uexp_t)(-exponent)));
                      if (exponent<0)
                      {
                        result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW;
                        mpz_set_si(dst, 0);
                      }//end if (exponent<0)
                      else//if (exponent>=0)
                      {
                        if (exponent>=maxIntegerBits)
                        {
                          result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                          mpz_realloc2(dst, maxIntegerBits);
                        }//end if (exponent>=maxIntegerBits)
                        else//if (exponent<maxIntegerBits)
                        {
                          if (exponent>=dstTotalBits)
                            mpz_mul_2exp(dst, dst, exponent-dstTotalBits);
                          else//if (exponent<fracPartBits)
                          {
                            if (firstOne<fracPartBits)
                              result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                            BOOL shouldRoundUp = fracPartBits && mpz_tstbit(dst, fracPartBits-1);
                            mpz_div_2exp(dst, dst, fracPartBits);
                            if (shouldRoundUp)
                              mpz_add_ui(dst, dst, 1);
                          }//end if (exponent<fracPartBits)
                        }//end if (exponent<maxIntegerBits)
                      }//end if (exponent>=0)
                    }//end regular exponent
                  }//end if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                  mpzRepool(exponentZ, chalkContext.gmpPool);
                  mpfrRepool(exponentWrapper, chalkContext.gmpPool);
                }//end if (!result.error)
                
                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR
              break;
          }//end switch(srcEncodingVariant.gmpStandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_GMP_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
        {
          switch(srcEncodingVariant.ieee754StandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isNegative = (mpz_cmp_si(signZ, 0) != 0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                BOOL isZeroSignificand = NO;
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isZeroSignificand = !mpz_cmp_si(dst, 0);
                  mpz_setbit(dst, significandMinorPartRange_safe.length);//1 is implicit in IEEE754
                }//end if (!result.error)
                
                //exponent
                BOOL isSpecialExponent = NO;
                if (!result.error)
                {
                  mpfr_t exponentWrapper;
                  mpfrDepool(exponentWrapper, MPFR_PREC_MIN, chalkContext.gmpPool);
                  mpfr_set_si(exponentWrapper, 1, MPFR_RNDN);
                  mpz_t exponentZ;
                  mpzDepool(exponentZ, chalkContext.gmpPool);
                  mpz_set_ui(exponentZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isSpecialExponent = (mpz_scan0(exponentZ, 0)>=exponentMinorPartRange.length);
                  if (isSpecialExponent)
                  {
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                    if (isZeroSignificand)
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                    else//if (!isZeroSignificand)
                      result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                  }//if (isSpecialExponent)
                  else//if (!isSpecialExponent)
                  {
                    mpz_t exponentBiasZ;
                    mpzDepool(exponentBiasZ, chalkContext.gmpPool);
                    mpz_set_si(exponentBiasZ, 1);
                    mpz_mul_2exp(exponentBiasZ, exponentBiasZ, getExponentBitsCountForEncoding(srcNumberEncoding)-1);
                    mpz_sub_ui(exponentBiasZ, exponentBiasZ, 1);
                    mpz_sub(exponentZ, exponentZ, exponentBiasZ);
                    mpz_add_ui(exponentZ, exponentZ, 1);//because of added implicit 1
                    mpzRepool(exponentBiasZ, chalkContext.gmpPool);

                    mpfr_exp_t exponent = (mpfr_exp_t)mpz_get_si(exponentZ);
                    exponentWrapper->_mpfr_exp = exponent;
                    if (mpfr_inf_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                    }//end if (mpfr_inf_p(exponentWrapper))
                    else if (mpfr_nan_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                    }//end if (mpfr_nan_p(exponentWrapper))
                    else if (mpfr_zero_p(exponentWrapper))//special zero exponent
                      mpz_set_si(dst, 0);
                    else//regular exponent
                    {
                      NSUInteger maxIntegerBits = [chalkContext softIntegerMaxDigitsWithBase:2];
                      mp_bitcnt_t firstOne = mpz_scan1(dst, 0);
                      mp_bitcnt_t dstTotalBits = mpz_sizeinbase(dst, 2);
                      mp_bitcnt_t fracPartBits = ((exponent>=0) && (dstTotalBits<(mpfr_uexp_t)(exponent))) ? 0 :
                        (exponent>=0) ? (dstTotalBits-exponent) : (dstTotalBits+((mpfr_uexp_t)(-exponent)));
                      if (exponent<0)
                      {
                        result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW;
                        mpz_set_si(dst, 0);
                      }//end if (exponent<0)
                      else//if (exponent>=0)
                      {
                        if (exponent>=maxIntegerBits)
                        {
                          result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                          mpz_realloc2(dst, maxIntegerBits);
                        }//end if (exponent>=maxIntegerBits)
                        else//if (exponent<maxIntegerBits)
                        {
                          if (exponent>=dstTotalBits)
                            mpz_mul_2exp(dst, dst, exponent-dstTotalBits);
                          else//if (exponent<fracPartBits)
                          {
                            if (firstOne<fracPartBits)
                              result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                            BOOL shouldRoundUp = fracPartBits && mpz_tstbit(dst, fracPartBits-1);
                            mpz_div_2exp(dst, dst, fracPartBits);
                            if (shouldRoundUp)
                              mpz_add_ui(dst, dst, 1);
                          }//end if (exponent<fracPartBits)
                        }//end if (exponent<maxIntegerBits)
                      }//end if (exponent>=0)
                    }//end regular exponent
                  }//end if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                  mpzRepool(exponentZ, chalkContext.gmpPool);
                  mpfrRepool(exponentWrapper, chalkContext.gmpPool);
                }//end if (!result.error)
                
                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_...
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isNegative = (mpz_cmp_si(signZ, 0) != 0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                BOOL isZeroSignificand = NO;
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isZeroSignificand = !mpz_cmp_si(dst, 0);
                  mpz_setbit(dst, significandMinorPartRange_safe.length);//1 is implicit in IEEE754
                }//end if (!result.error)
                
                //exponent
                BOOL isSpecialExponent = NO;
                if (!result.error)
                {
                  mpfr_t exponentWrapper;
                  mpfrDepool(exponentWrapper, MPFR_PREC_MIN, chalkContext.gmpPool);
                  mpfr_set_si(exponentWrapper, 1, MPFR_RNDN);
                  mpz_t exponentZ;
                  mpzDepool(exponentZ, chalkContext.gmpPool);
                  mpz_set_ui(exponentZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isSpecialExponent = (mpz_scan0(exponentZ, 0)>=exponentMinorPartRange.length);
                  if (isSpecialExponent)
                  {
                    result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                    if (isZeroSignificand)
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                    else//if (!isZeroSignificand)
                      result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                  }//if (isSpecialExponent)
                  else//if (!isSpecialExponent)
                  {
                    mpz_t exponentBiasZ;
                    mpzDepool(exponentBiasZ, chalkContext.gmpPool);
                    mpz_set_si(exponentBiasZ, 1);
                    mpz_mul_2exp(exponentBiasZ, exponentBiasZ, getExponentBitsCountForEncoding(srcNumberEncoding)-1);
                    mpz_sub_ui(exponentBiasZ, exponentBiasZ, 1);
                    mpz_sub(exponentZ, exponentZ, exponentBiasZ);
                    mpz_add_ui(exponentZ, exponentZ, 1);//because of added implicit 1
                    mpzRepool(exponentBiasZ, chalkContext.gmpPool);

                    mpfr_exp_t exponent = (mpfr_exp_t)mpz_get_si(exponentZ);
                    exponentWrapper->_mpfr_exp = exponent;
                    if (mpfr_inf_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE | CHALK_COMPUTE_FLAG_OVERFLOW;
                    }//end if (mpfr_inf_p(exponentWrapper))
                    else if (mpfr_nan_p(exponentWrapper))
                    {
                      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
                      result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                    }//end if (mpfr_nan_p(exponentWrapper))
                    else if (mpfr_zero_p(exponentWrapper))//special zero exponent
                      mpz_set_si(dst, 0);
                    else//regular exponent
                    {
                      NSUInteger maxIntegerBits = [chalkContext softIntegerMaxDigitsWithBase:2];
                      mp_bitcnt_t firstOne = mpz_scan1(dst, 0);
                      mp_bitcnt_t dstTotalBits = mpz_sizeinbase(dst, 2);
                      mp_bitcnt_t fracPartBits = ((exponent>=0) && (dstTotalBits<(mpfr_uexp_t)(exponent))) ? 0 :
                        (exponent>=0) ? (dstTotalBits-exponent) : (dstTotalBits+((mpfr_uexp_t)(-exponent)));
                      if (exponent<0)
                      {
                        result.computeFlags |= CHALK_COMPUTE_FLAG_UNDERFLOW;
                        mpz_set_si(dst, 0);
                      }//end if (exponent<0)
                      else//if (exponent>=0)
                      {
                        if (exponent>=maxIntegerBits)
                        {
                          result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                          mpz_realloc2(dst, maxIntegerBits);
                        }//end if (exponent>=maxIntegerBits)
                        else//if (exponent<maxIntegerBits)
                        {
                          if (exponent>=dstTotalBits)
                            mpz_mul_2exp(dst, dst, exponent-dstTotalBits);
                          else//if (exponent<fracPartBits)
                          {
                            if (firstOne<fracPartBits)
                              result.computeFlags |= CHALK_COMPUTE_FLAG_OVERFLOW|CHALK_COMPUTE_FLAG_INEXACT;
                            BOOL shouldRoundUp = fracPartBits && mpz_tstbit(dst, fracPartBits-1);
                            mpz_div_2exp(dst, dst, fracPartBits);
                            if (shouldRoundUp)
                              mpz_add_ui(dst, dst, 1);
                          }//end if (exponent<fracPartBits)
                        }//end if (exponent<maxIntegerBits)
                      }//end if (exponent>=0)
                    }//end regular exponent
                  }//end if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                  mpzRepool(exponentZ, chalkContext.gmpPool);
                  mpfrRepool(exponentWrapper, chalkContext.gmpPool);
                }//end if (!result.error)
                
                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION
              break;
          }//end switch(srcEncodingVariant.ieee754StandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
        {
          switch(srcEncodingVariant.integerStandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isNegative = (mpz_cmp_si(signZ, 0) != 0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  if (isNegative)
                    mpz_complement2(dst, NSMakeRange(0, significandMinorPartRange_safe.length));
                }//end if (!result.error)

                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_...S
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //significand
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                }//end if (!result.error)
              }//end CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_...U
              break;
          }//end switch(srcEncodingVariant.integerStandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
        {
          switch(srcEncodingVariant.integerCustomVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                BOOL isNegative = NO;
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  isNegative = (mpz_cmp_si(signZ, 0) != 0);
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  if (isNegative)
                    mpz_complement2(dst, NSMakeRange(0, significandMinorPartRange_safe.length));
                }//end if (!result.error)

                if (result.error){
                }
                else if (isNegative && (mpz_sgn(dst)>0))
                  mpz_neg(dst, dst);
                else if (!isNegative && (mpz_sgn(dst)<0))
                  mpz_neg(dst, dst);
              }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
              {
                NSRange srcMaxRange = getTotalBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //significand
                if (!result.error)
                {
                  BOOL error = NO;
                  mpz_copyBits(dst, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                }//end if (!result.error)
              }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED
              break;
          }//end switch(srcEncodingVariant.integerCustomVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM
        break;
    }//end switch(srcEncodingType)
    
    if (!result.error && isDstIntegerUnsigned && (mpz_sgn(dst)<0))
    {
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
      mpz_set_si(dst, 0);
    }//end if (!result.error && isDstIntegerUnsigned && (mpz_sgn(dst)<0))

    result.computeFlags |= chalkGmpFlagsMake();
    chalkGmpFlagsRestore(oldFlags);
  }//end if (src && dst && srcBitInterpretation && dstBitInterpretation)
  return result;
}
//end convertFromRawToValueZ()

chalk_conversion_result_t convertFromRawToValueQ(mpq_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR)
      result = convertFromRawToValueZ(mpq_numref(dst), src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR)
      result = convertFromRawToValueZ(mpq_denref(dst), src, dstBitInterpretation, chalkContext);
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromRawToValueQ()

static void checkMpfr(mpfr_ptr dst, const chalk_bit_interpretation_t* dstBitInterpretation, chalk_conversion_result_t* result)
{
  if (result && !result->error)
  {
    //various checks
    size_t dstLimbsCount = (dst->_mpfr_prec+mp_bits_per_limb-1)/mp_bits_per_limb;
    if (!result->error)
    {
      const mp_limb_t* dstMsbLimb = !dst->_mpfr_d || !dstLimbsCount ? 0 : &dst->_mpfr_d[dstLimbsCount-1];
      BOOL msb = dstMsbLimb && ((*dstMsbLimb & (MP_LIMB_ONE<<(mp_bits_per_limb-1))) != 0);
      if (!msb)
        result->error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND;
    }//end if (!result->error)
    if (!result->error)
    {
      const mp_limb_t* dstLsbLimb = !dst->_mpfr_d || !dstLimbsCount ? 0 : &dst->_mpfr_d[0];
      mp_bitcnt_t extraBits = mp_bits_per_limb*((dst->_mpfr_prec+mp_bits_per_limb-1)/mp_bits_per_limb)-dst->_mpfr_prec;
      BOOL dstIsZeroExtraBits = (mpn_zero_range_p(dstLsbLimb, 1, NSMakeRange(0, extraBits)) != 0);
      if (!dstIsZeroExtraBits)
        result->error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND;
    }//end if (!result->error)
    if (!result->error)
    {
      BOOL dstIsZeroSignificand = (mpn_zero_range_p(dst->_mpfr_d, dstLimbsCount, getSignBitsRangeForBitInterpretation(dstBitInterpretation)) != 0);
      if (!dstIsZeroSignificand && !dst->_mpfr_sign)
        result->error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
    }//end if (!result->error)
    if (result->error)
      mpfr_set_nan(dst);
  }//end if (result && !result->error)
}
//end checkMpfr()
                
chalk_conversion_result_t convertFromRawToValueFR(mpfr_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  __block chalk_conversion_result_t result = {0};
  const chalk_bit_interpretation_t* srcBitInterpretation = !src ? 0 : &src->bitInterpretation;
  if (src && dst && srcBitInterpretation && dstBitInterpretation)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);

    chalk_number_encoding_t srcNumberEncoding = srcBitInterpretation->numberEncoding;
    chalk_number_encoding_type_t srcEncodingType = srcNumberEncoding.encodingType;
    chalk_number_encoding_variant_t srcEncodingVariant = srcNumberEncoding.encodingVariant;
    chalk_number_encoding_t dstNumberEncoding = dstBitInterpretation->numberEncoding;
    BOOL isDstIntegerUnsigned = getEncodingIsUnsignedInteger(dstNumberEncoding);

    switch(srcEncodingType)
    {
      case CHALK_NUMBER_ENCODING_UNDEFINED:
        result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD:
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
        {
          switch(srcEncodingVariant.gmpStandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                BOOL isZeroSignificand = NO;
                mpfr_prec_t unroundedPrec = 0;
                mpfr_exp_t expOffset = 0;
                if (!result.error)
                {
                  unroundedPrec = significandMinorPartRange.length;
                  unroundedPrec = MIN(MPFR_PREC_MAX, unroundedPrec);
                  mpfr_prec_t adaptedPrec = MAX(MPFR_PREC_MIN, unroundedPrec);
                  mpfr_prec_round(dst, adaptedPrec, MPFR_RNDN);
                  mp_bitcnt_t totalBitsCount = ((unroundedPrec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                  expOffset = significandMinorPartRange.length-mpz_sizeinbase(src->bits, 2);
                  mp_bitcnt_t offset = totalBitsCount-unroundedPrec+expOffset;
                  mp_size_t limbsCount = totalBitsCount/mp_bits_per_limb;
                  mpn_zero(dst->_mpfr_d, limbsCount);
                  BOOL error = NO;
                  NSRange usefulSignificandRange = NSIntersectionRange(significandMinorPartRange_safe, NSMakeRange(significandMinorPartRange.location, significandMinorPartRange.length-expOffset));
                  mpfr_copyBits(dst, offset, mpz_limbs_read(src->bits), mpz_size(src->bits), usefulSignificandRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mp_bitcnt_t first1Bit = mpz_scan1(src->bits, significandMinorPartRange_safe.location);
                  isZeroSignificand |= (first1Bit >= NSMaxRange(significandMinorPartRange_safe));
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  if (isZeroSignificand)
                    mpfr_set_zero(dst, MAX((dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0, 0));
                  else//if (!isZeroSignificand)
                  {
                    mpfr_exp_t dstExp = unroundedPrec-expOffset;
                    if ((dstExp<mpfr_get_emin()) || (dstExp>mpfr_get_emax()))
                    {
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      mpfr_set_zero(dst, 0);
                    }//end if ((dstExp<mpfr_get_emin()) || (dstExp>mpfr_get_emax()))
                    else//if ((dstExp>=mpfr_get_emin()) && (dstExp<=mpfr_get_emax()))
                      dst->_mpfr_exp = dstExp;
                  }//end if (!isZeroSignificand)
                }//end if (!result.error)
                
                checkMpfr(dst, dstBitInterpretation, &result);
              }
              break;
            case CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = *((mpfr_sign_t*)mpz_limbs_read(signZ));
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                mpfr_prec_t unroundedPrec = 0;
                if (!result.error)
                {
                  mp_bitcnt_t srcPrecRaw = getSignificandBitsCountForBitInterpretation(srcBitInterpretation, NO);
                  mp_bitcnt_t srcPrecFull = getSignificandBitsCountForBitInterpretation(srcBitInterpretation, YES);
                  BOOL hasSrcImpliedBit = (srcPrecFull>srcPrecRaw);
                  mp_bitcnt_t dstPrecRaw = getSignificandBitsCountForBitInterpretation(dstBitInterpretation, NO);
                  mp_bitcnt_t dstPrecFull = getSignificandBitsCountForBitInterpretation(dstBitInterpretation, YES);
                  mpfr_prec_round(dst, dstPrecFull, MPFR_RNDN);
                  size_t dstLimbsCount = (dstPrecFull+mp_bits_per_limb-1)/mp_bits_per_limb;
                  mp_bitcnt_t dstTotalBits = dstLimbsCount*mp_bits_per_limb;
                  mpn_zero(dst->_mpfr_d, dstLimbsCount);
                  const mp_limb_t* srcLimbs = mpz_limbs_read(src->bits);
                  const size_t srcLimbsCount = mpz_size(src->bits);
                  NSRange dstRange = hasSrcImpliedBit ? NSMakeRange(0, dstPrecRaw) : NSMakeRange(0, dstPrecFull);
                  NSRange srcRange = (significandMinorPartRange_safe.length >= dstRange.length) ?
                    NSMakeRange(NSMaxRange(significandMinorPartRange_safe)-dstRange.length, dstRange.length) :
                    significandMinorPartRange_safe;
                  mp_bitcnt_t dstOffset = (dstPrecFull<dstTotalBits) ? (dstTotalBits-dstPrecFull) : 0;
                  BOOL error = NO;
                  mpfr_copyBits(dst, dstOffset, srcLimbs, srcLimbsCount, srcRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  if (hasSrcImpliedBit)
                    dst->_mpfr_d[dstLimbsCount-1] |= (((mp_limb_t)1UL)<<(mp_bits_per_limb-1));
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  const mp_limb_t* srcLimbs = mpz_limbs_read(src->bits);
                  const size_t srcLimbsCount = mpz_size(src->bits);
                  BOOL isSrcZeroSignificand = (mpn_zero_range_p(srcLimbs, srcLimbsCount, significandMinorPartRange_safe) != 0);
                  if (isSrcZeroSignificand)
                  {
                    BOOL isGmpFr =
                      ((src->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD) &&
                       (src->bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR)) ||
                      ((src->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
                       (src->bitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding == CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR));
                    if (isGmpFr)
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND;
                    else
                      mpfr_set_zero(dst, (dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0);
                  }//end if (isSrcZeroSignificand)
                  else//if (!isSrcZeroSignificand)
                  {
                    mpz_t exponentZ;
                    mpzDepool(exponentZ, chalkContext.gmpPool);
                    mpz_set_ui(exponentZ, 0);
                    BOOL error = NO;
                    mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                    else if (mpz_sizeinbase(exponentZ, 2)>8*sizeof(mpfr_exp_t))
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                    else//if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                    {
                      memcpy(&dst->_mpfr_exp, exponentZ->_mp_d, MIN(sizeof(mp_limb_t), sizeof(mpfr_exp_t)));
                      if (mpfr_inf_p(dst))
                        result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                      else if (mpfr_nan_p(dst))
                        result.computeFlags |= CHALK_COMPUTE_FLAG_NAN;
                      else if (mpfr_zero_p(dst))//special zero exponent
                        mpfr_set_zero(dst, (dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0);
                      else if ((dst->_mpfr_exp<mpfr_get_emin()) || (dst->_mpfr_exp>mpfr_get_emax()))
                      {
                        result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                        mpfr_set_zero(dst, 0);
                      }//end if ((dst->_mpfr_exp<mpfr_get_emin()) || (dst->_mpfr_exp>mpfr_get_emax()))
                    }//end if (mpz_sizeinbase(exponentZ, 2)<=8*sizeof(mpfr_exp_t))
                    mpzRepool(exponentZ, chalkContext.gmpPool);
                  }//end if (!isSrcZeroSignificand)
                }//end if (!result.error)
                checkMpfr(dst, dstBitInterpretation, &result);
              }//end if (!result.error)
              break;
          }//end switch(srcEncodingVariant.gmpStandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_GMP_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
        {
          switch(srcEncodingVariant.ieee754StandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_si(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                BOOL isSpecialExponent = NO;
                if (!result.error)
                {
                  exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                  mpz_t exponentZ;
                  mpzDepool(exponentZ, chalkContext.gmpPool);
                  mpz_set_ui(exponentZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mp_bitcnt_t firstZeroBitIndex = !exponentMinorPartRange.length ? 0 : mpz_scan0(exponentZ, 0);
                  isSpecialExponent |= exponentMinorPartRange.length &&
                    (firstZeroBitIndex >= getExponentBitsCountForEncoding(srcNumberEncoding));
                  if (!isSpecialExponent)
                  {
                    mpz_t exponentBiasZ;
                    mpzDepool(exponentBiasZ, chalkContext.gmpPool);
                    mpz_set_si(exponentBiasZ, 1);
                    mpz_mul_2exp(exponentBiasZ, exponentBiasZ, getExponentBitsCountForEncoding(srcNumberEncoding)-1);
                    mpz_sub_ui(exponentBiasZ, exponentBiasZ, 1);
                    mpz_sub(exponentZ, exponentZ, exponentBiasZ);
                    mpz_add_ui(exponentZ, exponentZ, 1);//+1 because GMP needs MSB set to 1
                    mpzRepool(exponentBiasZ, chalkContext.gmpPool);
                    if (!result.error)
                    {
                      if ((mpz_cmp_si(exponentZ, mpfr_get_emin())<0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())>0))
                      {
                        result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                        result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      }//end if ((mpz_cmp_si(exponentZ, mpfr_get_emin())<0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())>0))
                      else//if ((mpz_cmp_si(exponentZ, mpfr_get_emin())>=0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())<=0))
                        memcpy(&dst->_mpfr_exp, exponentZ->_mp_d, MIN(sizeof(mp_limb_t), sizeof(mpfr_exp_t)));
                    }//end if (!result.error)
                  }//end if (!isSpecialExponent)
                  mpzRepool(exponentZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                BOOL isZeroSignificand = NO;
                if (!result.error)
                {
                  mp_bitcnt_t first1Bit = mpz_scan1(src->bits, significandMinorPartRange_safe.location);
                  isZeroSignificand |= (first1Bit >= NSMaxRange(significandMinorPartRange_safe));
                  mpfr_prec_t prec = significandMinorPartRange.length+1;//+1 because GMP needs MSB set to 1
                  prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                  mpfr_prec_round(dst, prec, MPFR_RNDN);
                  mp_bitcnt_t totalBitsCount = ((prec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                  mp_bitcnt_t offset = totalBitsCount-prec;
                  mpn_zero(dst->_mpfr_d, totalBitsCount/mp_bits_per_limb);
                  BOOL error = NO;
                  mpfr_copyBits(dst, offset, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  offset += significandMinorPartRange_safe.length;
                  mp_limb_t dummyLimbs[1] = {1};
                  mpfr_copyBits(dst, offset, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, 1), &error);//MSB
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mpfr_prec_round(dst, prec, MPFR_RNDN);//mpfr_copyBits may have changed prec to ensure enough space
                }//end if (!result.error)
                
                if (isZeroSignificand)
                {
                  if (isSpecialExponent)
                  {
                    mpfr_set_inf(dst, (dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0);
                    mpfr_set_erangeflag();
                  }//end if (isSpecialExponent)
                }//end if (isZeroSignificand)
                else//if (!isZeroSignificand)
                {
                  if (isSpecialExponent)
                  {
                    mpfr_set_nan(dst);
                    mpfr_set_nanflag();
                  }//end if (isSpecialExponent)
                }//end if (!isZeroSignificand)
              }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_...
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange exponentMinorPartRange = getExponentBitsRangeForBitInterpretation(srcBitInterpretation);
                exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_si(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                BOOL isSpecialExponent = NO;
                if (!result.error)
                {
                  exponentMinorPartRange = NSIntersectionRange(exponentMinorPartRange, srcMaxRange);
                  mpz_t exponentZ;
                  mpzDepool(exponentZ, chalkContext.gmpPool);
                  BOOL error = NO;
                  mpz_copyBits(exponentZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), exponentMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mp_bitcnt_t firstZeroBitIndex = !exponentMinorPartRange.length ? 0 : mpz_scan0(exponentZ, 0);
                  isSpecialExponent |= exponentMinorPartRange.length &&
                    (firstZeroBitIndex >= getExponentBitsCountForEncoding(srcNumberEncoding));
                  if (!isSpecialExponent)
                  {
                    mpz_t exponentBiasZ;
                    mpzDepool(exponentBiasZ, chalkContext.gmpPool);
                    mpz_set_si(exponentBiasZ, 1);
                    mpz_mul_2exp(exponentBiasZ, exponentBiasZ, getExponentBitsCountForEncoding(srcNumberEncoding)-1);
                    mpz_sub_ui(exponentBiasZ, exponentBiasZ, 1);
                    mpz_sub(exponentZ, exponentZ, exponentBiasZ);
                    mpz_add_ui(exponentZ, exponentZ, 1);//+1 because GMP needs MSB set to 1
                    mpzRepool(exponentBiasZ, chalkContext.gmpPool);
                    if (!result.error)
                    {
                      if ((mpz_cmp_si(exponentZ, mpfr_get_emin())<0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())>0))
                      {
                        result.computeFlags |= CHALK_COMPUTE_FLAG_ERANGE;
                        result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      }//end if ((mpz_cmp_si(exponentZ, mpfr_get_emin())<0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())>0))
                      else//if ((mpz_cmp_si(exponentZ, mpfr_get_emin())>=0) || (mpz_cmp_si(exponentZ, mpfr_get_emax())<=0))
                        memcpy(&dst->_mpfr_exp, exponentZ->_mp_d, MIN(sizeof(mp_limb_t), sizeof(mpfr_exp_t)));
                    }//end if (!result.error)
                  }//end if (!isSpecialExponent)
                  mpzRepool(exponentZ, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //significand
                BOOL isZeroSignificand = NO;
                if (!result.error)
                {
                  mp_bitcnt_t first1Bit = mpz_scan1(src->bits, significandMinorPartRange_safe.location);
                  isZeroSignificand |= (first1Bit >= NSMaxRange(significandMinorPartRange_safe));
                  mpfr_prec_t prec = significandMinorPartRange.length+1;//+1 because GMP needs MSB set to 1
                  prec = MIN(MPFR_PREC_MAX, MAX(MPFR_PREC_MIN, prec));
                  mp_bitcnt_t totalBitsCount = ((prec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                  mp_bitcnt_t offset = totalBitsCount-prec;
                  mpn_zero(dst->_mpfr_d, totalBitsCount/mp_bits_per_limb);
                  BOOL error = NO;
                  mpfr_copyBits(dst, offset, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  offset += significandMinorPartRange_safe.length;
                  mp_limb_t dummyLimbs[1] = {1};
                  mpfr_copyBits(dst, offset, dummyLimbs, sizeof(dummyLimbs)/sizeof(mp_limb_t), NSMakeRange(0, 1), &error);//MSB
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                }//end if (!result.error)
                
                if (isZeroSignificand)
                {
                  if (isSpecialExponent)
                  {
                    mpfr_set_inf(dst, (dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0);
                    mpfr_set_erangeflag();
                  }//end if (isSpecialExponent)
                }//end if (isZeroSignificand)
                else//if (!isZeroSignificand)
                {
                  if (isSpecialExponent)
                  {
                    mpfr_set_nan(dst);
                    mpfr_set_nanflag();
                  }//end if (isSpecialExponent)
                }//end if (!isZeroSignificand)
              }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION
              break;
          }//end switch(srcEncodingVariant.ieee754StandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_IEEE754_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
        {
          switch(srcEncodingVariant.integerStandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                BOOL isZeroSignificand = NO;
                mp_prec_t unroundedPrec = 0;
                if (!result.error)
                {
                  mpz_t significand;
                  mpzDepool(significand, chalkContext.gmpPool);
                  BOOL error = NO;
                  mpz_copyBits(significand, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  if (dst->_mpfr_sign<0)
                  {
                    mpz_complement2(significand, NSMakeRange(significandMinorPartRange_safe.location, significandMinorPartRange_safe.length));
                    ++significandMinorPartRange_safe.length;//include sign bit
                  }//end if (dst->_mpfr_sign<0)
                  mp_bitcnt_t usefulBits = MIN(mpz_sizeinbase(significand, 2), significandMinorPartRange_safe.length);
                  isZeroSignificand = !mpz_cmp_si(significand, 0);
                  if (!isZeroSignificand)
                  {
                    unroundedPrec = usefulBits;
                    unroundedPrec = MIN(MPFR_PREC_MAX, unroundedPrec);
                    mpfr_prec_t adaptedPrec = MAX(MPFR_PREC_MIN, unroundedPrec);
                    mp_bitcnt_t totalBitsCount = ((unroundedPrec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                    mp_bitcnt_t offset = totalBitsCount-unroundedPrec;
                    mpz_mul_2exp(significand, significand, offset);//shift left for further use as mpfr limbs
                    mpfr_prec_round(dst, adaptedPrec, MPFR_RNDN);
                    BOOL error = NO;
                    mpfr_copyBits(dst, 0, mpz_limbs_read(significand), mpz_size(significand), NSMakeRange(0, totalBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  }//end if (!isZeroSignificand)
                  mpzRepool(significand, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  if (isZeroSignificand)
                    mpfr_set_zero(dst, MAX((dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0, 0));
                  else//if (!isZeroSignificand)
                  {
                    if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    {
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      mpfr_set_zero(dst, 0);
                    }//end if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    else//if ((unroundedPrec>=mpfr_get_emin()) && (unroundedPrec<=mpfr_get_emax()))
                      dst->_mpfr_exp = unroundedPrec;
                  }//end if (!isZeroSignificand)
                }//end if (!result.error)
              }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_...S
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                BOOL isZeroSignificand = NO;
                mp_prec_t unroundedPrec = 0;
                if (!result.error)
                {
                  mpz_t significand;
                  mpzDepool(significand, chalkContext.gmpPool);
                  BOOL error = NO;
                  mpz_copyBits(significand, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mp_bitcnt_t usefulBits = mpz_sizeinbase(significand, 2);
                  isZeroSignificand = !mpz_cmp_si(significand, 0);
                  if (!isZeroSignificand)
                  {
                    unroundedPrec = usefulBits;
                    unroundedPrec = MIN(MPFR_PREC_MAX, unroundedPrec);
                    mpfr_prec_t adaptedPrec = MAX(MPFR_PREC_MIN, unroundedPrec);
                    mp_bitcnt_t totalBitsCount = ((unroundedPrec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                    mp_bitcnt_t offset = totalBitsCount-unroundedPrec;
                    mpz_mul_2exp(significand, significand, offset);//shift left for further use as mpfr limbs
                    mpfr_prec_round(dst, adaptedPrec, MPFR_RNDN);
                    BOOL error = NO;
                    mpfr_copyBits(dst, 0, mpz_limbs_read(significand), mpz_size(significand), NSMakeRange(0, totalBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  }//end if (!isZeroSignificand)
                  mpzRepool(significand, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  if (isZeroSignificand)
                    mpfr_set_zero(dst, MAX((dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0, 0));
                  else//if (!isZeroSignificand)
                  {
                    if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    {
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      mpfr_set_zero(dst, 0);
                    }//end if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    else//if ((unroundedPrec>=mpfr_get_emin()) && (unroundedPrec<=mpfr_get_emax()))
                      dst->_mpfr_exp = unroundedPrec;
                  }//end if (!isZeroSignificand)
                }//end if (!result.error)
              }//end CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_...U
              break;
          }//end switch(srcEncodingVariant.integerStandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
        {
          switch(srcEncodingVariant.integerCustomVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
              result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                BOOL isZeroSignificand = NO;
                mp_prec_t unroundedPrec = 0;
                if (!result.error)
                {
                  mpz_t significand;
                  mpzDepool(significand, chalkContext.gmpPool);
                  BOOL error = NO;
                  mpz_copyBits(significand, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  else if (dst->_mpfr_sign<0)
                  {
                    mpz_complement2(significand, NSMakeRange(significandMinorPartRange_safe.location, significandMinorPartRange_safe.length));
                    ++significandMinorPartRange_safe.length;//include sign bit
                  }//end if (dst->_mpfr_sign<0)
                  mp_bitcnt_t usefulBits = MIN(mpz_sizeinbase(significand, 2), significandMinorPartRange_safe.length);
                  isZeroSignificand = !mpz_cmp_si(significand, 0);
                  if (!isZeroSignificand)
                  {
                    unroundedPrec = usefulBits;
                    unroundedPrec = MIN(MPFR_PREC_MAX, unroundedPrec);
                    mpfr_prec_t adaptedPrec = MAX(MPFR_PREC_MIN, unroundedPrec);
                    mp_bitcnt_t totalBitsCount = ((unroundedPrec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                    mp_bitcnt_t offset = totalBitsCount-unroundedPrec;
                    mpz_mul_2exp(significand, significand, offset);//shift left for further use as mpfr limbs
                    mpfr_prec_round(dst, adaptedPrec, MPFR_RNDN);
                    BOOL error = NO;
                    mpfr_copyBits(dst, 0, mpz_limbs_read(significand), mpz_size(significand), NSMakeRange(0, totalBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  }//end if (!isZeroSignificand)
                  mpzRepool(significand, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  if (isZeroSignificand)
                    mpfr_set_zero(dst, MAX((dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0, 0));
                  else//if (!isZeroSignificand)
                  {
                    if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    {
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      mpfr_set_zero(dst, 0);
                    }//end if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    else//if ((unroundedPrec>=mpfr_get_emin()) && (unroundedPrec<=mpfr_get_emax()))
                      dst->_mpfr_exp = unroundedPrec;
                  }//end if (!isZeroSignificand)
                }//end if (!result.error)
              }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
              {
                NSRange srcMaxRange = NSMakeRange(0, mpz_size(src->bits)*mp_bits_per_limb);
                NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                NSRange significandMinorPartRange = getSignificandBitsRangeForBitInterpretation(srcBitInterpretation, NO);
                NSRange significandMinorPartRange_safe = NSIntersectionRange(significandMinorPartRange, srcMaxRange);

                //sign
                if (!result.error)
                {
                  NSRange signMinorPartRange = getSignBitsRangeForBitInterpretation(srcBitInterpretation);
                  signMinorPartRange = NSIntersectionRange(signMinorPartRange, srcMaxRange);
                  mpz_t signZ;
                  mpzDepool(signZ, chalkContext.gmpPool);
                  mpz_set_ui(signZ, 0);
                  BOOL error = NO;
                  mpz_copyBits(signZ, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), signMinorPartRange, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  dst->_mpfr_sign = (mpz_cmp_si(signZ, 0)>0) ? -1 : 1;
                  mpzRepool(signZ, chalkContext.gmpPool);
                }//end if (!result.error)

                //significand
                BOOL isZeroSignificand = NO;
                mp_prec_t unroundedPrec = 0;
                if (!result.error)
                {
                  mpz_t significand;
                  mpzDepool(significand, chalkContext.gmpPool);
                  BOOL error = NO;
                  mpz_copyBits(significand, 0, mpz_limbs_read(src->bits), mpz_size(src->bits), significandMinorPartRange_safe, &error);
                  if (error)
                    result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  mp_bitcnt_t usefulBits = mpz_sizeinbase(significand, 2);
                  isZeroSignificand = !mpz_cmp_si(significand, 0);
                  if (!isZeroSignificand)
                  {
                    unroundedPrec = usefulBits;
                    unroundedPrec = MIN(MPFR_PREC_MAX, unroundedPrec);
                    mpfr_prec_t adaptedPrec = MAX(MPFR_PREC_MIN, unroundedPrec);
                    mp_bitcnt_t totalBitsCount = ((unroundedPrec+mp_bits_per_limb-1)/mp_bits_per_limb)*mp_bits_per_limb;
                    mp_bitcnt_t offset = totalBitsCount-unroundedPrec;
                    mpz_mul_2exp(significand, significand, offset);//shift left for further use as mpfr limbs
                    mpfr_prec_round(dst, adaptedPrec, MPFR_RNDN);
                    BOOL error = NO;
                    mpfr_copyBits(dst, 0, mpz_limbs_read(significand), mpz_size(significand), NSMakeRange(0, totalBitsCount), &error);
                    if (error)
                      result.error = CHALK_CONVERSION_ERROR_ALLOCATION;
                  }//end if (!isZeroSignificand)
                  mpzRepool(significand, chalkContext.gmpPool);
                }//end if (!result.error)
                
                //exponent
                if (!result.error)
                {
                  if (isZeroSignificand)
                    mpfr_set_zero(dst, MAX((dst->_mpfr_sign<0) ? -1 : (dst->_mpfr_sign>0) ? 1 : 0, 0));
                  else//if (!isZeroSignificand)
                  {
                    if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    {
                      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT;
                      mpfr_set_zero(dst, 0);
                    }//end if ((unroundedPrec<mpfr_get_emin()) || (unroundedPrec>mpfr_get_emax()))
                    else//if ((unroundedPrec>=mpfr_get_emin()) && (unroundedPrec<=mpfr_get_emax()))
                      dst->_mpfr_exp = unroundedPrec;
                  }//end if (!isZeroSignificand)
                }//end if (!result.error)
              }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED
              break;
          }//end switch(srcEncodingVariant.integerCustomVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM
        break;
    }//end switch(srcEncodingType)
    
    if (!result.error && isDstIntegerUnsigned && (mpfr_sgn(dst)<0))
    {
      result.error = CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN;
      mpfr_set_si(dst, 0, MPFR_RNDN);
    }//end if (!result.error && isDstIntegerUnsigned && (mpz_sgn(dst)<0))

    result.computeFlags |= chalkGmpFlagsMake();
    chalkGmpFlagsRestore(oldFlags);
  }//end if (src && dst && srcBitInterpretation && dstBitInterpretation)
  return result;
}
//end convertFromRawToValueFR()

chalk_conversion_result_t convertFromRawToValueFIR(mpfir_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND)
      result = convertFromRawToValueFR(&dst->interval.left, src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND)
      result = convertFromRawToValueFR(&dst->interval.right, src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE)
      result = convertFromRawToValueFR(&dst->estimation, src, dstBitInterpretation, chalkContext);
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end convertFromRawToValueFIR()

chalk_conversion_result_t interpretFromRawToValue(chalk_gmp_value_t* dst, const chalk_raw_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dst->type == CHALK_VALUE_TYPE_INTEGER)
      result = interpretFromRawToValueZ(dst->integer, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_FRACTION)
      result = interpretFromRawToValueQ(dst->fraction, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = interpretFromRawToValueFR(dst->realExact, src, dstBitInterpretation, chalkContext);
    else if (dst->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (computeMode == CHALK_COMPUTE_MODE_APPROX_BEST)
        result = interpretFromRawToValueFR(&dst->realApprox->estimation, src, dstBitInterpretation, chalkContext);
      else
        result = interpretFromRawToValueFIR(dst->realApprox, src, dstBitInterpretation, chalkContext);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end interpretFromRawToValue()

chalk_conversion_result_t interpretFromRawToValueZ(mpz_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    chalk_raw_value_t src2 = *src;
    src2.bitInterpretation = *dstBitInterpretation;
    result = convertFromRawToValueZ(dst, &src2, dstBitInterpretation, chalkContext);
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end interpretFromRawToValueZ()

chalk_conversion_result_t interpretFromRawToValueQ(mpq_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_NUMERATOR)
      result = interpretFromRawToValueZ(mpq_numref(dst), src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_DENOMINATOR)
      result = interpretFromRawToValueZ(mpq_denref(dst), src, dstBitInterpretation, chalkContext);
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end interpretFromRawToValueQ()

chalk_conversion_result_t interpretFromRawToValueFR(mpfr_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    chalk_raw_value_t src2 = {0};
    chalkRawValueSet(&src2, src, chalkContext.gmpPool);
    src2.bitInterpretation = *dstBitInterpretation;
    result = convertFromRawToValueFR(dst, &src2, dstBitInterpretation, chalkContext);
    chalkRawValueClear(&src2, YES, chalkContext.gmpPool);
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end interpretFromRawToValueFR()

chalk_conversion_result_t interpretFromRawToValueFIR(mpfir_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext)
{
  chalk_conversion_result_t result = {0};
  if (src && dst && dstBitInterpretation)
  {
    if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_LOWER_BOUND)
      result = interpretFromRawToValueFR(&dst->interval.left, src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_UPPER_BOUND)
      result = interpretFromRawToValueFR(&dst->interval.right, src, dstBitInterpretation, chalkContext);
    else if (dstBitInterpretation->major == CHALK_NUMBER_PART_MAJOR_BEST_VALUE)
      result = interpretFromRawToValueFR(&dst->estimation, src, dstBitInterpretation, chalkContext);
    else
      result.error = CHALK_CONVERSION_ERROR_NO_REPRESENTATION;
  }//end if (src && dst && dstBitInterpretation)
  return result;
}
//end interpretFromRawToValueFIR()

id plistFromBitNumberEncoding(chalk_number_encoding_t numberEncoding)
{
  id result = @{
    @"encodingType":@(numberEncoding.encodingType),
    @"encodingVariant":@(numberEncoding.encodingVariant.genericVariantEncoding),
  };
  return result;
}
//end plistFromBitNumberEncoding()

chalk_number_encoding_t plistToNumberEncoding(id plist)
{
  chalk_number_encoding_t result = {0};
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  result.encodingType = [[[dict objectForKey:@"encodingType"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result.encodingVariant.genericVariantEncoding = [[[dict objectForKey:@"encodingVariant"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end plistToNumberEncoding()

id plistFromBitInterpretation(chalk_bit_interpretation_t bitInterpretation)
{
  id result = @{
    @"major":@(bitInterpretation.major),
    @"numberEncoding":plistFromBitNumberEncoding(bitInterpretation.numberEncoding),
    @"signCustomBitsCount":@(bitInterpretation.signCustomBitsCount),
    @"exponentCustomBitsCount":@(bitInterpretation.exponentCustomBitsCount),
    @"significandCustomBitsCount":@(bitInterpretation.significandCustomBitsCount),
  };
  return result;
}
//end plistFromBitInterpretation

chalk_bit_interpretation_t plistToBitInterpretation(id plist)
{
  chalk_bit_interpretation_t result = {0};
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  result.major = [[[dict objectForKey:@"major"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result.numberEncoding = plistToNumberEncoding([dict objectForKey:@"numberEncoding"]);
  result.signCustomBitsCount = [[[dict objectForKey:@"signCustomBitsCount"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result.exponentCustomBitsCount = [[[dict objectForKey:@"exponentCustomBitsCount"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result.significandCustomBitsCount = [[[dict objectForKey:@"significandCustomBitsCount"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end plistToBitInterpretation()

id plistFromRawValue(chalk_raw_value_t rawValue)
{
  id result = nil;
  NSMutableData* dataBits = nil;
  FILE* fileBits = 0;
  dataBits = [[NSMutableData alloc] init];
  fileBits = [dataBits openAsFile];
  mpz_out_raw(fileBits, rawValue.bits);
  result = @{
    @"bitInterpretation":plistFromBitInterpretation(rawValue.bitInterpretation),
    @"bits":dataBits,
    @"flags":@(rawValue.flags),
  };
  if (fileBits)
    fclose(fileBits);
  [dataBits release];
  return result;
}
//end plistFromRawValue()

chalk_raw_value_t plistToRawValue(id plist)
{
  chalk_raw_value_t result = {0};
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSData* dataBits = [[dict objectForKey:@"bits"] dynamicCastToClass:[NSData class]];
  FILE* fileBits = [dataBits openAsFile];
  mpz_init(result.bits);
  mpz_inp_raw(result.bits, fileBits);
  if (fileBits)
    fclose(fileBits);
  result.bitInterpretation = plistToBitInterpretation([dict objectForKey:@"bitInterpretation"]);
  result.flags = [[[dict objectForKey:@"flags"] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end plistToRawValue()

void mpz_negbit(mpz_ptr rop, mp_bitcnt_t index)
{
  if (index > mpz_sizeinbase(rop, 2))
    mpz_setbit(rop, index);
  else if (mpz_tstbit(rop, index))
    mpz_clrbit(rop, index);
  else
    mpz_setbit(rop, index);
}
//end mpz_negbit()

void mpz_changeBit(mpz_ptr rop, mp_bitcnt_t index, BOOL value)
{
  if (index > mpz_sizeinbase(rop, 2))
  {
    if (value)
      mpz_setbit(rop, index);
  }//end if (index > mpz_sizeinbase(rop, 2))
  else if (value)
    mpz_setbit(rop, index);
  else//if (!value)
    mpz_clrbit(rop, index);
}
//end mpz_changeBit()

int mpz_complement2(mpz_ptr rop, NSRange bitRange)
{
  int result = 0;
  if (rop && bitRange.length)
  {
    size_t firstLimbIndex = bitRange.location/mp_bits_per_limb;
    size_t lastLimbIndex = (bitRange.location+bitRange.length-1+mp_bits_per_limb-1)/mp_bits_per_limb;
    size_t limbsCount = lastLimbIndex-firstLimbIndex;
    mp_bitcnt_t currentBitIndex = bitRange.location;
    mp_bitcnt_t bitsInFirstLimb = MIN(mp_bits_per_limb-currentBitIndex%mp_bits_per_limb, bitRange.length);
    mp_bitcnt_t bitsInLastLimb = (bitRange.location+bitRange.length)%mp_bits_per_limb;
    mp_limb_t* limbs = mpz_limbs_modify_safe(rop, limbsCount);
    if (limbs)
    {
      size_t limbIndex = firstLimbIndex;
      mp_limb_t carry = 1;
      mp_limb_t* currentLimb = 0;
      if (limbIndex < lastLimbIndex)
      {
        currentLimb = &limbs[limbIndex++];
        if (bitsInFirstLimb == mp_bits_per_limb)
        {
          *currentLimb = ~*currentLimb;
          if (carry)
            carry = mpn_add_1(currentLimb, currentLimb, 1, carry);
        }//end if (bitsInFirstLimb == mp_bits_per_limb)
        else//if (bitsInFirstLimb != mp_bits_per_limb)
        {
          mp_limb_t shift = (currentBitIndex%mp_bits_per_limb);
          carry <<= shift;
          mp_limb_t mask = ((((mp_limb_t)1)<<bitsInFirstLimb)-1)<<shift;
          *currentLimb = ((~(*currentLimb)) & mask) | ((*currentLimb) & ~mask);
          if (carry)
            carry = mpn_add_1(currentLimb, currentLimb, 1, carry);
        }//end if (bitsInFirstLimb != mp_bits_per_limb)
      }//end if (limbIndex < lastLimbIndex)
      while(limbIndex+1 < lastLimbIndex)
      {
        currentLimb = &limbs[limbIndex++];
        *currentLimb = ~(*currentLimb);
        if (carry)
          carry = mpn_add_1(currentLimb, currentLimb, 1, carry);
      }//end while(limbIndex+1 < lastLimbIndex)
      if (limbIndex < lastLimbIndex)
      {
        currentLimb = &limbs[limbIndex++];
        if (bitsInLastLimb == mp_bits_per_limb)
        {
          *currentLimb = ~(*currentLimb);
          if (carry)
            carry = mpn_add_1(currentLimb, currentLimb, 1, carry);
        }//end if (bitsInLastLimb == mp_bits_per_limb)
        else//if (bitsInLastLimb != mp_bits_per_limb)
        {
          mp_limb_t mask = ((((mp_limb_t)1)<<bitsInLastLimb)-1);
          *currentLimb = ((~(*currentLimb)) & mask) | ((*currentLimb) & ~mask);
          carry &= mask;
          if (carry)
            carry = mpn_add_1(currentLimb, currentLimb, 1, carry);
        }//end if (bitsInLastLimb != mp_bits_per_limb)
      }//end if (limbIndex < lastLimbIndex)
      mpz_limbs_finish(rop, limbsCount);
    }//end if (limbs)
  }//end if (rop && bitRange.length)
  return result;
}
//end mpz_complement2()

int mpf_is_infinity(mpf_srcptr op)
{
  int result = 0;
  double pinf = INFINITY;
  double minf = -pinf;
  result =
    !mpf_cmp_d(op, pinf) ? 1  :
    !mpf_cmp_d(op, minf) ? -1 :
    0;
  return result;
}
//end mpf_is_infinity()

int mpfr_init_set_nsui(mpfr_t rop, const NSUInteger op, mpfr_rnd_t rnd)
{
  int result = 0;
  if (sizeof(op) <= sizeof(unsigned long int))
    result = mpfr_init_set_ui(rop, op, rnd);
  else//if (sizeof(op) > sizeof(unsigned long int))
  {
    mpz_t mpz;
    mpz_init_set_nsui(mpz, op);
    result = mpfr_init_set_z(rop, mpz, rnd);
    mpz_clear(mpz);
  }//end if (sizeof(op) > sizeof(unsigned long int))
  return result;
}
//end mpfr_init_set_nsui()

int mpfr_init_set_nssi(mpfr_t rop, const NSInteger op, mpfr_rnd_t rnd)
{
  int result = 0;
  if (sizeof(op) <= sizeof(signed long int))
    result = mpfr_init_set_si(rop, op, rnd);
  else//if (sizeof(op) > sizeof(signed long int))
  {
    mpz_t mpz;
    mpz_init_set_nssi(mpz, op);
    result = mpfr_init_set_z(rop, mpz, rnd);
    mpz_clear(mpz);
  }//end if (sizeof(op) > sizeof(signed long int))
  return result;
}
//end mpfr_init_set_nssi()
  
int mpfr_set_nsui(mpfr_t rop, const NSUInteger op, mpfr_rnd_t rnd)
{
  int result = 0;
  if (sizeof(op) <= sizeof(unsigned long int))
    result = mpfr_set_ui(rop, op, rnd);
  else//if (sizeof(op) > sizeof(unsigned long int))
  {
    mpz_t mpz;
    mpz_init_set_nsui(mpz, op);
    result = mpfr_set_z(rop, mpz, rnd);
    mpz_clear(mpz);
  }//end if (sizeof(op) > sizeof(unsigned long int))
  return result;
}
//end mpfr_set_nsui()

int mpfr_set_nssi(mpfr_t rop, const NSInteger op, mpfr_rnd_t rnd)
{
  int result = 0;
  if (sizeof(op) <= sizeof(signed long int))
    result = mpfr_set_si(rop, op, rnd);
  else//if (sizeof(op) > sizeof(signed long int))
  {
    mpz_t mpz;
    mpz_init_set_nssi(mpz, op);
    result = mpfr_set_z(rop, mpz, rnd);
    mpz_clear(mpz);
  }//end if (sizeof(op) > sizeof(signed long int))
  return result;
}
//end mpfr_set_nssi()

NSUInteger mpfr_get_nsui(mpfr_srcptr op, mpfr_rnd_t rnd)
{
  NSUInteger result = 0;
  if (mpfr_fits_uint_p(op, rnd))
    result = mpfr_get_ui(op, rnd);
  else//if (mpfr_fits_uint_p(op, rnd))
  {
    mpz_t mpz;
    mpz_init(mpz);
    mpfr_get_z(mpz, op, rnd);
    result = mpz_get_nsui(mpz);
    mpz_clear(mpz);
  }//end if (mpfr_fits_uint_p(op, rnd))
  return result;
}
//end mpfr_get_nsui()
  
NSInteger mpfr_get_nssi(mpfr_srcptr op, mpfr_rnd_t rnd)
{
  NSInteger result = 0;
  if (mpfr_fits_sint_p(op, rnd))
    result = mpfr_get_si(op, rnd);
  else//if (mpfr_fits_sint_p(op, rnd))
  {
    mpz_t mpz;
    mpz_init(mpz);
    mpfr_get_z(mpz, op, rnd);
    result = mpz_get_nssi(mpz);
    mpz_clear(mpz);
  }//end if (mpfr_fits_sint_p(op, rnd))
  return result;
}
//end mpfr_get_nssi()

int mpfr_fits_z(mpfr_srcptr op, mp_bitcnt_t bitcount)
{
  int result = 0;
  if (!bitcount){
  }
  else if (mpfr_zero_p(op))
    result = 1;
  else if (mpfr_integer_p(op))
  {
    char buffer[4] = {0};
    mpfr_exp_t e = 0;
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    mpfr_get_str(buffer, &e, 2, 2, op, MPFR_RNDA);
    chalkGmpFlagsRestore(oldFlags);
    result = (e <= bitcount);
  }//end if (mpfr_integer_p(op))
  return result;
}
//end mpfr_fits_z()

BOOL mpfr_set_inf_optimized(mpfr_t rop, int sgn)
{
  BOOL result = NO;
  if (!mpfr_inf_p(rop) || (mpfr_get_prec(rop)>MPFR_PREC_MIN))
  {
    mpfr_set_prec(rop, MPFR_PREC_MIN);//set to nan
    mpfr_set_inf(rop, sgn);
    result = YES;
  }//end if (!mpfr_inf_p(rop) || (mpfr_get_prec(rop)>MPFR_PREC_MIN))
  return result;
}
//end mpfr_set_inf_optimized()

int mpfi_pow_z(mpfi_ptr rop, mpfi_srcptr op1, mpz_srcptr op2)
{
  int result = MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
  if (mpfi_nan_p(op1))
  {
    mpfr_set_nan(&rop->left);
    mpfr_set_nan(&rop->right);
    result = MPFI_FLAGS_BOTH_ENDPOINTS_EXACT;
  }//end if (mpfir_nan_p(op1))
  else if (mpfi_is_zero(op1))
  {
    int exact = mpfi_set(rop, op1);
    result = MPFI_BOTH_ARE_EXACT(exact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT : MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
  }//end if (mpfir_is_zero(op1))
  else
  {
    int cmpEnds = mpfr_cmp(&op1->left, &op1->right);
    if (!cmpEnds && !mpfr_cmp_d(&op1->left, 1))
    {
      int exact = mpfi_set(rop, op1);
      result = MPFI_BOTH_ARE_EXACT(exact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT : MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
    }//end if (!cmpEnds && !mpfr_cmp_d(&op1->left, 1))
    else//if (cmpEnds || mpfr_cmp_d(&op1->left, 1))
    {
      int sgn = mpz_sgn(op2);
      if (!sgn)
      {
        int exact = mpfi_set_d(rop, 1);
        result = MPFI_BOTH_ARE_EXACT(exact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT : MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
      }//end if (!sgn)
      else if (sgn<0)
      {
        mpz_t op2neg;
        mpz_init_set(op2neg, op2);
        mpz_neg(op2neg, op2neg);
        mpfi_t op1Inv;
        mpfi_init2(op1Inv, mpfi_get_prec(op1));
        mpfi_inv(op1Inv, op1);
        result = mpfi_pow_z(op1Inv, op1, op2neg);
        mpfi_clear(op1Inv);
        mpz_clear(op2neg);
      }//end if (sgn<0)
      else//if (sgn>0)
      {
        if (mpz_odd_p(op2))
        {
          BOOL leftExact = !mpfr_pow_z(&rop->left, &op1->left, op2, MPFR_RNDD);
          BOOL rightExact = !mpfr_pow_z(&rop->right, &op1->right, op2, MPFR_RNDU);
          result = (leftExact && rightExact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT :
                   leftExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT :
                   rightExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT :
                   MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
        }//end if (mpz_odd_p(op2))
        else//if (!mpz_odd_p(op2))
        {
          if (mpfi_is_strictly_neg(op1))
          {
            BOOL leftExact = !mpfr_pow_z(&rop->left, &op1->right, op2, MPFR_RNDD);
            BOOL rightExact = !mpfr_pow_z(&rop->right, &op1->left, op2, MPFR_RNDU);
            result = (leftExact && rightExact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT :
                     leftExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT :
                     rightExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT :
                     MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
          }//end if (mpfi_is_strictly_neg(op1))
          else if (mpfi_is_strictly_pos(op1))
          {
            BOOL leftExact = !mpfr_pow_z(&rop->left, &op1->left, op2, MPFR_RNDD);
            BOOL rightExact = !mpfr_pow_z(&rop->right, &op1->right, op2, MPFR_RNDU);
            result = (leftExact && rightExact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT :
                     leftExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT :
                     rightExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT :
                     MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
          }//end if (mpfi_is_strictly_pos(op1))
          else//if (mpfi_has_zero(op1))
          {
            mpfr_set_zero(&rop->left, 0);
            BOOL leftExact = YES;
            BOOL rightExact = YES;
            rightExact &= !mpfr_abs(&rop->right, &op1->left, MPFR_RNDU);
            rightExact &= !mpfr_max(&rop->right, &rop->right, &op1->right, MPFR_RNDU);
            rightExact &= !mpfr_pow_z(&rop->right, &rop->right, op2, MPFR_RNDU);
            result = (leftExact && rightExact) ? MPFI_FLAGS_BOTH_ENDPOINTS_EXACT :
                     leftExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT :
                     rightExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT :
                     MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
          }//end if (mpfi_has_zero(op1))
        }//end if (!mpz_odd_p(op2))
      }//end if (sgn>0)
    }//end if (cmpEnds || mpfr_cmp_d(&op1->left, 1))
  }//end if
  return result;
}
//end mpfi_pow_z()

int mpfir_pow_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_pow_z(&rop->interval, &op1->interval, op2);
  mpfr_pow_z(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_pow_z()

int mpfi_pow(mpfi_ptr rop, mpfi_srcptr op1, mpfi_srcptr op2)
{
  int result = 0;
  mpfi_t tmpi1;
  mpfi_t tmpi2;
  mpfiDepool(tmpi1, mpfi_get_prec(rop), nil);
  mpfiDepool(tmpi2, mpfi_get_prec(rop), nil);
  mpfi_log(tmpi1, op1);
  mpfi_mul(tmpi2, op2, tmpi1);
  mpfi_exp(rop, tmpi2);
  mpfiRepool(tmpi1, nil);
  mpfiRepool(tmpi2, nil);
  return result;
}
//end mpfi_pow()

int mpfir_pow(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_pow(&rop->interval, &op1->interval, &op2->interval);
  mpfr_pow(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_pow()

int mpz_fits_exponent_p(mpz_srcptr op, int base, CHGmpPool* pool)
{
  int result = 0;
  int fits1 = !chalkGmpBaseIsValid(base) ? 0 :
    (sizeof(mpfr_exp_t) <= sizeof(int)) ? mpz_fits_sint_p(op) :
    (sizeof(mpfr_exp_t) <= sizeof(NSInteger)) ? mpz_fits_nssi_p(op) :
     0;
  if (fits1)
  {
    mpz_t emax;
    mpzDepool(emax, pool);
    mpz_set_nsui(emax, mpfr_get_emax());
    if (base == 2)
      result = (mpz_cmp(op, emax)<=0);
    else//if (base != 2)
    {
      mpz_t e;
      mpzDepool(e, pool);
      mpz_min_exponent(e, op, base, 2, pool);
      result = (mpz_cmp(e, emax)<=0) ? 1 : 0;
      mpzRepool(e, pool);
    }//end if (base != 2)
    mpzRepool(emax, pool);
  }//end if (fits1)
  return result;
}
//end mpz_fits_exponent_p()

chalk_compute_flags_t chalkGmpFlagsMake(void)
{
  chalk_compute_flags_t result = CHALK_COMPUTE_FLAG_NONE;
  if (mpfr_divby0_p())
    result |= CHALK_COMPUTE_FLAG_DIVBYZERO;
  if (mpfr_erangeflag_p())
    result |= CHALK_COMPUTE_FLAG_ERANGE;
  if (mpfr_inexflag_p())
    result |= CHALK_COMPUTE_FLAG_INEXACT;
  if (mpfr_nanflag_p())
    result |= CHALK_COMPUTE_FLAG_NAN;
  if (mpfr_overflow_p())
    result |= CHALK_COMPUTE_FLAG_OVERFLOW;
  if (mpfr_underflow_p())
    result |= CHALK_COMPUTE_FLAG_UNDERFLOW;
  return result;
}
//end chalkGmpFlagsMake()
  
chalk_compute_flags_t chalkGmpFlagsAdd(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToAdd)
{
  chalk_compute_flags_t result = flags | flagsToAdd;
  return result;
}
//end chalkGmpFlagsAdd()
  
chalk_compute_flags_t chalkGmpFlagsRemove(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToRemove)
{
  chalk_compute_flags_t result = flags & flagsToRemove;
  return result;
}
//end chalkGmpFlagsRemove()

BOOL chalkGmpFlagsTest(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToTest)
{
  BOOL result = ((flags & flagsToTest) != 0);
  return result;
}
//end chalkGmpFlagsTest()

chalk_compute_flags_t chalkGmpFlagsSave(BOOL reset)
{
  chalk_compute_flags_t result = mpfr_flags_save();
  if (reset)
    mpfr_clear_flags();
  return result;
}
//end chalkGmpFlagsSave()

void chalkGmpFlagsRestore(chalk_compute_flags_t flags)
{
  mpfr_flags_restore((mpfr_flags_t)flags, MPFR_FLAGS_ALL);
}
//end chalkGmpFlagsRestore()

NSString* chalkGmpComputeFlagsGetHTML(chalk_compute_flags_t flags, const chalk_bit_interpretation_t* bitInterpretation, BOOL withTooltips)
{
  NSString* result = nil;
  NSMutableString* flagsImageString = [NSMutableString string];
  if (bitInterpretation)
  {
    switch(bitInterpretation->numberEncoding.encodingType)
    {
      case CHALK_NUMBER_ENCODING_UNDEFINED:
        break;
      case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
        break;
      case CHALK_NUMBER_ENCODING_GMP_STANDARD:
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
        {
          switch(bitInterpretation->numberEncoding.encodingVariant.integerStandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED:
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s8</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int8", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u8</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int8", @"")]];
              break;            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s16</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int16", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u16</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int16", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s32</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int32", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u32</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int32", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s64</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int64", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u64</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int64", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s128</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int128", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u128</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int128", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s256</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"signed int256", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u256</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"unsigned int256", @"")]];
              break;
          }//end switch(bitInterpretation->numberEncoding.encodingVariant.integerStandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_STANDARD
        break;
      case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
        {
          switch(bitInterpretation->numberEncoding.encodingVariant.integerCustomVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED:
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>s*</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"custom signed integer", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>u*</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"custom unsigned integer", @"")]];
              break;
          }//end switch(bitInterpretation->numberEncoding.encodingVariant.integerCustomVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM
        break;
      case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
        {
          switch(bitInterpretation->numberEncoding.encodingVariant.ieee754StandardVariantEncoding)
          {
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED:
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>f16</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"IEEE 754 half (16)", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>f32</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"IEEE 754 single (32)", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>f64</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"IEEE 754 single (64)", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>f128</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"IEEE 754 single (128)", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE:
              [flagsImageString appendFormat:@"<div class='warningFlag' %@>f128</div>",
                !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"IEEE 754 single (128)", @"")]];
              break;
            case CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION:
              break;
          }//end switch(bitInterpretation->numberEncoding.encodingVariant.ieee754StandardVariantEncoding)
        }//end case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM
        break;
    }//end switch(bitInterpretation->numberEncoding.encodingType)
  }//end if (bitInterpretation)
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_DIVBYZERO))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/divbyzero.png' srcset='images/divbyzero@2x.png 2x' %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"divbyzero", @"")]];
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_ERANGE))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/erange.png' srcset='images/erange@2x.png 2x' %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"erange", @"")]];
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_INEXACT))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/inexact.png' srcset='images/inexact@2x.png 2x' %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"inexact", @"")]];
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_NAN))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/nan.png' srcset='images/nan@2x.png 2x'  %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"nan", @"")]];
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_OVERFLOW))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/overflow.png' srcset='images/overflow@2x.png 2x' %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"overflow", @"")]];
  if (chalkGmpFlagsTest(flags, CHALK_COMPUTE_FLAG_UNDERFLOW))
    [flagsImageString appendFormat:@"<img class='warningFlag' src='images/underflow.png' srcset='images/underflow@2x.png 2x' %@ />",
      !withTooltips ? @"" : [NSString stringWithFormat:@"onmouseover=\"tooltip.show('%@')\" onmouseout=\"tooltip.hide()\"", NSLocalizedString(@"underflow", @"")]];
  result = [[flagsImageString copy] autorelease];
  return result;
}
//end chalkGmpComputeFlagsGetHTML()

BOOL chalkRawValueCreate(chalk_raw_value_t* value, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    mpzDepool(value->bits, pool);
    value->bitInterpretation = (chalk_bit_interpretation_t){0};
    value->flags = CHALK_RAW_VALUE_FLAG_NONE;
    result = YES;
  }//end if (value)
  return result;
}
//end chalkRawValueCreate()

BOOL chalkRawValueClear(chalk_raw_value_t* value, BOOL releaseResources, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (releaseResources && (mpz_limbs_read(value->bits) != 0))
      mpzRepool(value->bits, pool);
    value->bitInterpretation = (chalk_bit_interpretation_t){0};
    value->flags = CHALK_RAW_VALUE_FLAG_NONE;
    result = YES;
  }//end if (value)
  return result;
}
//end chalkRawValueClear()

BOOL chalkRawValueSet(chalk_raw_value_t* dst, const chalk_raw_value_t* src, CHGmpPool* pool)
{
  BOOL result = NO;
  if (src && dst && (src != dst))
  {
    chalkRawValueClear(dst, YES, pool);
    mpzDepool(dst->bits, pool);
    mpz_set(dst->bits, src->bits);
    dst->bitInterpretation = src->bitInterpretation;
    dst->flags = src->flags;
    result = YES;
  }//end if (src && dst && (src != dst))
  return result;
}
//end chalkRawValueSet()

BOOL chalkRawValueSetZero(chalk_raw_value_t* dst, CHGmpPool* pool)
{
  BOOL result = NO;
  if (dst)
  {
    mpz_set_si(dst->bits, 0);
    dst->flags = 0;
    result = YES;
  }//end if (dst)
  return result;
}
//end chalkRawValueSetZero()

BOOL chalkRawValueReverseBits(chalk_raw_value_t* dst, NSRange bitsRange)
{
  BOOL result = NO;
  BOOL done = NO;
  if (!dst || (dst->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED))
  {
    done = YES;
    result = NO;
  }//end if (!dst || (dst->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED))
  else if (bitsRange.location == NSNotFound)
  {
    done = YES;
    result = NO;
  }//end if (bitsRange.location == NSNotFound)
  else if (bitsRange.length <= 1)
  {
    done = YES;
    result = YES;
  }//end if (bitsRange.length <= 1)
  if (!done)
  {
    NSUInteger end = NSMaxRange(bitsRange);
    NSUInteger mid = bitsRange.location+bitsRange.length/2;
    for(NSUInteger i = bitsRange.location ; i<mid ; ++i)
    {
      NSUInteger j = end-i-1;
      BOOL bit1 = mpz_tstbit(dst->bits, i);
      BOOL bit2 = mpz_tstbit(dst->bits, j);
      mpz_changeBit(dst->bits, j, bit1);
      mpz_changeBit(dst->bits, i, bit2);
    }//end for each bit
    done = YES;
    result = YES;
  }//end if (!done)
  return result;
}
//end chalkRawValueReverseBits()

BOOL chalkRawValueMove(chalk_raw_value_t* dst, chalk_raw_value_t* src, CHGmpPool* pool)
{
  BOOL result = NO;
  if (src && dst && (src != dst))
  {
    chalkRawValueClear(dst, YES, pool);
    *dst = *src;
    chalkRawValueClear(src, NO, pool);
    result = YES;
  }//end if (src && dst && (src != dst))
  return result;
}
//end chalkRawValueMove()


BOOL chalkGmpValueClear(chalk_gmp_value_t* value, BOOL releaseResources, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (!releaseResources){
    }
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
      mpzRepool(value->integer, pool);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      mpqRepool(value->fraction, pool);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      mpfrRepool(value->realExact, pool);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      mpfirRepool(value->realApprox, pool);
    memset(value, 0, sizeof(*value));
    result = YES;
  }//end if (value)
  return result;
}
//end chalkGmpValueClear()

BOOL chalkGmpValueSet(chalk_gmp_value_t* dst, const chalk_gmp_value_t* src, CHGmpPool* pool)
{
  BOOL result = NO;
  if (src && dst && (src != dst))
  {
    if (dst->type != src->type)
    {
      chalkGmpValueClear(dst, YES, pool);
      if (src->type == CHALK_VALUE_TYPE_INTEGER)
        mpzDepool(dst->integer, pool);
      else if (src->type == CHALK_VALUE_TYPE_FRACTION)
        mpqDepool(dst->fraction, pool);
      else if (src->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfrDepool(dst->realExact, mpfr_get_prec(src->realExact), pool);
      else if (src->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfirDepool(dst->realApprox, mpfir_get_prec(src->realApprox), pool);
    }//end if (dst->type != src->type)
    if (src->type == CHALK_VALUE_TYPE_INTEGER)
      mpz_set(dst->integer, src->integer);
    else if (src->type == CHALK_VALUE_TYPE_FRACTION)
      mpq_set(dst->fraction, src->fraction);
    else if (src->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      mpfr_set_prec(dst->realExact, mpfr_get_prec(src->realExact));
      mpfr_set(dst->realExact, src->realExact, MPFR_RNDN);
    }//end if (src->type == CHALK_VALUE_TYPE_REAL_EXACT)
    else if (src->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      mpfir_set_prec(dst->realApprox, mpfir_get_prec(src->realApprox));
      mpfir_set(dst->realApprox, src->realApprox);
    }//end if (src->type == CHALK_VALUE_TYPE_REAL_APPROX)
    dst->type = src->type;
    result = YES;
  }//end if (src && dstt && (src != dst))
  return result;
}
//end chalkGmpValueSet()

BOOL chalkGmpValueSetZero(chalk_gmp_value_t* dst, BOOL keepType, CHGmpPool* pool)
{
  BOOL result = NO;
  if (dst)
  {
    if (keepType)
    {
      if (dst->type == CHALK_VALUE_TYPE_INTEGER)
        mpz_set_si(dst->integer, 0);
      else if (dst->type == CHALK_VALUE_TYPE_FRACTION)
        mpq_set_si(dst->fraction, 0, 1);
      else if (dst->type == CHALK_VALUE_TYPE_REAL_EXACT)
        mpfr_set_si(dst->realExact, 0, MPFR_RNDN);
      else if (dst->type == CHALK_VALUE_TYPE_REAL_APPROX)
        mpfir_set_si(dst->realApprox, 0);
      result = YES;
    }//end if (keepType)
    else if (chalkGmpValueMakeInteger(dst, pool))
    {
      mpz_set_si(dst->integer, 0);
      result = YES;
    }//end if (chalkGmpValueMakeInteger(dst))
  }//end if (dst)
  return result;
}
//end chalkGmpValueSetZero()

BOOL chalkGmpValueSetNan(chalk_gmp_value_t* dst, BOOL raiseFlag, CHGmpPool* pool)
{
  BOOL result = NO;
  if (!dst || (dst->type != CHALK_VALUE_TYPE_REAL_EXACT) || !mpfr_nan_p(dst->realExact) || (mpfr_get_prec(dst->realExact)>MPFR_PREC_MIN))
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    chalkGmpValueMakeRealExact(dst, mpfr_get_default_prec(), pool);
    mpfr_set_prec(dst->realExact, MPFR_PREC_MIN);//set to nan
    mpfr_set_nan(dst->realExact);
    chalkGmpFlagsRestore(oldFlags);
    if (raiseFlag)
      mpfr_set_nanflag();
    result = YES;
  }//end if (!dst || (dst->type != CHALK_VALUE_TYPE_REAL_EXACT) || !mpfr_nan_p(dst->realExact) || (mpfr_get_prec(dst->realExact)>MPFR_PREC_MIN))
  return result;
}
//end chalkGmpValueSetNan()

BOOL chalkGmpValueSetInfinity(chalk_gmp_value_t* dst, int sgn, BOOL raiseFlag, CHGmpPool* pool)
{
  BOOL result = NO;
  if (dst)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    if (dst->type != CHALK_VALUE_TYPE_REAL_EXACT)
      result |= chalkGmpValueMakeRealExact(dst, mpfr_get_default_prec(), pool);
    result |= mpfr_set_inf_optimized(dst->realExact, sgn);
    chalkGmpFlagsRestore(oldFlags);
    if (raiseFlag)
    {
      mpfr_set_erangeflag();
      mpfr_set_overflow();
    }//end if (raiseFlag)
    result = YES;
  }//end if (sdt)
  return result;
}
//end chalkGmpValueSetInfinity()

BOOL chalkGmpValueSwap(chalk_gmp_value_t* op1, chalk_gmp_value_t* op2)
{
  BOOL result = NO;
  if (op1 && op2)
  {
    chalk_gmp_value_t tmp = *op1;
    *op1 = *op2;
    *op2 = tmp;
    result = YES;
  }//end if (op1 && op2)
  return result;
}
//end chalkGmpValueSwap()

BOOL chalkGmpValueGetOneDigitUpRounding(mpfr_srcptr x, int base, char* outChar, NSInteger* outExp)
{
  BOOL result = NO;
  BOOL isBaseValid = chalkGmpBaseIsValid(base);
  if (mpfr_number_p(x) && isBaseValid)
  {
    char buffer[4] = {0};
    mpfr_exp_t e = 0;
    mpfr_get_str(buffer, &e, base, 2, x, MPFR_RNDA);//overly conservative, but more correct
    mpz_t value;
    unsigned int absBase = (base<0) ? -base : base;
    mpz_init_set_str(value, buffer+((mpfr_sgn(x)<0) ? 1 : 0), base);
    mpz_add_ui(value, value, (absBase+1)/2);
    mpz_fdiv_q_ui(value, value, absBase);
    mpz_get_str(buffer, base, value);
    if (outChar)
      *outChar = toupper(buffer[0]);
    if (outExp)
      *outExp = ((NSInteger)e)-1;
    mpz_clear(value);
    result = YES;
  }//end if (mpfr_number_p(x) && isBaseValid)
  return result;
}
//end chalkGmpValueGetOneDigitUpRounding()

BOOL chalkGmpValueMove(chalk_gmp_value_t* dst, chalk_gmp_value_t* src, CHGmpPool* pool)
{
  BOOL result = NO;
  if (src && dst && (src != dst))
  {
    chalkGmpValueClear(dst, YES, pool);
    *dst = *src;
    chalkGmpValueClear(src, NO, pool);
    result = YES;
  }//end if (src && dst && (src != dst))
  return result;
}
//end chalkGmpValueMove()

BOOL chalkGmpValueAbs(chalk_gmp_value_t* value, CHGmpPool* pool)
{
  BOOL result = NO;
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_INTEGER)
  {
    mpz_abs(value->integer, value->integer);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
  else if (value->type == CHALK_VALUE_TYPE_FRACTION)
  {
    mpq_abs(value->fraction, value->fraction);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  {
    mpfr_abs(value->realExact, value->realExact, MPFR_RNDN);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  {
    mpfir_abs(value->realApprox, value->realApprox);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  return result;
}
//end chalkGmpValueAbs()

int chalkGmpValueCmpAbs(const chalk_gmp_value_t* op1, const chalk_gmp_value_t* op2, CHGmpPool* pool)
{
  int result = 0;
  int sgn1 = chalkGmpValueSign(op1);
  int sgn2 = chalkGmpValueSign(op2);
  if ((sgn1<0) && (sgn2<0))
    result = -chalkGmpValueCmp(op1, op2, pool);
  else if ((sgn1>0) && (sgn2>0))
    result = chalkGmpValueCmp(op1, op2, pool);
  else//if (...)
  {
    const chalk_gmp_value_t* pOp1Abs = op1;
    chalk_gmp_value_t op1Abs = {0};
    if (sgn1<=0)
    {
      chalkGmpValueSet(&op1Abs, op1, pool);
      chalkGmpValueAbs(&op1Abs, pool);
      pOp1Abs = &op1Abs;
    }//end if (sgn1<=0)
    const chalk_gmp_value_t* pOp2Abs = op1;
    chalk_gmp_value_t op2Abs = {0};
    if (sgn2<=0)
    {
      chalkGmpValueSet(&op2Abs, op2, pool);
      chalkGmpValueAbs(&op2Abs, pool);
      pOp2Abs = &op2Abs;
    }//end if (sgn2<=0)
    result = chalkGmpValueCmp(pOp1Abs, pOp2Abs, pool);
    chalkGmpValueClear(&op1Abs, YES, pool);
    chalkGmpValueClear(&op2Abs, YES, pool);
  }//end if (...)
  return result;
}
//end chalkGmpValueCmpAbs()

int chalkGmpValueCmp(const chalk_gmp_value_t* op1, const chalk_gmp_value_t* op2, CHGmpPool* pool)
{
  int result = 0;
  if (!op1 || !op2){
  }
  else//if (op1 && op2)
  {
    if ((op1->type == CHALK_VALUE_TYPE_INTEGER) && (op2->type == CHALK_VALUE_TYPE_INTEGER))
      result = mpz_cmp(op1->integer, op2->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_INTEGER) && (op2->type == CHALK_VALUE_TYPE_FRACTION))
      result = -mpq_cmp_z(op2->fraction, op1->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_INTEGER) && (op2->type == CHALK_VALUE_TYPE_REAL_EXACT))
      result = -mpfr_cmp_z(op2->realExact, op1->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_INTEGER) && (op2->type == CHALK_VALUE_TYPE_REAL_APPROX))
      result = -mpfir_cmp_z(op2->realApprox, op1->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_FRACTION) && (op2->type == CHALK_VALUE_TYPE_INTEGER))
      result = mpq_cmp_z(op1->fraction, op2->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_FRACTION) && (op2->type == CHALK_VALUE_TYPE_FRACTION))
      result = mpq_cmp(op1->fraction, op2->fraction);
    else if ((op1->type == CHALK_VALUE_TYPE_FRACTION) && (op2->type == CHALK_VALUE_TYPE_REAL_EXACT))
      result = -mpfr_cmp_q(op2->realExact, op1->fraction);
    else if ((op1->type == CHALK_VALUE_TYPE_FRACTION) && (op2->type == CHALK_VALUE_TYPE_REAL_APPROX))
      result = -mpfir_cmp_q(op2->realApprox, op1->fraction);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_EXACT) && (op2->type == CHALK_VALUE_TYPE_INTEGER))
      result = mpfr_cmp_z(op1->realExact, op2->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_EXACT) && (op2->type == CHALK_VALUE_TYPE_FRACTION))
      result = mpfr_cmp_q(op1->realExact, op2->fraction);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_EXACT) && (op2->type == CHALK_VALUE_TYPE_REAL_EXACT))
      result = mpfr_cmp(op1->realExact, op2->realExact);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_EXACT) && (op2->type == CHALK_VALUE_TYPE_REAL_APPROX))
      result = -mpfir_cmp_fr(op2->realApprox, op1->realExact);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_APPROX) && (op2->type == CHALK_VALUE_TYPE_INTEGER))
      result = mpfir_cmp_z(op1->realApprox, op2->integer);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_APPROX) && (op2->type == CHALK_VALUE_TYPE_FRACTION))
      result = mpfir_cmp_q(op1->realApprox, op2->fraction);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_APPROX) && (op2->type == CHALK_VALUE_TYPE_REAL_EXACT))
      result = mpfir_cmp_fr(op1->realApprox, op2->realExact);
    else if ((op1->type == CHALK_VALUE_TYPE_REAL_APPROX) && (op2->type == CHALK_VALUE_TYPE_REAL_APPROX))
      result = mpfir_cmp(op1->realApprox, op2->realApprox);
  }//end if (op1 && op2)
  return result;
}
//end chalkGmpValueCmp()

BOOL chalkGmpValueIsZero(const chalk_gmp_value_t* value, chalk_compute_flags_t flags)
{
  BOOL result = !value;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
      result = YES;
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = (mpz_sgn(value->integer) == 0);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = (mpq_sgn(value->fraction) == 0);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = mpfr_zero_p(value->realExact);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      result = !(flags&CHALK_COMPUTE_FLAG_ERANGE) && !(flags&CHALK_COMPUTE_FLAG_UNDERFLOW) && mpfir_is_zero(value->realApprox);
  }//end if (value)
  return result;
}
//end chalkGmpValueIsZero()

BOOL chalkGmpValueIsOne(const chalk_gmp_value_t* value, BOOL* isOneIgnoringSign, chalk_compute_flags_t flags)
{
  BOOL result = !value;
  BOOL shouldCheckIgnoringSign = (isOneIgnoringSign != 0);
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
      result = NO;
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
    {
      result = !mpz_cmp_si(value->integer, 1);
      if (shouldCheckIgnoringSign)
        *isOneIgnoringSign = !result && !mpz_cmp_si(value->integer, -1);
    }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      result = !mpq_cmp_si(value->fraction, 1, 1);
      if (shouldCheckIgnoringSign)
        *isOneIgnoringSign = !result && !mpq_cmp_si(value->fraction, -1, 1);
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      result = !mpfr_cmp_si(value->realExact, 1);
      if (shouldCheckIgnoringSign)
        *isOneIgnoringSign = !result && !mpfr_cmp_si(value->realExact, -1);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      result = !(flags&CHALK_COMPUTE_FLAG_ERANGE) && !(flags&CHALK_COMPUTE_FLAG_UNDERFLOW) &&
        !mpfr_cmp_si(&value->realApprox->interval.left, 1) &&
        !mpfr_cmp_si(&value->realApprox->interval.right, 1);
      if (shouldCheckIgnoringSign)
        *isOneIgnoringSign = !result &&
          !mpfr_cmp_si(&value->realApprox->interval.left, -1) &&
          !mpfr_cmp_si(&value->realApprox->interval.right, -1);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if (value)
  return result;
}
//end chalkGmpValueIsOne()

BOOL chalkGmpValueIsNan(const chalk_gmp_value_t* value)
{
  BOOL result = NO;
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    result = mpfr_nan_p(value->realExact);
  else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    result = mpfir_nan_p(value->realApprox);
  return result;
}
//end chalkGmpValueIsNan()

int chalkGmpValueSign(const chalk_gmp_value_t* value)
{
  int result = 0;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = mpz_sgn(value->integer);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = mpq_sgn(value->fraction);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = mpfr_sgn(value->realExact);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      result = mpfir_nan_p(value->realApprox) ? 0 :
               mpfir_inf_p(value->realApprox) && (mpfr_sgn(&value->realApprox->interval.left) == mpfr_sgn(&value->realApprox->interval.right)) ? mpfr_sgn(&value->realApprox->interval.left) :
               mpfir_is_strictly_neg(value->realApprox) ? -1 :
               mpfir_is_strictly_pos(value->realApprox) ?  1 :
               0;
  }//end if (value)
  return result;
}
//end chalkGmpValueSign()

BOOL chalkGmpValueNeg(chalk_gmp_value_t* value)
{
  BOOL result = NO;
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_INTEGER)
  {
    mpz_neg(value->integer, value->integer);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
  else if (value->type == CHALK_VALUE_TYPE_FRACTION)
  {
    mpq_neg(value->fraction, value->fraction);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  {
    mpfr_neg(value->realExact, value->realExact, MPFR_RNDN);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  else if (value->type== CHALK_VALUE_TYPE_REAL_APPROX)
  {
    mpfir_neg(value->realApprox, value->realApprox);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  return result;
}
//end chalkGmpValueNeg()

BOOL chalkGmpValueInvert(chalk_gmp_value_t* value, CHGmpPool* pool)
{
  BOOL result = NO;
  if (!value || chalkGmpValueIsZero(value, 0)){
  }
  else if (value->type == CHALK_VALUE_TYPE_INTEGER)
  {
    mpqDepool(value->fraction, pool);
    mpq_set_z(value->fraction, value->integer);
    mpzRepool(value->integer, pool);
    value->type = CHALK_VALUE_TYPE_FRACTION;
    mpq_inv(value->fraction, value->fraction);
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
  else if (value->type == CHALK_VALUE_TYPE_FRACTION)
  {
    mpq_inv(value->fraction, value->fraction);
    mpq_canonicalize(value->fraction);
    if (!mpz_cmp_si(mpq_denref(value->fraction), 1))//fraction is an integer
    {
      mpzDepool(value->integer, pool);
      mpz_swap(value->integer, mpq_numref(value->fraction));
      mpqRepool(value->fraction, pool);
      value->type = CHALK_VALUE_TYPE_INTEGER;
    }//end if (!mpz_cmp_si(mpq_denref(value->fraction), 1))//fraction is an integer
    result = YES;
  }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  else if ((value->type == CHALK_VALUE_TYPE_REAL_EXACT) || (value->type == CHALK_VALUE_TYPE_REAL_APPROX))
  {
    if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      mpfr_t tmp;
      mpfrDepool(tmp, mpfr_get_prec(value->realExact), pool);
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      mpfr_ui_div(tmp, 1, value->realExact, MPFR_RNDN);
      mpfr_neg(value->realExact, value->realExact, MPFR_RNDN);
      result = !mpfr_inexflag_p();
      if (result)
        mpfr_swap(value->realExact, tmp);
      else
        chalkGmpValueMakeRealApprox(value, mpfr_get_prec(value->realExact), pool);
      mpfrRepool(tmp, pool);
      chalkGmpFlagsRestore(oldFlags);
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    if (value->type== CHALK_VALUE_TYPE_REAL_APPROX)
    {
      mpfir_inv(value->realApprox, value->realApprox);
      result = YES;
    }//end if (value->type== CHALK_VALUE_TYPE_REAL_APPROX)
  }//end if ((value->type == CHALK_VALUE_TYPE_REAL_EXACT) || (value->type == CHALK_VALUE_TYPE_REAL_APPROX))
  return result;
}
//end chalkGmpValueInvert()

CG_INLINE BOOL chalkGMPUnderflowCanDeceiveMpfi(void) {return NO;}

BOOL chalkGmpValueCanSimplify(const chalk_gmp_value_t* value, mp_bitcnt_t maxIntegerBits, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (mpfr_nan_p(&value->realApprox->interval.left) && mpfr_nan_p(&value->realApprox->interval.right))
        result = YES;
      else if (!chalkGMPUnderflowCanDeceiveMpfi() && mpfr_equal_p(&value->realApprox->interval.left, &value->realApprox->interval.right))
        result = YES;
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      if (mpfr_nan_p(value->realExact))
        result = YES;
      else if (mpfr_inf_p(value->realExact))
        result = YES;
      else if (mpfr_fits_z(value->realExact, maxIntegerBits))
      {
        chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
        mpz_t tmpInteger;
        mpzDepool(tmpInteger, pool);
        mpfr_get_z(tmpInteger, value->realExact, MPFR_RNDN);
        result = !mpfr_inexflag_p();
        mpzRepool(tmpInteger, pool);
        chalkGmpFlagsRestore(oldFlags);
      }//end if (mpfr_integer_p(value->realExact))
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      if (mpz_divisible_p(mpq_numref(value->fraction), mpq_denref(value->fraction)))
        result = YES;
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  }//end if (value)
  return result;
}
//end chalkGmpValueCanSimplify()

BOOL chalkGmpValueSimplify(chalk_gmp_value_t* value, mp_bitcnt_t maxIntegerBits, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      if (mpfr_nan_p(&value->realApprox->interval.left) && mpfr_nan_p(&value->realApprox->interval.right))
        result = chalkGmpValueSetNan(value, NO, pool);
      else if (!chalkGMPUnderflowCanDeceiveMpfi() && mpfr_equal_p(&value->realApprox->interval.left, &value->realApprox->interval.right))
      {
        mpfrDepool(value->realExact, mpfir_get_prec(value->realApprox), pool);
        mpfir_get_fr(value->realExact, value->realApprox);
        mpfirRepool(value->realApprox, pool);
        value->type = CHALK_VALUE_TYPE_REAL_EXACT;
        result = YES;
      }//end if (!mpfr_cmp(&value->realApprox->left, &value->realApprox->right))*/
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      if (mpfr_nan_p(value->realExact))
        result |= chalkGmpValueSetNan(value, NO, pool);
      else if (mpfr_inf_p(value->realExact))
        result |= chalkGmpValueSetInfinity(value, mpfr_sgn(value->realExact), NO, pool);
      else if (mpfr_fits_z(value->realExact, maxIntegerBits))
      {
        chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
        mpzDepool(value->integer, pool);
        mpfr_get_z(value->integer, value->realExact, MPFR_RNDN);
        if (mpfr_inexflag_p())
          mpzRepool(value->integer, pool);
        else//if (!mpfr_inexflag_p())
        {
          mpfrRepool(value->realExact, pool);
          value->type = CHALK_VALUE_TYPE_INTEGER;
          result = YES;
        }//end if (!mpfr_inexflag_p())
        chalkGmpFlagsRestore(oldFlags);
      }//end if (mpfr_integer_p(value->realExact))
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      mpq_canonicalize(value->fraction);
      if (!mpz_cmp_si(mpq_denref(value->fraction), 1))//fraction is an integer
      {
        mpzDepool(value->integer, pool);
        mpz_swap(value->integer, mpq_numref(value->fraction));
        value->type = CHALK_VALUE_TYPE_INTEGER;
        mpqRepool(value->fraction, pool);
        result = YES;
      }//end if (mpz_cmp_si(den, 1) == 0)
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  }//end if (value)
  return result;
}
//end chalkGmpValueSimplify()

BOOL chalkGmpValueMake(chalk_gmp_value_t* value, chalk_value_gmp_type_t type, mpfr_prec_t prec, CHGmpPool* pool)
{
  BOOL result = NO;
  switch(type)
  {
    case CHALK_VALUE_TYPE_UNDEFINED:
      result = chalkGmpValueClear(value, YES, pool);
      break;
    case CHALK_VALUE_TYPE_INTEGER:
      result = chalkGmpValueMakeInteger(value, pool);
      break;
    case CHALK_VALUE_TYPE_FRACTION:
      result = chalkGmpValueMakeFraction(value, pool);
      break;
    case CHALK_VALUE_TYPE_REAL_EXACT:
      result = chalkGmpValueMakeRealExact(value, prec, pool);
      break;
    case CHALK_VALUE_TYPE_REAL_APPROX:
      result = chalkGmpValueMakeRealApprox(value, prec, pool);
      break;
  }//end switch(type)
  return result;
}
//end chalkGmpValueMake()

BOOL chalkGmpValueMakeInteger(chalk_gmp_value_t* value, CHGmpPool* pool)
{
  BOOL result = NO;
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
  {
    mpzDepool(value->integer, pool);
    value->type = CHALK_VALUE_TYPE_INTEGER;
  }//end if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
  else if (value->type == CHALK_VALUE_TYPE_INTEGER){
  }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
  else if (value->type == CHALK_VALUE_TYPE_FRACTION)
  {
    mpzDepool(value->integer, pool);
    mpz_set_q(value->integer, value->fraction);
    mpqRepool(value->fraction, pool);
    value->type = CHALK_VALUE_TYPE_INTEGER;
  }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  {
    mpzDepool(value->integer, pool);
    mpfr_get_z(value->integer, value->realExact, MPFR_RNDN);
    mpfrRepool(value->realExact, pool);
    value->type = CHALK_VALUE_TYPE_INTEGER;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  {
    mpzDepool(value->integer, pool);
    mpfr_get_z(value->integer, &value->realApprox->estimation, MPFR_RNDN);
    mpfirRepool(value->realApprox, pool);
    value->type = CHALK_VALUE_TYPE_INTEGER;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  result = value && (value->type == CHALK_VALUE_TYPE_INTEGER);
  return result;
}
//end chalkGmpValueMakeInteger()

BOOL chalkGmpValueMakeFraction(chalk_gmp_value_t* value, CHGmpPool* pool)
{
  BOOL result = NO;
  if (!value){
  }
  else if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
  {
    mpqDepool(value->fraction, pool);
    value->type = CHALK_VALUE_TYPE_FRACTION;
  }//end if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
  else if (value->type == CHALK_VALUE_TYPE_INTEGER)
  {
    mpqDepool(value->fraction, pool);
    mpq_set_z(value->fraction, value->integer);
    value->type = CHALK_VALUE_TYPE_FRACTION;
    mpzRepool(value->integer, pool);
  }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
  else if (value->type == CHALK_VALUE_TYPE_FRACTION){
  }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
  else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  {
    mpzDepool(value->integer, pool);
    mpfr_get_z(value->integer, value->realExact, MPFR_RNDN);
    mpfrRepool(value->realExact, pool);
    mpqDepool(value->fraction, pool);
    mpq_set_z(value->fraction, value->integer);
    mpzRepool(value->integer, pool);
    value->type = CHALK_VALUE_TYPE_FRACTION;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
  else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  {
    mpzDepool(value->integer, pool);
    mpfr_get_z(value->integer, &value->realApprox->estimation, MPFR_RNDN);
    mpfirRepool(value->realApprox, pool);
    mpqDepool(value->fraction, pool);
    mpq_set_z(value->fraction, value->integer);
    mpzRepool(value->integer, pool);
    value->type = CHALK_VALUE_TYPE_FRACTION;
  }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
  result = value && (value->type == CHALK_VALUE_TYPE_FRACTION);
  return result;
}
//end chalkGmpValueMakeFraction()
  
BOOL chalkGmpValueMakeReal(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    {
      mpfrDepool(value->realExact, precision, pool);
      value->type = CHALK_VALUE_TYPE_REAL_EXACT;
    }//end if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
    {
      BOOL done = NO;
      if (mpz_sizeinbase(value->integer, 2) <= precision)
      {
        mpfr_clear_flags();
        mpfrDepool(value->realExact, precision, pool);
        mpfr_set_z(value->realExact, value->integer, MPFR_RNDN);
        if (mpfr_inexflag_p())
          mpfrRepool(value->realExact, pool);
        else//if (!mpfr_inexflag_p())
        {
          mpzRepool(value->integer, pool);
          value->type = CHALK_VALUE_TYPE_REAL_EXACT;
          done = YES;
        }//end if (!mpfr_inexflag_p())
      }//end if (mpz_sizeinbase(value->integer, 2) <= precision)
      if (!done)
      {
        mpfirDepool(value->realApprox, precision, pool);
        mpfir_set_z(value->realApprox, value->integer);
        mpzRepool(value->integer, pool);
        value->type = CHALK_VALUE_TYPE_REAL_APPROX;
      }//end if (!done)
    }//endif (value->type == CHALK_VALUE_TYPE_INTEGER)
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      BOOL done = NO;
      BOOL tryRealExact = NO;
      if (tryRealExact)
      {
        mpfr_clear_flags();
        mpfrDepool(value->realExact, precision, pool);
        mpfr_set_q(value->realExact, value->fraction, MPFR_RNDN);
        if (mpfr_inexflag_p())
          mpfrRepool(value->realExact, pool);
        else//if (!mpfr_inexflag_p())
        {
          mpqRepool(value->fraction, pool);
          value->type = CHALK_VALUE_TYPE_REAL_EXACT;
          done = YES;
        }//end if (!mpfr_inexflag_p())
      }//end if (tryRealExact)
      if (!done)
      {
        mpfirDepool(value->realApprox, precision, pool);
        mpfir_set_q(value->realApprox, value->fraction);
        mpqRepool(value->fraction, pool);
        value->type = CHALK_VALUE_TYPE_REAL_APPROX;
      }//end if (!done)
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
    result = (value->type == CHALK_VALUE_TYPE_REAL_EXACT) || (value->type == CHALK_VALUE_TYPE_REAL_APPROX);
  }//end if (value)
  return result;
}
//end chalkGmpValueMakeReal()

BOOL chalkGmpValueMakeRealExact(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    {
      mpfrDepool(value->realExact, precision, pool);
      value->type = CHALK_VALUE_TYPE_REAL_EXACT;
    }//end if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
    {
      mpfrDepool(value->realExact, precision, pool);
      mpfr_set_z(value->realExact, value->integer, MPFR_RNDN);
      mpzRepool(value->integer, pool);
      value->type = CHALK_VALUE_TYPE_REAL_EXACT;
    }//endif (value->type == CHALK_VALUE_TYPE_INTEGER)
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      mpfrDepool(value->realExact, precision, pool);
      mpfr_set_q(value->realExact, value->fraction, MPFR_RNDN);
      mpqRepool(value->fraction, pool);
      value->type = CHALK_VALUE_TYPE_REAL_EXACT;
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      mpfrDepool(value->realExact, precision, pool);
      mpfr_set(value->realExact, &value->realApprox->estimation, MPFR_RNDN);
      mpfirRepool(value->realApprox, pool);
      value->type = CHALK_VALUE_TYPE_REAL_EXACT;
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
    result = (value->type == CHALK_VALUE_TYPE_REAL_EXACT);
  }//end if (value)
  return result;
}
//end chalkGmpValueMakeRealExact()
  
BOOL chalkGmpValueMakeRealApprox(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool)
{
  BOOL result = NO;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    {
      mpfirDepool(value->realApprox, precision, pool);
      mpfir_set_si(value->realApprox, 0);
      value->type = CHALK_VALUE_TYPE_REAL_APPROX;
    }//end if (value->type == CHALK_VALUE_TYPE_UNDEFINED)
    else if (value->type == CHALK_VALUE_TYPE_INTEGER)
    {
      mpfirDepool(value->realApprox, precision, pool);
      mpfir_set_z(value->realApprox, value->integer);
      mpzRepool(value->integer, pool);
      value->type = CHALK_VALUE_TYPE_REAL_APPROX;
    }//end if (value->type == CHALK_VALUE_TYPE_INTEGER)
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
    {
      mpfirDepool(value->realApprox, precision, pool);
      mpfir_set_q(value->realApprox, value->fraction);
      mpqRepool(value->fraction, pool);
      value->type = CHALK_VALUE_TYPE_REAL_APPROX;
    }//end if (value->type == CHALK_VALUE_TYPE_FRACTION)
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    {
      mpfirDepool(value->realApprox, precision, pool);
      mpfir_set_fr(value->realApprox, value->realExact);
      mpfrRepool(value->realExact, pool);
      value->type = CHALK_VALUE_TYPE_REAL_APPROX;
    }//end if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
    result = (value->type == CHALK_VALUE_TYPE_REAL_APPROX);
  }//end if (value)
  return result;
}
//end chalkGmpValueMakeRealApprox()

CGFloat chalkGmpValueGetCGFloat(const chalk_gmp_value_t* value)
{
  CGFloat result = NAN;
  if (value)
  {
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      result = mpz_get_d(value->integer);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      result = mpq_get_d(value->fraction);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      result = mpfr_get_d(value->realExact, MPFR_RNDN);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      result = mpfr_get_d(&value->realApprox->estimation, MPFR_RNDN);
  }//end if (value)
  return result;
}
//end chalkGmpValueGetCGFloat()

NSUInteger chalkGmpGetMinRoundingDigitsCount(void)
{
  NSUInteger result = 2;//mpfr does not allow 1-digit roundings before 4.0.1
  if ((MPFR_VERSION_MAJOR > 4) ||
      ((MPFR_VERSION_MAJOR == 4) && (MPFR_VERSION_MINOR > 0)) ||
      ((MPFR_VERSION_MAJOR == 4) && (MPFR_VERSION_MINOR == 0) && (MPFR_VERSION_PATCHLEVEL >= 1)))
    result = 1;
  return result;
}
//end chalkGmpGetMinRoundingDigitsCount()

mpfr_prec_t chalkGmpGetRequiredBitsCountForDigitsCount(NSUInteger nbDigits, int base)
{
  mpfr_prec_t result = 0;
  if (nbDigits && (base > 1))
  {
    mpz_t tmp;
    mpz_init_set_nsui(tmp, nbDigits);
    result = chalkGmpGetRequiredBitsCountForDigitsCountZ(tmp, base);
    mpz_clear(tmp);
  }//end if (nbDigits && (base > 1))
  return result;
}
//end chalkGmpGetRequiredBitsCountForDigitsCount()

mpfr_prec_t chalkGmpGetRequiredBitsCountForDigitsCountZ(mpz_srcptr nbDigits, int base)
{
  mpfr_prec_t result = 0;
  if (nbDigits && (base > 1))
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    mpfr_prec_t prec = 8*sizeof(NSUInteger);
    //X<=B^nbDigits
    //log2(X)<=nbDigits*log2(B)
    //result=floor(log2(X))+1<=floor(nbDigits*log2(B))+1
    mpfr_t tmpf;
    mpfr_init2(tmpf, prec);
    mpfr_set_si(tmpf, base, MPFR_RNDU);
    mpfr_log2(tmpf, tmpf, MPFR_RNDU);
    mpfr_mul_z(tmpf, tmpf, nbDigits, MPFR_RNDU);
    mpfr_floor(tmpf, tmpf);
    mpz_t resultz;
    mpz_init_set_si(resultz, 0);
    mpfr_get_z(resultz, tmpf, MPFR_RNDU);
    mpz_add_ui(resultz, resultz, 1);
    result = mpz_get_nsui(resultz);
    mpfr_clear(tmpf);
    mpz_clear(resultz);
    chalkGmpFlagsRestore(oldFlags);
  }//end if (nbDigits && (base > 1))
  return result;
}
//end chalkGmpGetRequiredBitsCountForDigitsCountZ()
  
NSUInteger chalkGmpGetMaximumDigitsCountFromBitsCount(NSUInteger nbBits, int base)
{
  NSUInteger result = mpfr_get_str_ndigits(base, nbBits);
  /*
  if (nbBits && (base > 1))
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    mpfr_prec_t prec = 8*sizeof(NSUInteger);
    //DB=floor(log(X)/log(B))+1
    //D2=floor(log(X)/log(2))+1
    //N1=floor(log(B)/log(2))
    //N2=ceil(log(B)/log(2))
    //N1*(DB-1)+1 <= D2 <= N2*DB
    mpfr_t nf;
    mpfr_init2(nf, prec);
    mpfr_set_si(nf, base, MPFR_RNDU);
    mpfr_log2(nf, nf, MPFR_RNDU);
    mpfr_floor(nf, nf);
    mpz_t numz;
    mpz_init_set_nsui(numz, nbBits);
    mpz_sub_ui(numz, numz, 1);
    mpfr_t numf;
    mpfr_init2(numf, prec);
    mpfr_set_z(numf, numz, MPFR_RNDU);
    mpfr_div(numf, numf, nf, MPFR_RNDU);
    mpfr_get_z(numz, numf, MPFR_RNDU);
    mpz_add_ui(numz, numz, 1);
    result = mpz_get_nsui(numz);
    mpfr_clear(nf);
    mpz_clear(numz);
    mpfr_clear(numf);
    chalkGmpFlagsRestore(oldFlags);
  }//end if (nbBits && (base > 1))*/
  return result;
}
//end chalkGmpGetMaximumDigitsCountFromBitsCount()

NSUInteger chalkGmpGetMaximumExactDigitsCountFromBitsCount(NSUInteger nbBits, int base)
{
  NSUInteger result = mpfr_get_str_ndigits(base, nbBits);
  /*if (base == 2)
    result = nbBits;
  else if (nbBits && (base > 1))
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    mpfr_prec_t prec = 8*sizeof(NSUInteger);
    //http://en.cppreference.com/w/cpp/types/numeric_limits/digits10
    //result = floor((nbBits-1)*std::logB(2))
    mpfr_t tmp1;
    mpfr_t tmp2;
    mpfr_init2(tmp1, prec);
    mpfr_init2(tmp2, prec);
    mpfr_const_log2(tmp1, MPFR_RNDZ);
    mpfr_set_si(tmp2, base, MPFR_RNDA);
    mpfr_log(tmp2, tmp2, MPFR_RNDA);
    mpfr_div(tmp1, tmp1, tmp2, MPFR_RNDZ);
    mpz_t tmp3;
    mpz_init_set_nsui(tmp3, nbBits-1);
    mpfr_mul_z(tmp2, tmp1, tmp3, MPFR_RNDZ);
    mpfr_get_z(tmp3, tmp2, MPFR_RNDZ);
    result = mpz_get_nsui(tmp3);
    mpfr_clear(tmp1);
    mpfr_clear(tmp2);
    mpz_clear(tmp3);
    chalkGmpFlagsRestore(oldFlags);
  }//end if (nbBits && (base > 1))*/
  return result;
}
//end chalkGmpGetMaximumExactDigitsCountFromBitsCount()
    
NSUInteger chalkGmpGetSignificandDigitsCount(mpfr_srcptr f, int base)
{
  NSUInteger result = 0;
  NSUInteger nbBits = mpfr_get_prec(f);//GMP stores the MSB which is implied in IEEE754
  result = chalkGmpGetMaximumExactDigitsCountFromBitsCount(nbBits, base);
  return result;
}
//end chalkGmpGetSignificandDigitsCount()

NSUInteger chalkGmpGetEquivalentBasePower(int base1, NSUInteger power1, int base2)
{
  NSUInteger result = 0;
  if (!chalkGmpBaseIsValid(base1) || !chalkGmpBaseIsValid(base2) || (power1<1)){
  }
  else if (base1 == base2)
    result = power1;
  else//if (chalkGmpBaseIsValid(base1) && chalkGmpBaseIsValid(base2) && (power1>=1) && (base1 != base2))
  {
    mpz_t prime;
    mpz_t mp1;
    mpz_t mp2;
    mpz_init_set_ui(prime, 2);
    mpz_init_set_si(mp1, base1);
    mpz_init_set_si(mp2, base2);
    NSUInteger previousResult = 0;
    NSUInteger currentResult = 0;
    BOOL error = NO;
    BOOL done = NO;
    while(!done && !error)
    {
      NSUInteger currentPrimePower1 = 0;
      NSUInteger currentPrimePower2 = 0;
      while(mpz_divisible_p(mp1, prime))
      {
        ++currentPrimePower1;
        mpz_divexact(mp1, mp1, prime);
      }
      while(mpz_divisible_p(mp2, prime))
      {
        ++currentPrimePower2;
        mpz_divexact(mp2, mp2, prime);
      }
      if (currentPrimePower1)
        currentPrimePower1 *= power1;
      error |= (currentPrimePower1 && !currentPrimePower2) || (!currentPrimePower1 && currentPrimePower2) ||
               (currentPrimePower1 < currentPrimePower2);
      if (!error)
      {
        if (currentPrimePower1 && currentPrimePower2)
        {
          error |= ((currentPrimePower1%currentPrimePower2) != 0);
          if (!error)
            currentResult = currentPrimePower1/currentPrimePower2;
        }//end if (currentPrimePower1 && currentPrimePower2)
      }//end if(!error)
      if (currentResult)
      {
        error |= previousResult && (previousResult != currentResult);
        previousResult = currentResult;
      }//end if (currentResult)
      done = error || (mpz_cmp(prime, mp1)>=0) || (mpz_cmp(prime, mp2)>=0);
      if (!done)
        mpz_nextprime(prime, prime);
    }//end while(!done && !error)
    error |= (mpz_cmp_ui(mp1, 1)>0) || (mpz_cmp_ui(mp2, 1)>0);
    if (!error)
      result = previousResult;
    mpz_clear(prime);
    mpz_clear(mp1);
    mpz_clear(mp2);
  }//end if (chalkGmpBaseIsValid(base1) && chalkGmpBaseIsValid(base2) && (power1>=1) && (base1 != base2))
  return result;
}
//end chalkGmpGetEquivalentBasePower()

NSUInteger chalkGmpMaxDigitsInBase(NSUInteger countBase1, int base1, int base2, CHGmpPool* pool)
{
  NSUInteger result = 0;
  if (base1 == base2)
    result = countBase1;
  else//if (base1 != base2)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
    mpz_t mpCountbase1;
    mpfr_t logBase1;
    mpfr_t logBase2;
    mpfr_t tmp;
    mpzDepool(mpCountbase1, pool);
    mpfr_prec_t prec = 64;
    mpfrDepool(logBase1, prec, pool);
    mpfrDepool(logBase2, prec, pool);
    mpfrDepool(tmp, prec, pool);
    mpz_set_nsui(mpCountbase1, countBase1);
    mpfr_set_si(logBase1, base1, MPFR_RNDA);
    mpfr_set_si(logBase2, base2, MPFR_RNDZ);
    mpfr_log(logBase1, logBase1, MPFR_RNDA);
    mpfr_log(logBase2, logBase2, MPFR_RNDZ);
    mpfr_ceil(logBase1, logBase1);
    mpfr_mul_z(tmp, logBase1, mpCountbase1, MPFR_RNDA);
    mpfr_div(tmp, tmp, logBase2, MPFR_RNDA);
    mpfr_add_ui(tmp, tmp, 1, MPFR_RNDA);
    result = mpfr_get_nsui(tmp, MPFR_RNDA);
    mpzRepool(mpCountbase1, pool);
    mpfrRepool(logBase1, pool);
    mpfrRepool(logBase2, pool);
    mpfrRepool(tmp, pool);
    chalkGmpFlagsRestore(oldFlags);
  }//end if (base1 != base2)
  return result;
}
//end chalkGmpMaxDigitsInBase()

void mpz_min_exponent(mpz_ptr rop, mpz_srcptr exponent, int fromBase, int toBase, CHGmpPool* pool)
{
  if (fromBase == toBase)
    mpz_set(rop, exponent);
  else//if (fromBase != toBase)
  {
    mpfr_prec_t prec = 64;
    mpfr_t logFromBase;
    mpfr_t tmp;
    mpfrDepool(tmp, prec, pool);
    mpfrDepool(logFromBase, prec, pool);
    mpfr_set_si(logFromBase, fromBase, MPFR_RNDZ);
    if (toBase == 2)
      mpfr_log2(tmp, logFromBase, MPFR_RNDZ);
    else if (toBase == 10)
      mpfr_log10(tmp, logFromBase, MPFR_RNDZ);
    else//if ((toBase != 2) && (toBase != 10))
    {
      mpfr_t logToBase;
      mpfrDepool(logToBase, prec, pool);
      mpfr_set_si(logToBase, toBase, MPFR_RNDA);
      mpfr_log(logFromBase, logFromBase, MPFR_RNDZ);
      mpfr_log(logToBase, logToBase, MPFR_RNDA);
      mpfr_div(tmp, logFromBase, logToBase, MPFR_RNDZ);
      mpfrRepool(logToBase, pool);
    }//end if ((toBase != 2) && (toBase != 10))
    mpfr_mul_z(tmp, tmp, exponent, MPFR_RNDZ);
    mpfr_get_z(rop, tmp, MPFR_RNDZ);
    mpfrRepool(tmp, pool);
    mpfrRepool(logFromBase, pool);
  }//end if (base1 != base2)
}
//end mpz_min_exponent()

mp_bitcnt_t mpz_get_msb_zero_count(mpz_srcptr op, NSRange bitsRange)
{
  mp_bitcnt_t result = 0;
  size_t currentLimbsCount = mpz_size(op);
  NSRange currentBitsRange = NSMakeRange(0U, currentLimbsCount*mp_bits_per_limb);
  NSRange impactedBitsRange = NSIntersectionRange(currentBitsRange, bitsRange);
  if (impactedBitsRange.length)
  {
    const mp_limb_t* opLimbs = mpz_limbs_read(op);
    NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
    NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
    NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
    NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
    NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
    NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
    impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
    impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
    if (firstLimbIndex == lastLimbIndex)
    {
      NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
      impactedBitsRangeInLimb.location %= mp_bits_per_limb;
      mp_limb_t protectedBitsMask =
        !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
        (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
        ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
      mp_limb_t limbSaved = opLimbs[firstLimbIndex];
      limbSaved &= ~protectedBitsMask;//set to 0 the protected bits
      if (!limbSaved)
        result += impactedBitsRangeInLimb.length;
      else//if (limbSaved)
      {
        const mp_limb_t msbOne = ((mp_limb_t)1)<<(NSMaxRange(impactedBitsRangeInLimb)-1);
        while(!(limbSaved&msbOne))
        {
          ++result;
          limbSaved <<= 1;
        }//end while(!(limbSaved&msbOne))
      }//end if (limbSaved)
    }//end if (firstLimbIndex == lastLimbIndex)
    else//if (firstLimbIndex != lastLimbIndex)
    {
      mp_limb_t bitsProtectedInFirstRangeMask =
        !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
        (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
        ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
      mp_limb_t bitsProtectedInLastRangeMask =
        !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
        (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
        ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
      mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
      mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
      firstLimbSaved &= ~bitsProtectedInFirstRangeMask;//set to 0 the protected bits
      lastLimbSaved &= ~bitsProtectedInLastRangeMask;//set to 0 the protected bits
      BOOL done = NO;
      if (!done)
      {
        if (!lastLimbSaved)
          result += impactedBitsRangeInLastRange.length;
        else//if (lastLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1)<<(NSMaxRange(impactedBitsRangeInLastRange)-1);
          while(!(lastLimbSaved&msbOne))
          {
            ++result;
            lastLimbSaved <<= 1;
          }//end while(!(lastLimbSaved&msbOne))
          done = YES;
        }//end if (lastLimbSaved)
      }//end if (!done)
      for(NSUInteger limbIndex = lastLimbIndex-1 ; !done && (limbIndex > firstLimbIndex) ; --limbIndex)
      {
        mp_limb_t limb = opLimbs[limbIndex];
        if (!limb)
          result += mp_bits_per_limb;
        else//if (lastLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1)<<(mp_bits_per_limb-1);
          while(!(limb&msbOne))
          {
            ++result;
            limb <<= 1;
          }//end while(!(limb&msbOne))
          done = YES;
        }//end if (lastLimbSaved)
      }//end if (lastLimbSaved)
      if (!done)
      {
        if (!firstLimbSaved)
          result += impactedBitsRangeInFirstRange.length;
        else//if (firstLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1)<<(mp_bits_per_limb-1);
          while(!(firstLimbSaved&msbOne))
          {
            ++result;
            firstLimbSaved <<= 1;
          }//end while(!(lastLimbSaved&msbOne))
          done = YES;
        }//end if (firstLimbSaved)
      }//end if (!done)
    }//end if (firstLimbIndex != lastLimbIndex)
  }//end if (impactedBitsRange.length)
  result += (NSMaxRange(bitsRange)-NSMaxRange(impactedBitsRange));
  return result;
}
//end mpz_get_msb_zero_count()

mp_bitcnt_t mpz_get_lsb_zero_count(mpz_srcptr op, NSRange bitsRange)
{
  mp_bitcnt_t result = 0;
  size_t currentLimbsCount = mpz_size(op);
  NSRange currentBitsRange = NSMakeRange(0U, currentLimbsCount*mp_bits_per_limb);
  NSRange impactedBitsRange = NSIntersectionRange(currentBitsRange, bitsRange);
  if (impactedBitsRange.length)
  {
    const mp_limb_t* opLimbs = mpz_limbs_read(op);
    NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
    NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
    NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
    NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
    NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
    NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
    impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
    impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
    BOOL done = NO;
    if (firstLimbIndex == lastLimbIndex)
    {
      NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
      impactedBitsRangeInLimb.location %= mp_bits_per_limb;
      mp_limb_t protectedBitsMask =
        !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
        (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
        ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
      mp_limb_t limbSaved = opLimbs[firstLimbIndex];
      limbSaved &= ~protectedBitsMask;//set to 0 the protected bits
      if (!limbSaved)
        result += impactedBitsRangeInLimb.length;
      else//if (limbSaved)
      {
        const mp_limb_t msbOne = ((mp_limb_t)1<<impactedBitsRangeInLimb.location);
        while(!(limbSaved&msbOne))
        {
          ++result;
          limbSaved >>= 1;
        }//end while(!(limbSaved&msbOne))
      }//end if (limbSaved)
    }//end if (firstLimbIndex == lastLimbIndex)
    else//if (firstLimbIndex != lastLimbIndex)
    {
      mp_limb_t bitsProtectedInFirstRangeMask =
        !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
        (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
        ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
      mp_limb_t bitsProtectedInLastRangeMask =
        !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
        (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
        ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
      mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
      mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
      firstLimbSaved &= ~bitsProtectedInFirstRangeMask;//set to 0 the protected bits
      lastLimbSaved &= ~bitsProtectedInLastRangeMask;//set to 0 the protected bits
      if (!done)
      {
        if (!firstLimbSaved)
          result += impactedBitsRangeInFirstRange.length;
        else//if (firstLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1)<<impactedBitsRangeInFirstRange.location;
          while(!(firstLimbSaved&msbOne))
          {
            ++result;
            firstLimbSaved >>= 1;
          }//end while(!(lastLimbSaved&msbOne))
          done = YES;
        }//end if (firstLimbSaved)
      }//end if (!done)
      for(NSUInteger limbIndex = firstLimbIndex+1 ; !done && (limbIndex < lastLimbIndex) ; ++limbIndex)
      {
        mp_limb_t limb = opLimbs[limbIndex];
        if (!limb)
          result += mp_bits_per_limb;
        else//if (lastLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1);
          while(!(limb&msbOne))
          {
            ++result;
            limb >>= 1;
          }//end while(!(limb&msbOne))
          done = YES;
        }//end if (lastLimbSaved)
      }//end if (lastLimbSaved)
      if (!done)
      {
        if (!lastLimbSaved)
          result += impactedBitsRangeInLastRange.length;
        else//if (lastLimbSaved)
        {
          const mp_limb_t msbOne = ((mp_limb_t)1);
          while(!(lastLimbSaved&msbOne))
          {
            ++result;
            lastLimbSaved >>= 1;
          }//end while(!(lastLimbSaved&msbOne))
          done = YES;
        }//end if (lastLimbSaved)
      }//end if (!done)
    }//end if (firstLimbIndex != lastLimbIndex)
  }//end if (impactedBitsRange.length)
  result += (impactedBitsRange.location-bitsRange.location);
  return result;
}
//end mpz_get_lsb_zero_count()

void mpz_set_zero(mpz_ptr op, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          opLimbs[firstLimbIndex] = 0;
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          for(NSUInteger index = 0 ; index<requiredLimbsCount ; ++index)
            opLimbs[index] = 0;
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && rollValue)
}
//end mpz_set_zero()

void mpz_set_one(mpz_ptr op, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          opLimbs[firstLimbIndex] = ~0;
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          for(NSUInteger index = 0 ; index<requiredLimbsCount ; ++index)
            opLimbs[index] = ~0;
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && rollValue)
}
//end mpz_set_one()

void mpz_complement1(mpz_ptr op, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          opLimbs[firstLimbIndex] = ~opLimbs[firstLimbIndex];
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          for(NSUInteger index = 0 ; index<requiredLimbsCount ; ++index)
            opLimbs[index] = ~opLimbs[index];
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && rollValue)
}
//end mpz_complement1()

void mpz_shift_left(mpz_ptr op, mp_bitcnt_t shiftValue, NSRange bitsRange)
{
  NSUInteger currentLimbsCount = mpz_size(op);
  if (currentLimbsCount && bitsRange.length && shiftValue)
  {
    size_t nextLimbsCount = (mpz_sizeinbase(op, 2)+shiftValue+mp_bits_per_limb-1)/mp_bits_per_limb;
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, nextLimbsCount);
    if (opLimbs)
    {
      if (nextLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, nextLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, nextLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          if (shiftValue >= impactedBitsRangeInLimb.length)
            opLimbs[firstLimbIndex] = (limbSaved & protectedBitsMask);
          else//if (shift < impactedBitsRangeInLimb.length)
          {
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            mpn_lshift(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, 1, (unsigned int)shiftValue);
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
          }//end //if (shift < impactedBitsRangeInLimb.length)
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          mp_bitcnt_t remainingShift = shiftValue;
          while(remainingShift)
          {
            unsigned int subShift = (unsigned int)MIN(remainingShift, mp_bits_per_limb-1);
            mpn_lshift(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, (lastLimbIndex-firstLimbIndex+1), subShift);
            remainingShift -= subShift;
          }//end while(remainingShift)
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, nextLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && shiftValue)
}
//end mpz_shift_left()

void mpz_shift_right(mpz_ptr op, mp_bitcnt_t shiftValue, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  if (currentLimbsCount && bitsRange.length && shiftValue)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, currentLimbsCount);
    if (opLimbs)
    {
      NSRange naturalBitsRange = NSMakeRange(0, currentLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          if (shiftValue >= impactedBitsRangeInLimb.length)
            opLimbs[firstLimbIndex] = (limbSaved & protectedBitsMask);
          else//if (shift < impactedBitsRangeInLimb.length)
          {
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            mpn_rshift(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, 1, (unsigned int)shiftValue);
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
          }//end //if (shift < impactedBitsRangeInLimb.length)
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          mp_bitcnt_t remainingShift = shiftValue;
          while(remainingShift)
          {
            unsigned int subShift = (unsigned int)MIN(remainingShift, mp_bits_per_limb-1);
            mpn_rshift(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, (lastLimbIndex-firstLimbIndex+1), subShift);
            remainingShift -= subShift;
          }//end while(remainingShift)
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, currentLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && shiftValue)
}
//end mpz_shift_right()

void mpz_roll_left(mpz_ptr op, mp_bitcnt_t rollValue, NSRange bitsRange)
{
  if (bitsRange.length)
  {
    rollValue %= bitsRange.length;
    mp_bitcnt_t msbZerosCount = mpz_get_msb_zero_count(op, bitsRange);
    msbZerosCount = MIN(msbZerosCount, rollValue);
    if (msbZerosCount)
    {
      mpz_shift_left(op, msbZerosCount, bitsRange);
      rollValue -= msbZerosCount;
    }//end if (msbZerosCount)
  }//end if (bitsRange.length)
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length && rollValue)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          mp_limb_t limb = limbSaved&(~protectedBitsMask);
          unsigned long leftShift = rollValue%impactedBitsRange.length;
          unsigned long rightShift = impactedBitsRange.length-leftShift;
          opLimbs[firstLimbIndex] = (limb<<leftShift) | (limb>>rightShift);
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          unsigned long leftShift = rollValue%impactedBitsRange.length;
          unsigned long rightShift = impactedBitsRange.length-leftShift;
          mpz_t tmp;
          mpz_init_set(tmp, op);
          unsigned long remainingLeftShift = leftShift;
          while(remainingLeftShift)
          {
            unsigned int currentLeftShift = (unsigned int)MIN(remainingLeftShift, mp_bits_per_limb-1);
            mpn_lshift(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, lastLimbIndex-firstLimbIndex+1, currentLeftShift);
            remainingLeftShift -= currentLeftShift;
          }//end while(remainingLeftShift)
          mp_limb_t* tmpLimbs = mpz_limbs_modify(tmp, requiredLimbsCount);
          if (requiredLimbsCount > currentLimbsCount)
            mpn_zero(tmpLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
          unsigned long remainingRightShift = rightShift;
          while(remainingRightShift)
          {
            unsigned int currentRightShift = (unsigned int)MIN(remainingRightShift, mp_bits_per_limb-1);
            mpn_rshift(tmpLimbs+firstLimbIndex, tmpLimbs+firstLimbIndex, lastLimbIndex-firstLimbIndex+1, currentRightShift);
            remainingRightShift -= currentRightShift;
          }//end while(remainingRightShift)
          
          #pragma TODO
          mp_bitcnt_t bitsProtectedCountInFirstRange =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            impactedBitsRangeInFirstRange.location;
          mp_bitcnt_t relevantBitsFromTmp = leftShift;
          NSUInteger tmpRelevantFirstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
          NSUInteger tmpRelevantLimbsCount = (bitsProtectedCountInFirstRange+leftShift+mp_bits_per_limb-1)/mp_bits_per_limb;
          NSUInteger tmpRelevantLastLimbIndex = !tmpRelevantLimbsCount ? tmpRelevantFirstLimbIndex :
            tmpRelevantFirstLimbIndex+tmpRelevantLimbsCount-1;
          for(NSUInteger index = tmpRelevantFirstLimbIndex ; index<tmpRelevantLastLimbIndex ; ++index)
            opLimbs[index] = tmpLimbs[index];
          mp_bitcnt_t relevantBitsCountInLastTmpLimb = (bitsProtectedCountInFirstRange+relevantBitsFromTmp)%mp_bits_per_limb;
          mp_limb_t bitsProtectedInLastTmpLimbMask =
            !relevantBitsCountInLastTmpLimb ? MP_LIMB_MAX :
            (relevantBitsCountInLastTmpLimb == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<relevantBitsCountInLastTmpLimb)-1);
          if (tmpRelevantLastLimbIndex == firstLimbIndex)
            bitsProtectedInLastTmpLimbMask |= bitsProtectedInFirstRangeMask;
          if (tmpRelevantLastLimbIndex == lastLimbIndex)
            bitsProtectedInLastTmpLimbMask |= bitsProtectedInLastRangeMask;
          if (tmpRelevantLimbsCount)
            opLimbs[tmpRelevantLastLimbIndex] =
              (opLimbs[tmpRelevantLastLimbIndex] & bitsProtectedInLastTmpLimbMask) |
              (tmpLimbs[tmpRelevantLastLimbIndex] & ~bitsProtectedInLastTmpLimbMask);
          mpz_limbs_finish(tmp, requiredLimbsCount);
          mpz_clear(tmp);
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (requiredLimbsCount && bitsRange.length && rollValue)
}
//end mpz_roll_left()

void mpz_roll_right(mpz_ptr op, mp_bitcnt_t rollValue, NSRange bitsRange)
{
  if (bitsRange.length)
  {
    rollValue %= bitsRange.length;
    mp_bitcnt_t lsbZerosCount = mpz_get_lsb_zero_count(op, bitsRange);
    lsbZerosCount = MIN(lsbZerosCount, rollValue);
    if (lsbZerosCount)
    {
      mpz_shift_right(op, lsbZerosCount, bitsRange);
      rollValue -= lsbZerosCount;
    }//end if (msbZerosCount)
  }//end if (bitsRange.length)
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length && rollValue)
  {
    NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
    NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
    if (impactedBitsRange.length)
    {
      rollValue %= impactedBitsRange.length;
      mp_bitcnt_t equivalentRollValue = impactedBitsRange.length-rollValue;
      mpz_roll_left(op, equivalentRollValue, bitsRange);
    }//end if (impactedBitsRange.length)
  }//end if (requiredLimbsCount && bitsRange.length && rollValue)
}
//end mpz_roll_right()

void mpz_swap_packets_pairs(mpz_ptr op, mp_bitcnt_t packetBitSize, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  if (currentLimbsCount && bitsRange.length && (packetBitSize > 0))
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, currentLimbsCount);
    if (opLimbs)
    {
      NSRange naturalBitsRange = NSMakeRange(0, currentLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        size_t tmpLimbsCount = (2*packetBitSize+mp_bits_per_limb-1)/mp_bits_per_limb;
        mp_limb_t* tmpLimbs = calloc(tmpLimbsCount, sizeof(mp_limb_t));
        if (tmpLimbs)
        {
          NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
          NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
          NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
          NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
          NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
          NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
          impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
          impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
          if (firstLimbIndex == lastLimbIndex)
          {
            NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
            impactedBitsRangeInLimb.location %= mp_bits_per_limb;
            mp_limb_t protectedBitsMask =
              !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
              (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
              ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
            mp_limb_t limbSaved = opLimbs[firstLimbIndex];
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            mp_bitcnt_t twoPacketsBitSize = 2*packetBitSize;
            NSRange currentTwoPacketsRange = NSMakeRange(0, twoPacketsBitSize);
            currentTwoPacketsRange = NSIntersectionRange(currentTwoPacketsRange, impactedBitsRangeInLimb);
            while(currentTwoPacketsRange.length == twoPacketsBitSize)
            {
              NSRange currentFirstPacketRange = NSMakeRange(currentTwoPacketsRange.location, packetBitSize);
              NSRange currentSecondPacketRange = NSMakeRange(currentTwoPacketsRange.location+packetBitSize, packetBitSize);
              memset(tmpLimbs, 0, tmpLimbsCount*sizeof(mp_limb_t));
              mpn_copyBits(tmpLimbs, tmpLimbsCount,             0, &opLimbs[firstLimbIndex], 1, currentSecondPacketRange, 0);
              mpn_copyBits(tmpLimbs, tmpLimbsCount, packetBitSize, &opLimbs[firstLimbIndex], 1, currentFirstPacketRange, 0);
              mpn_copyBits(&opLimbs[firstLimbIndex], 1, currentFirstPacketRange.location, tmpLimbs, tmpLimbsCount, NSMakeRange(0, packetBitSize), 0);
              mpn_copyBits(&opLimbs[firstLimbIndex], 1, currentSecondPacketRange.location, tmpLimbs, tmpLimbsCount, NSMakeRange(packetBitSize, packetBitSize), 0);
              currentTwoPacketsRange.location += currentTwoPacketsRange.length;
              currentTwoPacketsRange = NSIntersectionRange(currentTwoPacketsRange, impactedBitsRangeInLimb);
            }//end while(currentTwoPacketsRange.length > 0)
            opLimbs[firstLimbIndex] &= ~protectedBitsMask;
            opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
          }//end if (firstLimbIndex == lastLimbIndex)
          else//if (firstLimbIndex != lastLimbIndex)
          {
            mp_limb_t bitsProtectedInFirstRangeMask =
              !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
              (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
              ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
            mp_limb_t bitsProtectedInLastRangeMask =
              !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
              (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
              ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
            mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
            mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
            opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
            opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;

            mp_bitcnt_t twoPacketsBitSize = 2*packetBitSize;
            NSRange currentTwoPacketsRange = NSMakeRange(bitsRange.location, twoPacketsBitSize);
            currentTwoPacketsRange = NSIntersectionRange(currentTwoPacketsRange, bitsRange);
            while(currentTwoPacketsRange.length == twoPacketsBitSize)
            {
              NSRange currentFirstPacketRange = NSMakeRange(currentTwoPacketsRange.location, packetBitSize);
              NSRange currentSecondPacketRange = NSMakeRange(currentTwoPacketsRange.location+packetBitSize, packetBitSize);
              mpn_copyBits(tmpLimbs, tmpLimbsCount,             0, opLimbs, currentLimbsCount, currentSecondPacketRange, 0);
              mpn_copyBits(tmpLimbs, tmpLimbsCount, packetBitSize, opLimbs, currentLimbsCount, currentFirstPacketRange, 0);
              mpn_copyBits(opLimbs, currentLimbsCount, currentFirstPacketRange.location, tmpLimbs, tmpLimbsCount, NSMakeRange(0, packetBitSize), 0);
              mpn_copyBits(opLimbs, currentLimbsCount, currentSecondPacketRange.location, tmpLimbs, tmpLimbsCount, NSMakeRange(packetBitSize, packetBitSize), 0);
              currentTwoPacketsRange.location += currentTwoPacketsRange.length;
              currentTwoPacketsRange = NSIntersectionRange(currentTwoPacketsRange, bitsRange);
            }//end while(currentTwoPacketsRange.length > 0)

            
            opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
            opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
            opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
            opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
          }//end if (firstLimbIndex != lastLimbIndex)
          free(tmpLimbs);
        }//end if (tmpLimbs)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, currentLimbsCount);
    }//end if (opLimbs)
  }//end if (currentLimbsCount && bitsRange.length && (packetBitSize > 0))
}
//end mpz_swap_packets_pairs()

void mpz_add_one(mpz_ptr op, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          mpn_add_1(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, 1, MP_LIMB_ONE<<impactedBitsRangeInLimb.location);
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          mpn_add_1(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, requiredLimbsCount, MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location);
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (requiredLimbsCount && bitsRange.length)
}
//end mpz_add_one()

void mpz_sub_one(mpz_ptr op, NSRange bitsRange)
{
  size_t currentLimbsCount = mpz_size(op);
  size_t requiredLimbsCount = (bitsRange.location+bitsRange.length+mp_bits_per_limb-1)/mp_bits_per_limb;
  if (requiredLimbsCount && bitsRange.length)
  {
    mp_limb_t* opLimbs = mpz_limbs_modify_safe(op, requiredLimbsCount);
    if (opLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(opLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSRange naturalBitsRange = NSMakeRange(0, requiredLimbsCount*mp_bits_per_limb);
      NSRange impactedBitsRange = NSIntersectionRange(naturalBitsRange, bitsRange);
      if (impactedBitsRange.length)
      {
        NSUInteger firstLimbIndex = impactedBitsRange.location/mp_bits_per_limb;
        NSUInteger lastLimbIndex = (NSMaxRange(impactedBitsRange)-1)/mp_bits_per_limb;
        NSRange firstLimbNaturalBitsRange = NSMakeRange(firstLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange lastLimbNaturalBitsRange = NSMakeRange(lastLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange impactedBitsRangeInFirstRange = NSIntersectionRange(impactedBitsRange, firstLimbNaturalBitsRange);
        NSRange impactedBitsRangeInLastRange = NSIntersectionRange(impactedBitsRange, lastLimbNaturalBitsRange);
        impactedBitsRangeInFirstRange.location %= mp_bits_per_limb;
        impactedBitsRangeInLastRange.location %= mp_bits_per_limb;
        if (firstLimbIndex == lastLimbIndex)
        {
          NSRange impactedBitsRangeInLimb = NSIntersectionRange(impactedBitsRangeInFirstRange, impactedBitsRangeInLastRange);
          impactedBitsRangeInLimb.location %= mp_bits_per_limb;
          mp_limb_t protectedBitsMask =
            !impactedBitsRangeInLimb.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLimb.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInLimb.length)-1)<<impactedBitsRangeInLimb.location);
          mp_limb_t limbSaved = opLimbs[firstLimbIndex];
          mpn_sub_1(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, 1, MP_LIMB_ONE<<impactedBitsRangeInLimb.location);
          opLimbs[firstLimbIndex] &= ~protectedBitsMask;
          opLimbs[firstLimbIndex] |= (limbSaved & protectedBitsMask);
        }//end if (firstLimbIndex == lastLimbIndex)
        else//if (firstLimbIndex != lastLimbIndex)
        {
          mp_limb_t bitsProtectedInFirstRangeMask =
            !impactedBitsRangeInFirstRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInFirstRange.length == mp_bits_per_limb) ? 0 :
            ~(((MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location)-1)<<impactedBitsRangeInFirstRange.location);
          mp_limb_t bitsProtectedInLastRangeMask =
            !impactedBitsRangeInLastRange.length ? MP_LIMB_MAX :
            (impactedBitsRangeInLastRange.length == mp_bits_per_limb) ? 0 :
            ~((MP_LIMB_ONE<<impactedBitsRangeInLastRange.length)-1);
          mp_limb_t firstLimbSaved = opLimbs[firstLimbIndex];
          mp_limb_t lastLimbSaved = opLimbs[lastLimbIndex];
          mpn_sub_1(opLimbs+firstLimbIndex, opLimbs+firstLimbIndex, requiredLimbsCount, MP_LIMB_ONE<<impactedBitsRangeInFirstRange.location);
          opLimbs[firstLimbIndex] &= ~bitsProtectedInFirstRangeMask;
          opLimbs[firstLimbIndex] |= (firstLimbSaved & bitsProtectedInFirstRangeMask);
          opLimbs[lastLimbIndex] &= ~bitsProtectedInLastRangeMask;
          opLimbs[lastLimbIndex] |= (lastLimbSaved & bitsProtectedInLastRangeMask);
        }//end if (firstLimbIndex != lastLimbIndex)
      }//end if (impactedBitsRange.length)
      mpz_limbs_finish(op, requiredLimbsCount);
    }//end if (opLimbs)
  }//end if (requiredLimbsCount && bitsRange.length)
}
//end mpz_sub_one()

mp_bitcnt_t mpn_copyBits(mp_limb_t* dstLimbs, size_t dstLimbsCount, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError)
{
  mp_bitcnt_t result = 0;
  if (dstLimbs && srcBitRange.length)
  {
    mp_bitcnt_t dstBitEnd = dstBitIndex+srcBitRange.length;
    BOOL overflow = (dstBitEnd < MAX(dstBitIndex, srcBitRange.length)) || (dstBitEnd+mp_bits_per_limb-1 < dstBitEnd);
    mp_size_t requiredLimbsCount = (dstBitEnd+mp_bits_per_limb-1)/mp_bits_per_limb;
    BOOL ok = (!overflow && (dstLimbsCount >= requiredLimbsCount));
    if (ok)
    {
      NSUInteger dstCurrentBitIndex = dstBitIndex;
      NSRange srcRemainingRange = srcBitRange;
      BOOL stop = !srcRemainingRange.length;
      while(!stop)
      {
        mp_size_t dstCurrentLimbIndex = dstCurrentBitIndex/mp_bits_per_limb;
        assert(dstCurrentLimbIndex < requiredLimbsCount);
        mp_bitcnt_t dstCurrentBitIndexInCurrentLimb = dstCurrentBitIndex%mp_bits_per_limb;
        mp_limb_t* dstCurrentLimb = (dstCurrentLimbIndex<requiredLimbsCount) ? dstLimbs+dstCurrentLimbIndex : 0;
        mp_bitcnt_t dstCurrentLimbFreeBits = !dstCurrentLimb ? mp_bits_per_limb :
          (mp_bits_per_limb-dstCurrentBitIndexInCurrentLimb);
        assert(dstCurrentLimb != 0);
        NSUInteger srcCurrentLimbIndex = srcRemainingRange.location/mp_bits_per_limb;
        const mp_limb_t* srcCurrentLimbPointer = (srcCurrentLimbIndex < srcLimbsCount) ? src+srcCurrentLimbIndex : 0;
        mp_limb_t srcCurrentLimbValue = !srcCurrentLimbPointer ? 0 : *srcCurrentLimbPointer;
        NSRange srcCurrentLimbBitRange = NSMakeRange(srcCurrentLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange srcCurrentLimbUsefulBitRange = NSIntersectionRange(srcCurrentLimbBitRange, srcRemainingRange);
        srcCurrentLimbUsefulBitRange.length = MIN(srcCurrentLimbUsefulBitRange.length, dstCurrentLimbFreeBits);
        NSRange srcCurrentLimbUsefulBitRangeLocal = NSMakeRange(srcCurrentLimbUsefulBitRange.location-srcCurrentLimbBitRange.location, srcCurrentLimbUsefulBitRange.length);
        mp_limb_t srcCurrentValueShiftedMask = (srcCurrentLimbUsefulBitRange.length == mp_bits_per_limb) ? MP_LIMB_MAX : ((MP_LIMB_ONE<<srcCurrentLimbUsefulBitRange.length)-1);
        mp_limb_t srcCurrentValueShifted = ((srcCurrentLimbValue >> srcCurrentLimbUsefulBitRangeLocal.location) & srcCurrentValueShiftedMask);
      
        mp_bitcnt_t bitsToCopy = srcCurrentLimbUsefulBitRangeLocal.length;
        if (dstCurrentLimb)
        {
          mp_limb_t dstMask = (bitsToCopy == mp_bits_per_limb) ? MP_LIMB_MAX :
            (((MP_LIMB_ONE<<bitsToCopy)-1)<<dstCurrentBitIndexInCurrentLimb);
          *dstCurrentLimb &= ~dstMask;
          *dstCurrentLimb |= (srcCurrentValueShifted<<dstCurrentBitIndexInCurrentLimb);
        }//end if (dstCurrentLimb)
        srcRemainingRange.location += bitsToCopy;
        srcRemainingRange.length   -= bitsToCopy;
        dstCurrentBitIndex += bitsToCopy;
        stop |= !srcRemainingRange.length;
      }//end while(remainingBits)
      result = (dstCurrentBitIndex-dstBitIndex);
    }//end if (ok)
    if (outError)
      *outError = !ok;
  }//end if (dstLimbs && srcBitRange.length)
  return result;
}
//end mpn_copyBits()

mp_bitcnt_t mpz_copyBits(mpz_ptr dst, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError)
{
  mp_bitcnt_t result = 0;
  if (dst && srcBitRange.length)
  {
    mp_bitcnt_t dstBitEnd = dstBitIndex+srcBitRange.length;
    BOOL overflow = (dstBitEnd < MAX(dstBitIndex, srcBitRange.length)) || (dstBitEnd+mp_bits_per_limb-1 < dstBitEnd);
    size_t currentLimbsCount = mpz_size(dst);
    mp_size_t requiredLimbsCount = (dstBitEnd+mp_bits_per_limb-1)/mp_bits_per_limb;
    mp_limb_t* dstLimbs = overflow ? 0 : mpz_limbs_modify_safe(dst, requiredLimbsCount);
    if (!dstLimbs && outError)
      *outError = YES;
    else if (dstLimbs)
    {
      if (requiredLimbsCount > currentLimbsCount)
        mpn_zero(dstLimbs+currentLimbsCount, requiredLimbsCount-currentLimbsCount);
      NSUInteger dstCurrentBitIndex = dstBitIndex;
      NSRange srcRemainingRange = srcBitRange;
      BOOL stop = !srcRemainingRange.length;
      while(!stop)
      {
        mp_size_t dstCurrentLimbIndex = dstCurrentBitIndex/mp_bits_per_limb;
        assert(dstCurrentLimbIndex < requiredLimbsCount);
        mp_bitcnt_t dstCurrentBitIndexInCurrentLimb = dstCurrentBitIndex%mp_bits_per_limb;
        mp_limb_t* dstCurrentLimb = (dstCurrentLimbIndex<requiredLimbsCount) ? dstLimbs+dstCurrentLimbIndex : 0;
        mp_bitcnt_t dstCurrentLimbFreeBits = !dstCurrentLimb ? mp_bits_per_limb :
          (mp_bits_per_limb-dstCurrentBitIndexInCurrentLimb);
        assert(dstCurrentLimb != 0);
        NSUInteger srcCurrentLimbIndex = srcRemainingRange.location/mp_bits_per_limb;
        const mp_limb_t* srcCurrentLimbPointer = (srcCurrentLimbIndex < srcLimbsCount) ? src+srcCurrentLimbIndex : 0;
        mp_limb_t srcCurrentLimbValue = !srcCurrentLimbPointer ? 0 : *srcCurrentLimbPointer;
        NSRange srcCurrentLimbBitRange = NSMakeRange(srcCurrentLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange srcCurrentLimbUsefulBitRange = NSIntersectionRange(srcCurrentLimbBitRange, srcRemainingRange);
        srcCurrentLimbUsefulBitRange.length = MIN(srcCurrentLimbUsefulBitRange.length, dstCurrentLimbFreeBits);
        NSRange srcCurrentLimbUsefulBitRangeLocal = NSMakeRange(srcCurrentLimbUsefulBitRange.location-srcCurrentLimbBitRange.location, srcCurrentLimbUsefulBitRange.length);
        mp_limb_t srcCurrentValueShiftedMask = (srcCurrentLimbUsefulBitRange.length == mp_bits_per_limb) ? MP_LIMB_MAX : ((MP_LIMB_ONE<<srcCurrentLimbUsefulBitRange.length)-1);
        mp_limb_t srcCurrentValueShifted = ((srcCurrentLimbValue >> srcCurrentLimbUsefulBitRangeLocal.location) & srcCurrentValueShiftedMask);
      
        mp_bitcnt_t bitsToCopy = srcCurrentLimbUsefulBitRangeLocal.length;
        if (dstCurrentLimb)
        {
          mp_limb_t dstMask = (bitsToCopy == mp_bits_per_limb) ? MP_LIMB_MAX :
            (((MP_LIMB_ONE<<bitsToCopy)-1)<<dstCurrentBitIndexInCurrentLimb);
          *dstCurrentLimb &= ~dstMask;
          *dstCurrentLimb |= (srcCurrentValueShifted<<dstCurrentBitIndexInCurrentLimb);
        }//end if (dstCurrentLimb)
        srcRemainingRange.location += bitsToCopy;
        srcRemainingRange.length   -= bitsToCopy;
        dstCurrentBitIndex += bitsToCopy;
        stop |= !srcRemainingRange.length;
      }//end while(remainingBits)
      mpz_limbs_finish(dst, ((mpz_sgn(dst) < 0) ? -1 : 1)*(requiredLimbsCount));
      result = (dstCurrentBitIndex-dstBitIndex);
    }//end if (dstLimbs)
  }//end if (dst && srcBitRange.length)
  return result;
}
//end mpz_copyBits()

mp_bitcnt_t mpfr_copyBits(mpfr_ptr dst, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError)
{
  mp_bitcnt_t result = 0;
  if (dst && srcBitRange.length)
  {
    mp_bitcnt_t dstBitEnd = dstBitIndex+srcBitRange.length;
    mp_size_t dstLimbsCount = (dstBitEnd+mp_bits_per_limb-1)/mp_bits_per_limb;
    
    //mp_bitcnt_t dstLimbsBitsCount = dstLimbsCount*mp_bits_per_limb;
    mpfr_prec_t precRequested = MAX(mpfr_get_prec(dst), dstBitIndex+srcBitRange.length);
    if ((precRequested > MPFR_PREC_MAX) && outError)
      *outError = YES;
    else if (precRequested <= MPFR_PREC_MAX)
    {
      mpfr_prec_round(dst, precRequested, MPFR_RNDN);
      mp_limb_t* dstLimbs = dst->_mpfr_d;
      NSUInteger dstCurrentBitIndex = dstBitIndex;
      NSRange srcRemainingRange = srcBitRange;
      BOOL stop = !srcRemainingRange.length;
      while(!stop)
      {
        mp_size_t dstCurrentLimbIndex = dstCurrentBitIndex/mp_bits_per_limb;
        mp_bitcnt_t dstCurrentBitIndexInCurrentLimb = dstCurrentBitIndex%mp_bits_per_limb;
        mp_limb_t* dstCurrentLimb = (dstCurrentLimbIndex<dstLimbsCount) ? dstLimbs+dstCurrentLimbIndex : 0;
        mp_bitcnt_t dstCurrentLimbFreeBits = !dstCurrentLimb ? mp_bits_per_limb :
          (mp_bits_per_limb-dstCurrentBitIndexInCurrentLimb);

        NSUInteger srcCurrentLimbIndex = srcRemainingRange.location/mp_bits_per_limb;
        const mp_limb_t* srcCurrentLimbPointer = (srcCurrentLimbIndex < srcLimbsCount) ? src+srcCurrentLimbIndex : 0;
        mp_limb_t srcCurrentLimbValue = !srcCurrentLimbPointer ? 0 : *srcCurrentLimbPointer;
        NSRange srcCurrentLimbBitRange = NSMakeRange(srcCurrentLimbIndex*mp_bits_per_limb, mp_bits_per_limb);
        NSRange srcCurrentLimbUsefulBitRange = NSIntersectionRange(srcCurrentLimbBitRange, srcRemainingRange);
        srcCurrentLimbUsefulBitRange.length = MIN(srcCurrentLimbUsefulBitRange.length, dstCurrentLimbFreeBits);
        NSRange srcCurrentLimbUsefulBitRangeLocal = NSMakeRange(srcCurrentLimbUsefulBitRange.location-srcCurrentLimbBitRange.location, srcCurrentLimbUsefulBitRange.length);
        mp_limb_t srcCurrentValueShiftedMask = (srcCurrentLimbUsefulBitRange.length == mp_bits_per_limb) ? MP_LIMB_MAX : ((MP_LIMB_ONE<<srcCurrentLimbUsefulBitRange.length)-1);
        mp_limb_t srcCurrentValueShifted = ((srcCurrentLimbValue >> srcCurrentLimbUsefulBitRangeLocal.location) & srcCurrentValueShiftedMask);
      
        mp_bitcnt_t bitsToCopy = srcCurrentLimbUsefulBitRangeLocal.length;
        if (dstCurrentLimb)
        {
          mp_limb_t dstMask = (bitsToCopy == mp_bits_per_limb) ? MP_LIMB_MAX :
            ~((MP_LIMB_ONE<<dstCurrentBitIndexInCurrentLimb)-1);
          *dstCurrentLimb &= ~dstMask;
          *dstCurrentLimb |= (srcCurrentValueShifted<<dstCurrentBitIndexInCurrentLimb);
        }//end if (dstCurrentLimb)
        srcRemainingRange.location += bitsToCopy;
        srcRemainingRange.length   -= bitsToCopy;
        dstCurrentBitIndex += bitsToCopy;
        stop |= !srcRemainingRange.length;
      }//end while(remainingBits)
      result = (dstCurrentBitIndex-dstBitIndex);
    }//end if (precRequested <= MPFR_PREC_MAX)
  }//end if (dst && srcBitRange.length)
  return result;
}
//end mpfr_copyBits()

void mpz_reverseBits(mpz_ptr dst, NSRange bitRange)
{
  NSUInteger endBitIndex = mpz_size(dst)*mp_bits_per_limb;
  for(NSUInteger i = bitRange.location ; i<bitRange.location+bitRange.length/2 ; ++i)
  {
    NSUInteger i2 = NSMaxRange(bitRange)-i-1;
    BOOL srcBit = mpz_tstbit(dst, i);
    BOOL dstBit =
      (i2 < endBitIndex) ? mpz_tstbit(dst, i2) :
      (i == 0) ? (mpz_sgn(dst)<0) :
      NO;
    if (i2 >= endBitIndex)
    {
      mpz_abs(dst, dst);
      if (srcBit)
        mpz_neg(dst, dst);
    }//end if (i2 >= endBitIndex)
    else if (!srcBit)
      mpz_clrbit(dst, i2);
    else
      mpz_setbit(dst, i2);
    if (!dstBit)
      mpz_clrbit(dst, i);
    else
      mpz_setbit(dst, i);
  }//end for each bit
}
//end mpz_reverseBits()

BOOL chalkGmpIsPowerOfBase(mpz_srcptr value, int base, NSUInteger* outPower, CHGmpPool* pool)
{
  BOOL result = NO;
  NSUInteger power = 0;
  int sgn = mpz_sgn(value);
  if (sgn != 0)
  {
    if (!mpz_cmp_si(value, 1))
      result = YES;
    else if (mpz_divisible_ui_p(value, (unsigned int)base))
    {
      mpz_t x;
      mpzDepool(x, pool);
      mpz_set(x, value);
      mpz_abs(x, x);
      ++power;
      mpz_divexact_ui(x, x, (unsigned int)base);
      while(mpz_divisible_ui_p(x, (unsigned int)base))
      {
        ++power;
        mpz_divexact_ui(x, x, (unsigned int)base);
      }
      result = !mpz_cmp_si(x, 1);
      mpzRepool(x, pool);
    }//end if (mpz_divisible_ui_p(value, base))
  }//end if (sgn != 0)
  if (outPower)
    *outPower = power;
  return result;
}
//end chalkGmpIsPowerOfBase()
  
NSString* chalkGmpGetCharacterSetAsLowercaseStringForBase(int base)
{
  NSString* result = nil;
  if (base < 2)
    result = nil;
  else if (base<=36)
    result = [@"0123456789abcdefghijklmnopqrstuvwxyz" substringToIndex:base];
  return result;
}
//end chalkGmpGetCharacterSetAsLowercaseStringForBase()

NSString* chalkGmpGetCharacterAsLowercaseStringForBase(int base, NSUInteger value)
{
  NSString* result = nil;
  NSString* characterSet = chalkGmpGetCharacterSetAsLowercaseStringForBase(base);
  result = [characterSet substringWithRange:NSIntersectionRange(NSMakeRange(value, 1), NSMakeRange(0, characterSet.length))];
  return result;
}
//end chalkGmpGetCharacterSetAsLowercaseStringForBase()

NSCharacterSet* chalkGmpGetCharacterSetForBase(int base)
{
  NSCharacterSet* result = nil;
  NSString* characterStringLowercase = chalkGmpGetCharacterSetAsLowercaseStringForBase(base);
  NSString* characterStringUppercase = [characterStringLowercase uppercaseString];
  NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@""];
  [characterSet addCharactersInString:characterStringLowercase];
  [characterSet addCharactersInString:characterStringUppercase];
  result = [[characterSet copy] autorelease];
  return result;
}
//end chalkGmpGetCharacterSetForBase()
  
BOOL chalkGmpMpfrGetStrRaiseInexFlag(void)
{
  static BOOL result = NO;
  static BOOL initialized = NO;
  if (!initialized)
  {
    @synchronized(@"")
    {
      if (!initialized)
      {
        mpfr_t f;
        mpfr_init_set_d(f, 0.125, MPFR_RNDN);
        mpfr_exp_t e = 0;
        mpfr_clear_flags();
        static char buffer[4] = {0};
        mpfr_get_str(buffer, &e, 10, 2, f, MPFR_RNDN);
        result = (mpfr_inexflag_p() != 0);
        mpfr_clear(f);
        initialized = YES;
      }//end if (!initialized)
    }//end @synchronized(@"")
  }//end if (!initialized)
  return result;
}
//end chalkGmpMpfrGetStrRaiseInexFlag()
  
int chalkGmpLog(mpfr_t dst, mpfr_srcptr src, int base, mpfr_rnd_t rnd)
{
  int result = 0;
  if (base == 2)
    result = mpfr_log2(dst, src, rnd);
  else if (base == 10)
    result = mpfr_log10(dst, src, rnd);
  else//if base != 2 and != 10
  {
    mpfi_t rop;
    mpfi_t lnB;
    mpfi_init2(rop, MAX(mpfr_get_prec(src), mpfr_get_prec(dst)));
    mpfi_init2(lnB, MAX(mpfr_get_prec(src), mpfr_get_prec(dst)));
    BOOL exact = YES;
    exact &= MPFI_BOTH_ARE_EXACT(mpfi_set_fr(rop, src));
    exact &= MPFI_BOTH_ARE_EXACT(mpfi_set_si(lnB, base));
    exact &= MPFI_BOTH_ARE_EXACT(mpfi_log(rop, rop));
    exact &= MPFI_BOTH_ARE_EXACT(mpfi_log(lnB, lnB));
    exact &= MPFI_BOTH_ARE_EXACT(mpfi_div(rop, rop, lnB));
    if (rnd == MPFR_RNDN)
    {
      result = mpfi_mid(dst, rop);
      if (exact && !mpfr_equal_p(&rop->left, &rop->right))
        result = 0;
    }//end if (rnd == MPFR_RNDN)
    else if (rnd == MPFR_RNDZ)
    {
      if (mpfi_is_strictly_pos(rop))
      {
        mpfr_swap(dst, &rop->left);
        result = -1;
      }//end if (mpfir_is_strictly_pos(rop))
      else if (mpfi_is_strictly_neg(rop))
      {
        mpfr_swap(dst, &rop->right);
        result = 1;
      }//end if (mpfir_is_strictly_neg(rop))
      else//if (contains 0)
      {
        mpfr_abs(&rop->left, &rop->left, MPFR_RNDU);
        if (mpfr_cmp(&rop->left, &rop->right) >= 0)
        {
          mpfr_swap(dst, &rop->right);
          result = 1;
        }//end if (mpfr_cmp(&rop->left, &rop->right) >= 0)
        else//if (mpfr_cmp(&rop->left, &rop->right) < 0)
        {
          mpfr_swap(dst, &rop->left);
          mpfr_neg(dst, dst, MPFR_RNDN);
          result = -1;
        }//end if (mpfr_cmp(&rop->left, &rop->right) < 0)
      }//end //if (contains 0)
    }//end if (rnd == MPFR_RNDZ)
    else if (rnd == MPFR_RNDU)
    {
      mpfr_swap(dst, &rop->right);
      result = 1;
    }//end if (rnd == MPFR_RNDU)
    else if (rnd == MPFR_RNDD)
    {
      mpfr_swap(dst, &rop->left);
      result = -1;
    }//end if (rnd == MPFR_RNDD)
    else if (rnd == MPFR_RNDA)
    {
      if (mpfi_is_strictly_pos(rop))
      {
        mpfr_swap(dst, &rop->right);
        result = 1;
      }//end if (mpfi_is_strictly_pos(rop))
      else if (mpfi_is_strictly_neg(rop))
      {
        mpfr_swap(dst, &rop->left);
        result = -1;
      }//end if (mpfi_is_strictly_neg(rop))
      else//if (contains 0)
      {
        mpfr_abs(&rop->left, &rop->left, MPFR_RNDU);
        if (mpfr_cmp(&rop->left, &rop->right) <= 0)
        {
          mpfr_swap(dst, &rop->right);
          result = 1;
        }//end if (mpfr_cmp(&rop->left, &rop->right) <= 0)
        else//if (mpfr_cmp(&rop->left, &rop->right) > 0)
        {
          mpfr_swap(dst, &rop->left);
          mpfr_neg(dst, dst, MPFR_RNDN);
          result = -1;
        }//end if (mpfr_cmp(&rop->left, &rop->right) > 0)
      }//end //if (contains 0)
    }//end if (rnd == MPFR_RNDA)
    mpfi_clear(rop);
    mpfi_clear(lnB);
  }//end if ((base != 2) && (base != 10))
  return result;
}
//end chalkGmpLog()
