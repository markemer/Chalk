//
//  CHChalkValueNumberGmp.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueMovable.h"
#import "CHChalkValueNumber.h"

@class CHChalkContext;

@interface CHChalkValueNumberGmp : CHChalkValueNumber <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  chalk_gmp_value_t value;
  BOOL isValueWapperOnly;
}

@property(nonatomic,readonly) chalk_value_gmp_type_t valueType;
@property(nonatomic,readonly) const chalk_gmp_value_t* valueConstReference;
@property(nonatomic,readonly) chalk_gmp_value_t* valueReference;

-(instancetype) initWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token integer:(NSInteger)integer naturalBase:(int)naturalBase context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token uinteger:(NSUInteger)uinteger naturalBase:(int)naturalBase context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token cgfloat:(CGFloat)cgfloat naturalBase:(int)naturalBase context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token value:(chalk_gmp_value_t*)value naturalBase:(int)naturalBase context:(CHChalkContext*)context;
-(instancetype) initWithIntegerTypeToken:(CHChalkToken*)token base:(int)base context:(CHChalkContext*)context;
-(instancetype) initWithRealTypeToken:(CHChalkToken*)token base:(int)base precision:(mpfr_prec_t)precision context:(CHChalkContext*)context;

-(void) setValueReference:(chalk_gmp_value_t*)newValue clearPrevious:(BOOL)clearPrevious isValueWapperOnly:(BOOL)aIsValueWapperOnly;

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

+(CHChalkValueNumberGmp*) infinityWithContext:(CHChalkContext*)context;
+(CHChalkValueNumberGmp*) nanWithContext:(CHChalkContext*)context;

+(BOOL) checkInteger:(mpz_srcptr)op token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context;
+(BOOL) checkInteger:(mpz_srcptr)op maxBitsCount:(NSUInteger)maxBitsCount token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context;
+(BOOL) checkFraction:(mpq_srcptr)op token:(CHChalkToken*)token setError:(BOOL)setError context:(CHChalkContext*)context;

+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(const chalk_gmp_value_t*)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeMpzToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpz_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeMpqToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpq_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeMpfrToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfr_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeMpfiToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfi_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeMpfirToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context value:(mpfir_srcptr)value token:(CHChalkToken*)token presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
