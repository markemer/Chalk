//
//  CHChalkUtils.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#ifndef __CHCHALKUTILS_H__
#define __CHCHALKUTILS_H__

#include "CHChalkTypes.h"

#include "chalk-parser.h"
#include <gmp.h>
#include <mpfr.h>
#include <mpfi.h>
#include <arb.h>
#include "mpfir.h"

@class CHChalkContext;
@class CHGmpPool;

#ifdef __cplusplus
extern "C" {
#endif

extern NSString* CHPasteboardTypeConstantDescriptions;

extern const NSInteger GMP_BASE_MIN;
extern const NSInteger GMP_BASE_MAX;
extern NSString* NSSTRING_PI;
extern NSString* NSSTRING_INFINITY;
extern NSString* NSSTRING_ELLIPSIS;
extern NSString* NSSTRING_PLUSMINUS;
extern NSString* NSSTRING_UNBREAKABLE_SPACE;

typedef NS_ENUM(NSUInteger, chalk_operator_t) {
  CHALK_OPERATOR_UNDEFINED,
  CHALK_OPERATOR_PLUS = CHALK_LEMON_OPERATOR_PLUS,
  CHALK_OPERATOR_PLUS2 = CHALK_LEMON_OPERATOR_PLUS2,
  CHALK_OPERATOR_MINUS = CHALK_LEMON_OPERATOR_MINUS,
  CHALK_OPERATOR_MINUS2 = CHALK_LEMON_OPERATOR_MINUS2,
  CHALK_OPERATOR_TIMES = CHALK_LEMON_OPERATOR_TIMES,
  CHALK_OPERATOR_TIMES2 = CHALK_LEMON_OPERATOR_TIMES2,
  CHALK_OPERATOR_DIVIDE = CHALK_LEMON_OPERATOR_DIVIDE,
  CHALK_OPERATOR_DIVIDE2 = CHALK_LEMON_OPERATOR_DIVIDE2,
  CHALK_OPERATOR_POW = CHALK_LEMON_OPERATOR_POW,
  CHALK_OPERATOR_POW2 = CHALK_LEMON_OPERATOR_POW2,
  CHALK_OPERATOR_SQRT = CHALK_LEMON_OPERATOR_SQRT,
  CHALK_OPERATOR_SQRT2 = CHALK_LEMON_OPERATOR_SQRT2,
  CHALK_OPERATOR_CBRT = CHALK_LEMON_OPERATOR_CBRT,
  CHALK_OPERATOR_CBRT2 = CHALK_LEMON_OPERATOR_CBRT2,
  CHALK_OPERATOR_MUL_SQRT = CHALK_LEMON_OPERATOR_MUL_SQRT,
  CHALK_OPERATOR_MUL_SQRT2 = CHALK_LEMON_OPERATOR_MUL_SQRT2,
  CHALK_OPERATOR_MUL_CBRT = CHALK_LEMON_OPERATOR_MUL_CBRT,
  CHALK_OPERATOR_MUL_CBRT2 = CHALK_LEMON_OPERATOR_MUL_CBRT2,
  CHALK_OPERATOR_DEGREE = CHALK_LEMON_OPERATOR_DEGREE,
  CHALK_OPERATOR_DEGREE2 = CHALK_LEMON_OPERATOR_DEGREE2,
  CHALK_OPERATOR_FACTORIAL = CHALK_LEMON_OPERATOR_FACTORIAL,
  CHALK_OPERATOR_FACTORIAL2 = CHALK_LEMON_OPERATOR_FACTORIAL2,
  CHALK_OPERATOR_UNCERTAINTY = CHALK_LEMON_OPERATOR_UNCERTAINTY,
  CHALK_OPERATOR_ABS = CHALK_LEMON_OPERATOR_ABS,
  CHALK_OPERATOR_NOT = CHALK_LEMON_OPERATOR_NOT,
  CHALK_OPERATOR_NOT2 = CHALK_LEMON_OPERATOR_NOT2,
  CHALK_OPERATOR_LEQ = CHALK_LEMON_OPERATOR_LEQ,
  CHALK_OPERATOR_LEQ2 = CHALK_LEMON_OPERATOR_LEQ2,
  CHALK_OPERATOR_GEQ = CHALK_LEMON_OPERATOR_GEQ,
  CHALK_OPERATOR_GEQ2 = CHALK_LEMON_OPERATOR_GEQ2,
  CHALK_OPERATOR_LOW = CHALK_LEMON_OPERATOR_LOW,
  CHALK_OPERATOR_LOW2 = CHALK_LEMON_OPERATOR_LOW2,
  CHALK_OPERATOR_GRE = CHALK_LEMON_OPERATOR_GRE,
  CHALK_OPERATOR_GRE2 = CHALK_LEMON_OPERATOR_GRE2,
  CHALK_OPERATOR_NEQ = CHALK_LEMON_OPERATOR_NEQ,
  CHALK_OPERATOR_NEQ2 = CHALK_LEMON_OPERATOR_NEQ2,
  CHALK_OPERATOR_EQU = CHALK_LEMON_OPERATOR_EQU,
  CHALK_OPERATOR_EQU2 = CHALK_LEMON_OPERATOR_EQU2,
  CHALK_OPERATOR_AND = CHALK_LEMON_OPERATOR_AND,
  CHALK_OPERATOR_AND2 = CHALK_LEMON_OPERATOR_AND2,
  CHALK_OPERATOR_OR = CHALK_LEMON_OPERATOR_OR,
  CHALK_OPERATOR_OR2 = CHALK_LEMON_OPERATOR_OR2,
  CHALK_OPERATOR_XOR = CHALK_LEMON_OPERATOR_XOR,
  CHALK_OPERATOR_XOR2 = CHALK_LEMON_OPERATOR_XOR2,
  CHALK_OPERATOR_SHL = CHALK_LEMON_OPERATOR_SHL,
  CHALK_OPERATOR_SHL2 = CHALK_LEMON_OPERATOR_SHL2,
  CHALK_OPERATOR_SHR = CHALK_LEMON_OPERATOR_SHR,
  CHALK_OPERATOR_SHR2 = CHALK_LEMON_OPERATOR_SHR2,
  CHALK_OPERATOR_SUBSCRIPT = CHALK_LEMON_OPERATOR_SUBSCRIPT
};
//end chalk_operator_t

typedef NS_OPTIONS(NSUInteger, chalk_operator_position_t) {
  CHALK_OPERATOR_POSITION_NONE    =    0,
  CHALK_OPERATOR_POSITION_INFIX   = 1<<0,
  CHALK_OPERATOR_POSITION_PREFIX  = 1<<1,
  CHALK_OPERATOR_POSITION_POSTFIX = 1<<2
};
//end chalk_operator_position_t

typedef struct {
  chalk_value_gmp_type_t type;
  mpz_t integer;
  mpq_t fraction;
  mpfr_t realExact;
  mpfir_t realApprox;
} chalk_gmp_value_t;

typedef struct {
  chalk_number_part_major_t major;
  chalk_number_encoding_t   numberEncoding;
  mp_bitcnt_t               signCustomBitsCount;
  mp_bitcnt_t               exponentCustomBitsCount;
  mp_bitcnt_t               significandCustomBitsCount;
} chalk_bit_interpretation_t;

typedef struct {
  mpz_t bits;
  chalk_bit_interpretation_t bitInterpretation;
  chalk_raw_value_flags_t flags;
} chalk_raw_value_t;

void mpn_print2(const mp_limb_t* limbs, size_t count);

BOOL isPowerOfTwo(NSUInteger x);
NSUInteger nextPowerOfTwo(NSUInteger x, BOOL strict);
NSUInteger prevPowerOfTwo(NSUInteger x, BOOL strict);
NSUInteger getPowerOfTwo(NSUInteger x);

int mpn_zero_range_p(const mp_limb_t* limbs, size_t limbsCount, NSRange bitsRange);
void mpn_set_zero(mp_limb_t* limbs, size_t limbsCount);
mp_bitcnt_t mpn_rscan1(const mp_limb_t* limbs, size_t limbsCount);
mp_bitcnt_t mpn_rscan1_range(const mp_limb_t* limbs, size_t limbsCount, NSRange bitsRange);

void mpz_set_zero_raw(mpz_ptr value);

void mpz_init_set_nsui(mpz_t rop, const NSUInteger op);
void mpz_init_set_nssi(mpz_t rop, const NSInteger op);
void mpz_init_set_nsdecimal(mpz_t rop, const NSDecimal* op);
void mpz_set_nsui(mpz_t rop, const NSUInteger op);
void mpz_set_nssi(mpz_t rop, const NSInteger op);
void mpz_set_nsdecimal(mpz_t rop, const NSDecimal* op);

NSUInteger mpz_get_nsui(mpz_srcptr op);
NSInteger  mpz_get_nssi(mpz_srcptr op);
NSDecimal  mpz_get_nsdecimal(mpz_srcptr op);

int mpz_fits_nsui_p(mpz_srcptr op);
int mpz_fits_nssi_p(mpz_srcptr op);
int mpz_fits_nsdecimal_p(mpz_srcptr op);

void mpz_negbit(mpz_ptr rop, mp_bitcnt_t index);
void mpz_changeBit(mpz_ptr rop, mp_bitcnt_t index, BOOL value);
void mpz_complement1(mpz_ptr op, NSRange bitsRange);
int mpz_complement2(mpz_ptr rop, NSRange bitRange);

void mpz_min_exponent(mpz_ptr rop, mpz_srcptr exponent, int fromBase, int toBase, CHGmpPool* pool);

mp_bitcnt_t mpz_get_msb_zero_count(mpz_srcptr op, NSRange bitsRange);
mp_bitcnt_t mpz_get_lsb_zero_count(mpz_srcptr op, NSRange bitsRange);
void mpz_set_zero(mpz_ptr op, NSRange bitsRange);
void mpz_set_one(mpz_ptr op, NSRange bitsRange);
void mpz_shift_left(mpz_ptr op, mp_bitcnt_t shiftValue, NSRange bitsRange);
void mpz_shift_right(mpz_ptr op, mp_bitcnt_t shiftValue, NSRange bitsRange);
void mpz_roll_left(mpz_ptr op, mp_bitcnt_t rollValue, NSRange bitsRange);
void mpz_roll_right(mpz_ptr op, mp_bitcnt_t rollValue, NSRange bitsRange);
void mpz_swap_packets_pairs(mpz_ptr op, mp_bitcnt_t packetBitSize, NSRange bitsRange);
void mpz_add_one(mpz_ptr op, NSRange bitsRange);
void mpz_sub_one(mpz_ptr op, NSRange bitsRange);

mp_bitcnt_t mpn_copyBits(mp_limb_t* dst, size_t dstLimbsCount, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError);
mp_bitcnt_t mpz_copyBits(mpz_ptr dst, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError);
mp_bitcnt_t mpfr_copyBits(mpfr_ptr dst, mp_bitcnt_t dstBitIndex, const mp_limb_t* src, size_t srcLimbsCount, NSRange srcBitRange, BOOL* outError);

void mpz_reverseBits(mpz_ptr dst, NSRange bitRange);

int mpf_is_infinity(mpf_srcptr op);
  
int mpfr_init_set_nsui(mpfr_t rop, const NSUInteger op, mpfr_rnd_t rnd);
int mpfr_init_set_nssi(mpfr_t rop, const NSInteger op, mpfr_rnd_t rnd);
int mpfr_set_nsui(mpfr_t rop, const NSUInteger op, mpfr_rnd_t rnd);
int mpfr_set_nssi(mpfr_t rop, const NSInteger op, mpfr_rnd_t rnd);
NSUInteger mpfr_get_nsui(mpfr_srcptr op, mpfr_rnd_t rnd);
NSInteger mpfr_get_nssi(mpfr_srcptr op, mpfr_rnd_t rnd);
int mpfr_fits_z(mpfr_srcptr op, mp_bitcnt_t bitcount);
BOOL mpfr_set_inf_optimized(mpfr_t rop, int sgn);

int mpfi_pow_z(mpfi_ptr rop, mpfi_srcptr op1, mpz_srcptr op2);
int mpfir_pow_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2);
int mpfi_pow(mpfi_ptr rop, mpfi_srcptr op1, mpfi_srcptr op2);
int mpfir_pow(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2);

