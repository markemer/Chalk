//
//  CHChalkTypes.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#ifndef __CHCHALKTYPES_H__
#define __CHCHALKTYPES_H__

#include <mpfr.h>

extern NSString* CHChalkPBoardType;

@protocol CHPasteboardDelegate
-(BOOL) pasteDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard;
-(BOOL) copyDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard;
@end


typedef NS_ENUM(NSInteger, chalk_export_format_t) {
  CHALK_EXPORT_FORMAT_UNDEFINED,
  CHALK_EXPORT_FORMAT_SVG,
  CHALK_EXPORT_FORMAT_PDF,
  CHALK_EXPORT_FORMAT_STRING,
  CHALK_EXPORT_FORMAT_PNG,
  CHALK_EXPORT_FORMAT_MATHML,
};
//end chalk_export_format_t

typedef NS_ENUM(NSUInteger, chalk_nextinput_mode_t) {
  CHALK_NEXTINPUT_MODE_UNDEFINED,
  CHALK_NEXTINPUT_MODE_BLANK,
  CHALK_NEXTINPUT_MODE_PREVIOUS_INPUT,
  CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT,
};
//end chalk_nextinput_mode_t

typedef NS_ENUM(NSUInteger, chalk_parse_mode_t) {
  CHALK_PARSE_MODE_UNDEFINED,
  CHALK_PARSE_MODE_INFIX,
  CHALK_PARSE_MODE_RPN,
};
//end chalk_parse_mode_t

typedef NS_ENUM(NSUInteger, chalk_compute_mode_t) {
  CHALK_COMPUTE_MODE_UNDEFINED=0,
  CHALK_COMPUTE_MODE_EXACT=1,
  CHALK_COMPUTE_MODE_APPROX_INTERVALS=2,
  CHALK_COMPUTE_MODE_APPROX_BEST=3,
};
//end chalk_compute_mode_t

typedef NS_OPTIONS(NSUInteger, chalk_value_print_options_t) {
  CHALK_VALUE_PRINT_OPTION_NONE          =    0,
  CHALK_VALUE_PRINT_OPTION_IGNORE_SIGN   = 1<<0,
  CHALK_VALUE_PRINT_OPTION_FORCE_EXACT   = 1<<2,
  CHALK_VALUE_PRINT_OPTION_FORCE_INEXACT = 1<<3,
};
//end chalk_value_print_flags_t

typedef NS_ENUM(NSUInteger, chalk_bool_t) {
  CHALK_BOOL_NO=0,
  CHALK_BOOL_UNLIKELY=1,
  CHALK_BOOL_MAYBE=2,
  CHALK_BOOL_CERTAINLY=3,
  CHALK_BOOL_YES=4
};
//end chalk_bool_t

typedef NS_ENUM(NSUInteger, chalk_value_gmp_type_t) {
  CHALK_VALUE_TYPE_UNDEFINED,
  CHALK_VALUE_TYPE_INTEGER,
  CHALK_VALUE_TYPE_FRACTION,
  CHALK_VALUE_TYPE_REAL_EXACT,
  CHALK_VALUE_TYPE_REAL_APPROX,
};
//end chalk_value_gmp_type_t
  
typedef NS_ENUM(NSUInteger, chalk_value_description_t) {
  CHALK_VALUE_DESCRIPTION_UNDEFINED,
  CHALK_VALUE_DESCRIPTION_STRING,
  CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING,
  CHALK_VALUE_DESCRIPTION_DOT,
  CHALK_VALUE_DESCRIPTION_MATHML,
  CHALK_VALUE_DESCRIPTION_TEX,
  CHALK_VALUE_DESCRIPTION_HTML
};
//end chalk_value_description_t
  
typedef NS_OPTIONS(NSUInteger, chalk_compute_flags_t) {
  CHALK_COMPUTE_FLAG_NONE      =    0,
  CHALK_COMPUTE_FLAG_DIVBYZERO = MPFR_FLAGS_DIVBY0,
  CHALK_COMPUTE_FLAG_ERANGE    = MPFR_FLAGS_ERANGE,
  CHALK_COMPUTE_FLAG_INEXACT   = MPFR_FLAGS_INEXACT,
  CHALK_COMPUTE_FLAG_NAN       = MPFR_FLAGS_NAN,
  CHALK_COMPUTE_FLAG_OVERFLOW  = MPFR_FLAGS_OVERFLOW,
  CHALK_COMPUTE_FLAG_UNDERFLOW = MPFR_FLAGS_UNDERFLOW
};
//end chalk_compute_flags_t

typedef NS_ENUM(NSUInteger, chalk_conversion_error_t) {
  CHALK_CONVERSION_ERROR_NOERROR,
  CHALK_CONVERSION_ERROR_NO_REPRESENTATION,
  CHALK_CONVERSION_ERROR_ALLOCATION,
  CHALK_CONVERSION_ERROR_UNEXPECTED_SIGN,
  CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT,
  CHALK_CONVERSION_ERROR_UNEXPECTED_SIGNIFICAND,
  CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN,
  CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT,
  CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND,
  CHALK_CONVERSION_ERROR_UNSUPPORTED_INFINITY,
  CHALK_CONVERSION_ERROR_UNSUPPORTED_NAN,
  CHALK_CONVERSION_ERROR_OVERFLOW,
};
//end chalk_conversion_error_t

