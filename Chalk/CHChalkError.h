//
//  CHChalkError.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

extern NSString* CHChalkErrorDomainChalk;
extern NSString* CHChalkErrorDomainNumeric;
extern NSString* CHChalkErrorDomainGmp;
extern NSString* CHChalkErrorDomainDataAccess;
extern NSString* CHChalkErrorNoError;
extern NSString* CHChalkErrorUnknown;
extern NSString* CHChalkErrorParseError;
extern NSString* CHChalkErrorUnimplemented;
extern NSString* CHChalkErrorAllocation;
extern NSString* CHChalkErrorIdentifierUndefined;
extern NSString* CHChalkErrorIdentifierFunctionUndefined;
extern NSString* CHChalkErrorIdentifierReserved;
extern NSString* CHChalkErrorIntegerOverflow;
extern NSString* CHChalkErrorOperatorUnknown;
extern NSString* CHChalkErrorOperatorArgumentsError;
extern NSString* CHChalkErrorOperatorArgumentsCountError;
extern NSString* CHChalkErrorOperatorOperationNonImplemented;
extern NSString* CHChalkErrorMatrixMalformed;
extern NSString* CHChalkErrorMatrixNotInvertible;
extern NSString* CHChalkErrorDimensionsMismatch;
extern NSString* CHChalkErrorNumericInvalid;
extern NSString* CHChalkErrorNumericDivideByZero;
extern NSString* CHChalkErrorGmpUnsupported;
extern NSString* CHChalkErrorGmpOverflow;
extern NSString* CHChalkErrorGmpUnderflow;
extern NSString* CHChalkErrorGmpPrecisionOverflow;
extern NSString* CHChalkErrorGmpValueCannotInit;
extern NSString* CHChalkErrorGmpBaseInvalid;
extern NSString* CHChalkErrorBaseDecorationAmbiguity;
extern NSString* CHChalkErrorBaseDecorationConflict;
extern NSString* CHChalkErrorBaseDecorationInvalid;
extern NSString* CHChalkErrorBaseDigitsInvalid;
extern NSString* CHChalkErrorDataOpen;
extern NSString* CHChalkErrorDataRead;
extern NSString* CHChalkErrorDataWrite;
extern NSString* CHChalkErrorConversionNoRepresentation;
extern NSString* CHChalkErrorConversionUnexpectedSign;
extern NSString* CHChalkErrorConversionUnexpectedExponent;
extern NSString* CHChalkErrorConversionUnexpectedSignificand;
extern NSString* CHChalkErrorConversionUnsupportedSign;
extern NSString* CHChalkErrorConversionUnsupportedExponent;
extern NSString* CHChalkErrorConversionUnsupportedSignificand;
extern NSString* CHChalkErrorConversionUnsupportedInfinity;
extern NSString* CHChalkErrorConversionUnsupportedNan;
extern NSString* CHChalkErrorConversionOverflow;
extern NSString* CHChalkErrorUserCancellation;

@interface CHChalkError : NSError <NSCoding, NSCopying, NSSecureCoding> {
  NSString*          reason;
  NSMutableIndexSet* ranges;
  id                 contextGenerator;
  id                 reasonExtraInformation;
}

@property(nonatomic,readonly,copy)   NSString*     reason;
@property(nonatomic,readonly,copy)   NSIndexSet*   ranges;
@property(nonatomic,readonly,retain) id            contextGenerator;
@property(nonatomic,copy)            id<NSCopying> reasonExtraInformation;

+(NSString*) convertFromConversionError:(chalk_conversion_error_t)conversionError;

+(instancetype) chalkError;
+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason;
+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason range:(NSRange)range;
+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason ranges:(NSIndexSet*)ranges;
-(instancetype) init;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason range:(NSRange)range;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason ranges:(NSIndexSet*)ranges;

-(void) setContextGenerator:(id)value replace:(BOOL)replace;
-(void) addRange:(NSRange)range;
-(void) removeRange:(NSRange)range;

-(NSString*) friendlyDescription;
-(NSString*) description;

@end