int mpz_fits_exponent_p(mpz_srcptr op, int base, CHGmpPool* pool);

id plistFromBitNumberEncoding(chalk_number_encoding_t numberEncoding);
chalk_number_encoding_t plistToNumberEncoding(id plist);

mp_bitcnt_t mpz_scan1_r(mpz_srcptr op, mp_bitcnt_t starting_bit);
void mpzCopy(mpz_ptr dst, __mpz_struct src);
void mpqCopy(mpq_ptr dst, __mpq_struct src);
void mpfrCopy(mpfr_ptr dst, __mpfr_struct src);
void mpfiCopy(mpfi_ptr dst, __mpfi_struct src);
void mpfirCopy(mpfir_ptr dst, __mpfir_struct src);
void mpzDepool(mpz_ptr dst, CHGmpPool* pool);
void mpqDepool(mpq_ptr dst, CHGmpPool* pool);
void mpfrDepool(mpfr_ptr dst, mpfr_prec_t prec, CHGmpPool* pool);
void mpfiDepool(mpfi_ptr dst, mpfr_prec_t prec, CHGmpPool* pool);
void mpfirDepool(mpfir_ptr dst, mpfr_prec_t prec, CHGmpPool* pool);
void arbDepool(arb_ptr dst, CHGmpPool* pool);
void mpzRepool(mpz_ptr dst, CHGmpPool* pool);
void mpqRepool(mpq_ptr dst, CHGmpPool* pool);
void mpfrRepool(mpfr_ptr dst, CHGmpPool* pool);
void mpfiRepool(mpfi_ptr dst, CHGmpPool* pool);
void mpfirRepool(mpfir_ptr dst, CHGmpPool* pool);
void arbRepool(arb_ptr dst, CHGmpPool* pool);