typedef struct {
  chalk_conversion_error_t error;
  chalk_compute_flags_t computeFlags;
} chalk_conversion_result_t;

typedef NS_ENUM(NSUInteger, chalk_number_encoding_type_t) {
  CHALK_NUMBER_ENCODING_UNDEFINED,
  CHALK_NUMBER_ENCODING_GMP_STANDARD,
  CHALK_NUMBER_ENCODING_GMP_CUSTOM,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD,
  CHALK_NUMBER_ENCODING_INTEGER_CUSTOM,
};
//end chalk_number_encoding_type_t

typedef NS_ENUM(NSUInteger, chalk_number_encoding_gmp_standard_variant_t) {
  CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED,
  CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z,
  CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR,
};
//end chalk_number_encoding_gmp_standard_variant_t

typedef NS_ENUM(NSUInteger, chalk_number_encoding_gmp_custom_variant_t) {
  CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED,
  CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z = CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z,
  CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR = CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR,
};
//end chalk_number_encoding_gmp_custom_variant_t

typedef NS_ENUM(NSUInteger, chalk_number_encoding_ieee754_standard_variant_t) {
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_UNDEFINED,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE,
  CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE,
};
//end chalk_number_encoding_ieee754_standard_variant_t

typedef NS_ENUM(NSUInteger, chalk_number_encoding_integer_standard_variant_t) {
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_UNDEFINED,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S,
  CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U,
};
//end chalk_number_encoding_integer_standard_variant_t

typedef NS_ENUM(NSUInteger, chalk_number_encoding_integer_custom_variant_t) {
  CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNDEFINED,
  CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED,
  CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED,
};
//end chalk_number_encoding_integer_custom_variant_t

typedef union {
  chalk_number_encoding_gmp_standard_variant_t     gmpStandardVariantEncoding;
  chalk_number_encoding_gmp_custom_variant_t       gmpCustomVariantEncoding;
  chalk_number_encoding_ieee754_standard_variant_t ieee754StandardVariantEncoding;
  chalk_number_encoding_integer_standard_variant_t integerStandardVariantEncoding;
  chalk_number_encoding_integer_custom_variant_t   integerCustomVariantEncoding;
  NSUInteger genericVariantEncoding;
} chalk_number_encoding_variant_t;

typedef struct {
  chalk_number_encoding_type_t encodingType;
  chalk_number_encoding_variant_t encodingVariant;
} chalk_number_encoding_t;

typedef NS_ENUM(NSUInteger, chalk_number_part_major_t) {
  CHALK_NUMBER_PART_MAJOR_UNDEFINED,
  CHALK_NUMBER_PART_MAJOR_BEST_VALUE,
  CHALK_NUMBER_PART_MAJOR_1,
  CHALK_NUMBER_PART_MAJOR_2,
  CHALK_NUMBER_PART_MAJOR_NUMERATOR   = CHALK_NUMBER_PART_MAJOR_1,
  CHALK_NUMBER_PART_MAJOR_DENOMINATOR = CHALK_NUMBER_PART_MAJOR_2,
  CHALK_NUMBER_PART_MAJOR_LOWER_BOUND = CHALK_NUMBER_PART_MAJOR_1,
  CHALK_NUMBER_PART_MAJOR_UPPER_BOUND = CHALK_NUMBER_PART_MAJOR_2,
};
//end chalk_number_part_major_t

typedef NS_OPTIONS(NSUInteger, chalk_number_part_minor_type_t) {
  CHALK_NUMBER_PART_MINOR_UNDEFINED   = 0,
  CHALK_NUMBER_PART_MINOR_SIGN        = 1<<0,
  CHALK_NUMBER_PART_MINOR_EXPONENT    = 1<<1,
  CHALK_NUMBER_PART_MINOR_SIGNIFICAND = 1<<2,
};
//end chalk_number_part_minor_type_t

typedef NS_ENUM(NSUInteger, chalk_bitInterpretation_action_t) {
  CHALK_BITINTERPRETATION_ACTION_UNDEFINED,
  CHALK_BITINTERPRETATION_ACTION_CONVERT,
  CHALK_BITINTERPRETATION_ACTION_INTERPRET,
};
//end chalk_bitInterpretation_action_t

typedef NS_OPTIONS(NSUInteger, chalk_raw_value_flags_t) {
  CHALK_RAW_VALUE_FLAG_NONE = 0,
  CHALK_RAW_VALUE_FLAG_POSITIVE = 1<<0,
  CHALK_RAW_VALUE_FLAG_NEGATIVE = 1<<1,
  CHALK_RAW_VALUE_FLAG_INFINITY = 1<<2,
  CHALK_RAW_VALUE_FLAG_NAN = 1<<3,
};
//end chalk_raw_value_flags_t

#endif