BOOL chalkBoolIsCertain(chalk_bool_t value);
chalk_bool_t chalkBoolNot(chalk_bool_t value);
chalk_bool_t chalkBoolAnd(chalk_bool_t op1, chalk_bool_t op2);
chalk_bool_t chalkBoolOr(chalk_bool_t op1, chalk_bool_t op2);
chalk_bool_t chalkBoolXor(chalk_bool_t op1, chalk_bool_t op2);
chalk_bool_t chalkBoolCombine(chalk_bool_t op1, chalk_bool_t op2);

BOOL chalkDigitsMatchBase(NSString* digits, NSRange range, int base, BOOL allowSpace, NSIndexSet** outFailures);
BOOL chalkGmpBaseIsValid(int base);
int  chalkGmpBaseMakeValid(int base);
BOOL chalkGmpBaseIsValidPrefix(NSString* digits);
BOOL chalkGmpBaseIsValidSuffix(NSString* digits);

chalk_compute_flags_t chalkGmpFlagsMake(void);
chalk_compute_flags_t chalkGmpFlagsAdd(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToAdd);
chalk_compute_flags_t chalkGmpFlagsRemove(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToRemove);
BOOL chalkGmpFlagsTest(chalk_compute_flags_t flags, chalk_compute_flags_t flagsToTest);
chalk_compute_flags_t chalkGmpFlagsSave(BOOL reset);
void chalkGmpFlagsRestore(chalk_compute_flags_t flags);
NSString* chalkGmpComputeFlagsGetHTML(chalk_compute_flags_t flags, const chalk_bit_interpretation_t* bitInterpretation, BOOL withTooltips);
BOOL chalkGmpValueClear(chalk_gmp_value_t* value, BOOL releaseResources, CHGmpPool* pool);
BOOL chalkGmpValueSet(chalk_gmp_value_t* dst, const chalk_gmp_value_t* src, CHGmpPool* pool);
BOOL chalkGmpValueSetZero(chalk_gmp_value_t* dst, BOOL keepType, CHGmpPool* pool);
BOOL chalkGmpValueSetNan(chalk_gmp_value_t* dst, BOOL raiseFlag, CHGmpPool* pool);
BOOL chalkGmpValueSetInfinity(chalk_gmp_value_t* dst, int sgn, BOOL raiseFlag, CHGmpPool* pool);
BOOL chalkGmpValueSwap(chalk_gmp_value_t* op1, chalk_gmp_value_t* op2);
BOOL chalkGmpValueGetOneDigitUpRounding(mpfr_srcptr x, int  base, char* outChar, mpfr_exp_t* outExp);
BOOL chalkGmpValueMove(chalk_gmp_value_t* dst, chalk_gmp_value_t* src, CHGmpPool* pool);
BOOL chalkGmpValueAbs(chalk_gmp_value_t* value, CHGmpPool* pool);
int  chalkGmpValueCmp(const chalk_gmp_value_t* op1, const chalk_gmp_value_t* op2, CHGmpPool* pool);
BOOL chalkGmpValueIsZero(const chalk_gmp_value_t* value, chalk_compute_flags_t flags);
BOOL chalkGmpValueIsOne(const chalk_gmp_value_t* value, BOOL* isOneIgnoringSign, chalk_compute_flags_t flags);
BOOL chalkGmpValueIsNan(const chalk_gmp_value_t* value);
int  chalkGmpValueSign(const chalk_gmp_value_t* value);
BOOL chalkGmpValueNeg(chalk_gmp_value_t* value);
BOOL chalkGmpValueInvert(chalk_gmp_value_t* value, CHGmpPool* pool);
BOOL chalkGmpValueCanSimplify(const chalk_gmp_value_t* value, mp_bitcnt_t maxIntegerBits, CHGmpPool* pool);
BOOL chalkGmpValueSimplify(chalk_gmp_value_t* value, mp_bitcnt_t maxIntegerBits, CHGmpPool* pool);
BOOL chalkGmpValueMake(chalk_gmp_value_t* value, chalk_value_gmp_type_t type, mpfr_prec_t prec, CHGmpPool* pool);
BOOL chalkGmpValueMakeInteger(chalk_gmp_value_t* value, CHGmpPool* pool);
BOOL chalkGmpValueMakeFraction(chalk_gmp_value_t* value, CHGmpPool* pool);
BOOL chalkGmpValueMakeReal(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool);
BOOL chalkGmpValueMakeRealExact(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool);
BOOL chalkGmpValueMakeRealApprox(chalk_gmp_value_t* value, mpfr_prec_t precision, CHGmpPool* pool);
CGFloat chalkGmpValueGetCGFloat(const chalk_gmp_value_t* value);
NSUInteger chalkGmpGetMinRoundingDigitsCount(void);
mpfr_prec_t chalkGmpGetRequiredBitsCountForDigitsCount(NSUInteger nbDigits, int base);
mpfr_prec_t chalkGmpGetRequiredBitsCountForDigitsCountZ(mpz_srcptr nbDigits, int base);
NSUInteger chalkGmpGetMaximumDigitsCountFromBitsCount(NSUInteger nbBits, int base);
NSUInteger chalkGmpGetMaximumExactDigitsCountFromBitsCount(NSUInteger nbBits, int base);
NSUInteger chalkGmpGetSignificandDigitsCount(mpfr_srcptr f, int base);
NSUInteger chalkGmpMaxDigitsInBase(NSUInteger countBase1, int base1, int base2, CHGmpPool* pool);
NSUInteger chalkGmpGetEquivalentBasePower(int base1, NSUInteger power1, int base2);
BOOL chalkGmpIsPowerOfBase(mpz_srcptr value, int base, NSUInteger* outPower, CHGmpPool* pool);
NSString* chalkGmpGetCharacterAsLowercaseStringForBase(int base, NSUInteger value);
NSString* chalkGmpGetCharacterSetAsLowercaseStringForBase(int base);
NSCharacterSet* chalkGmpGetCharacterSetForBase(int base);
BOOL chalkGmpMpfrGetStrRaiseInexFlag(void);
int chalkGmpLog(mpfr_t dst, mpfr_srcptr src, int base, mpfr_rnd_t rnd);

id plistFromBitInterpretation(chalk_bit_interpretation_t bitInterpretation);
chalk_bit_interpretation_t plistToBitInterpretation(id plist);

id plistFromRawValue(chalk_raw_value_t rawValue);
chalk_raw_value_t plistToRawValue(id plist);

BOOL chalkRawValueCreate(chalk_raw_value_t* value, CHGmpPool* pool);
BOOL chalkRawValueClear(chalk_raw_value_t* value, BOOL releaseResources, CHGmpPool* pool);
BOOL chalkRawValueSet(chalk_raw_value_t* dst, const chalk_raw_value_t* src, CHGmpPool* pool);
BOOL chalkRawValueMove(chalk_raw_value_t* dst, chalk_raw_value_t* src, CHGmpPool* pool);
BOOL chalkRawValueSetZero(chalk_raw_value_t* dst, CHGmpPool* pool);
BOOL chalkRawValueReverseBits(chalk_raw_value_t* dst, NSRange bitsRange);

BOOL getEncodingIsStandard(chalk_number_encoding_t encoding);
BOOL getEncodingIsInteger(chalk_number_encoding_t encoding);
BOOL getEncodingIsUnsignedInteger(chalk_number_encoding_t encoding);
BOOL getEncodingIsSignedInteger(chalk_number_encoding_t encoding);

NSUInteger getMinorPartOrderedCountForEncoding(chalk_number_encoding_t encoding);
chalk_number_part_minor_type_t getMinorPartOrderedForEncoding(chalk_number_encoding_t encoding, NSUInteger index);

NSUInteger getMinorPartBitsCountForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorPart);
NSUInteger getMultipleMinorPartsBitsCountForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorParts);
NSUInteger getTotalBitsCountForEncoding(chalk_number_encoding_t encoding);
NSUInteger getSignBitsCountForEncoding(chalk_number_encoding_t encoding);
NSUInteger getExponentBitsCountForEncoding(chalk_number_encoding_t encoding);
NSUInteger getSignificandBitsCountForEncoding(chalk_number_encoding_t encoding, BOOL addImplicitBits);

NSRange getMinorPartBitsRangeForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorPart);
NSRange getMultipleMinorPartsBitsRangeForEncoding(chalk_number_encoding_t encoding, chalk_number_part_minor_type_t minorParts);
NSRange getTotalBitsRangeForEncoding(chalk_number_encoding_t encoding);
NSRange getSignBitsRangeForEncoding(chalk_number_encoding_t encoding);
NSRange getExponentBitsRangeForEncoding(chalk_number_encoding_t encoding);
NSRange getSignificandBitsRangeForEncoding(chalk_number_encoding_t encoding, BOOL addImplicitBits);

NSUInteger getMinorPartOrderedCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
chalk_number_part_minor_type_t getMinorPartOrderedForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, NSUInteger index);

NSUInteger getMinorPartBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSUInteger getMultipleMinorPartsBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSUInteger getTotalBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSUInteger getSignBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSUInteger getExponentBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSUInteger getSignificandBitsCountForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, BOOL addImplicitBits);

NSRange getMinorPartBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSRange getMultipleMinorPartsBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSRange getTotalBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSRange getExponentBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignificandBitsRangeForBitInterpretation(const chalk_bit_interpretation_t* bitInterpretation, BOOL addImplicitBits);

NSRange getMinorPartBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSRange getMinorPartBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSRange getMinorPartBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSRange getMinorPartBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);
NSRange getMinorPartBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorPart);

NSRange getMultipleMinorPartsBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSRange getMultipleMinorPartsBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSRange getMultipleMinorPartsBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSRange getMultipleMinorPartsBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);
NSRange getMultipleMinorPartsBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation, chalk_number_part_minor_type_t minorParts);

NSRange getTotalBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getTotalBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getTotalBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getTotalBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getTotalBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);

NSRange getSignBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);

NSRange getExponentBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getExponentBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getExponentBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getExponentBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getExponentBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);

NSRange getSignificandBitsRangeForValue(const chalk_gmp_value_t* value, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignificandBitsRangeForValueZ(mpz_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignificandBitsRangeForValueQ(mpq_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignificandBitsRangeForValueFR(mpfr_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);
NSRange getSignificandBitsRangeForValueFIR(mpfir_srcptr value, const chalk_bit_interpretation_t* bitInterpretation);

chalk_number_part_minor_type_t getMinorPartForBit(NSUInteger bitIndex, const chalk_bit_interpretation_t* bitInterpretation);

BOOL bitInterpretationEquals(const chalk_bit_interpretation_t* op1, const chalk_bit_interpretation_t* op2);

chalk_conversion_result_t convertFromValueToRaw(chalk_raw_value_t* dst, const chalk_gmp_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromValueToRawZ(chalk_raw_value_t* dst, mpz_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromValueToRawQ(chalk_raw_value_t* dst, mpq_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromValueToRawFR(chalk_raw_value_t* dst, mpfr_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromValueToRawFIR(chalk_raw_value_t* dst, mpfir_srcptr src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);

chalk_conversion_result_t convertFromRawToValue(chalk_gmp_value_t* value, const chalk_raw_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromRawToValueZ(mpz_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromRawToValueQ(mpq_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromRawToValueFR(mpfr_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t convertFromRawToValueFIR(mpfir_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);

chalk_conversion_result_t interpretFromRawToValue(chalk_gmp_value_t* value, const chalk_raw_value_t* src, chalk_compute_mode_t computeMode, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t interpretFromRawToValueZ(mpz_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t interpretFromRawToValueQ(mpq_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t interpretFromRawToValueFR(mpfr_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);
chalk_conversion_result_t interpretFromRawToValueFIR(mpfir_ptr dst, const chalk_raw_value_t* src, const chalk_bit_interpretation_t* dstBitInterpretation, CHChalkContext* chalkContext);

#ifdef __cplusplus
}//end extern "C"
#endif


#endif
