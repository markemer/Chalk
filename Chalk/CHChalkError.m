//
//  CHChalkError.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkError.h"

#import "CHChalkUtils.h"
#import "CHUtils.h"

#import "NSCoderExtended.h"

NSString* CHChalkErrorDomainChalk = @"CHChalkErrorDomainChalk";
NSString* CHChalkErrorDomainNumeric = @"CHChalkErrorDomainNumeric";
NSString* CHChalkErrorDomainGmp = @"CHChalkErrorDomainGmp";
NSString* CHChalkErrorDomainDataAccess = @"CHChalkErrorDomainDataAccess";

NSString* CHChalkErrorNoError = @"CHChalkErrorNoError";
NSString* CHChalkErrorUnknown = @"CHChalkErrorUnknown";
NSString* CHChalkErrorParseError = @"CHChalkErrorParseError";
NSString* CHChalkErrorUnimplemented = @"CHChalkErrorUnimplemented";
NSString* CHChalkErrorAllocation = @"CHChalkErrorAllocation";
NSString* CHChalkErrorIdentifierUndefined = @"CHChalkErrorIdentifierUndefined";
NSString* CHChalkErrorIdentifierFunctionUndefined = @"CHChalkErrorIdentifierFunctionUndefined";
NSString* CHChalkErrorIdentifierReserved = @"CHChalkErrorIdentifierReserved";
NSString* CHChalkErrorIntegerOverflow = @"CHChalkErrorIntegerOverflow";
NSString* CHChalkErrorOperatorUnknown = @"CHChalkErrorOperatorUnknown";
NSString* CHChalkErrorOperatorArgumentsError = @"CHChalkErrorOperatorArgumentsError";
NSString* CHChalkErrorOperatorArgumentsCountError = @"CHChalkErrorOperatorArgumentsCountError";
NSString* CHChalkErrorOperatorOperationNonImplemented = @"CHChalkErrorOperatorOperationNonImplemented";
NSString* CHChalkErrorMatrixMalformed = @"CHChalkErrorMatrixMalformed";
NSString* CHChalkErrorMatrixNotInvertible = @"CHChalkErrorMatrixNotInvertible";
NSString* CHChalkErrorDimensionsMismatch = @"CHChalkErrorDimensionsMismatch";
NSString* CHChalkErrorNumericInvalid = @"CHChalkErrorNumericInvalid";
NSString* CHChalkErrorNumericDivideByZero = @"CHChalkErrorNumericDivideByZero";
NSString* CHChalkErrorGmpUnsupported = @"CHChalkErrorGmpUnsupported";
NSString* CHChalkErrorGmpOverflow = @"CHChalkErrorGmpOverflow";
NSString* CHChalkErrorGmpUnderflow = @"CHChalkErrorGmpUnderflow";
NSString* CHChalkErrorGmpValueCannotInit = @"CHChalkErrorGmpValueCannotInit";
NSString* CHChalkErrorGmpPrecisionOverflow = @"CHChalkErrorGmpPrecisionOverflow";
NSString* CHChalkErrorGmpBaseInvalid = @"CHChalkErrorGmpBaseInvalid";

NSString* CHChalkErrorBaseDecorationAmbiguity = @"CHChalkErrorBaseDecorationAmbiguity";
NSString* CHChalkErrorBaseDecorationConflict = @"CHChalkErrorBaseDecorationConflict";
NSString* CHChalkErrorBaseDecorationInvalid = @"CHChalkErrorBaseDecorationInvalid";
NSString* CHChalkErrorBaseDigitsInvalid = @"CHChalkErrorBaseDigitsInvalid";

NSString* CHChalkErrorDataOpen  = @"CHChalkErrorDataOpen";
NSString* CHChalkErrorDataRead  = @"CHChalkErrorDataRead";
NSString* CHChalkErrorDataWrite = @"CHChalkErrorDataWrite";

NSString* CHChalkErrorConversionNoRepresentation = @"CHChalkErrorConversionNoRepresentation";
NSString* CHChalkErrorConversionUnexpectedSign = @"CHChalkErrorConversionUnexpectedSign";
NSString* CHChalkErrorConversionUnexpectedExponent = @"CHChalkErrorConversionUnexpectedExponent";
NSString* CHChalkErrorConversionUnexpectedSignificand = @"CHChalkErrorConversionUnexpectedSignificand";
NSString* CHChalkErrorConversionUnsupportedSign = @"CHChalkErrorConversionUnsupportedSign";
NSString* CHChalkErrorConversionUnsupportedExponent = @"CHChalkErrorConversionUnsupportedExponent";
NSString* CHChalkErrorConversionUnsupportedSignificand = @"CHChalkErrorConversionUnsupportedSignificand";
NSString* CHChalkErrorConversionUnsupportedInfinity = @"CHChalkErrorConversionUnsupportedInfinity";
NSString* CHChalkErrorConversionUnsupportedNan = @"CHChalkErrorConversionUnsupportedNan";
NSString* CHChalkErrorConversionOverflow = @"CHChalkErrorConversionOverflow";

NSString* CHChalkErrorUserCancellation = @"CHChalkErrorUserCancellation";

@implementation CHChalkError

@synthesize reason;
@synthesize ranges;
@synthesize contextGenerator;
@synthesize reasonExtraInformation;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) chalkError
{
  return [[[[self class] alloc] init] autorelease];
}
//end chalkError

+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason
{
  return [[[[self class] alloc] initWithDomain:domain reason:reason] autorelease];
}
//end chalkErrorWithDomain:reason

+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason range:(NSRange)range
{
  return [[[[self class] alloc] initWithDomain:domain reason:reason range:range] autorelease];
}
//end chalkErrorWithDomain:reason:range:

+(instancetype) chalkErrorWithDomain:(NSString*)domain reason:(NSString*)reason ranges:(NSIndexSet*)ranges
{
  return [[[[self class] alloc] initWithDomain:domain reason:reason ranges:ranges] autorelease];
}
//end chalkErrorWithDomain:reason:ranges:

-(instancetype) init
{
  return [self initWithDomain:CHChalkErrorDomainChalk reason:nil];
}
//end init

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason
{
  return [self initWithDomain:aDomain reason:aReason range:NSRangeZero];
}
//end initWithDomain:reason:

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason range:(NSRange)aRange
{
  return [self initWithDomain:aDomain reason:aReason ranges:[NSIndexSet indexSetWithIndexesInRange:aRange]];
}
//end initWithDomain:reason:range:

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason ranges:(NSIndexSet*)aRanges
{
  if (!((self = [super initWithDomain:aDomain code:0 userInfo:nil])))
    return nil;
  self->ranges = [aRanges mutableCopy];
  self->reason = [aReason copy];
  return self;
}
//end initWithDomain:reason:range:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super init])))
    return nil;
  self->reason = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"reason"] copy];
  self->ranges = [[aDecoder decodeObjectOfClass:[NSMutableIndexSet class] forKey:@"ranges"] copy];
  self->contextGenerator = [[aDecoder decodeObjectForKey:@"contextGenerator"] retain];
  self->reasonExtraInformation = [[aDecoder decodeObjectForKey:@"reasonExtraInformation"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self->reason forKey:@"reason"];
  [aCoder encodeObject:self->ranges forKey:@"ranges"];
  if ([self->contextGenerator conformsToProtocol:@protocol(NSCoding)] ||
      [self->contextGenerator conformsToProtocol:@protocol(NSSecureCoding)])
    [aCoder encodeObject:self->contextGenerator forKey:@"contextGenerator"];
  if ([self->reasonExtraInformation conformsToProtocol:@protocol(NSCoding)] ||
      [self->reasonExtraInformation conformsToProtocol:@protocol(NSSecureCoding)])
    [aCoder encodeObject:self->reasonExtraInformation forKey:@"reasonExtraInformation"];
}
//end encodeWithCoder:

-(void) dealloc
{
  [self->ranges release];
  [self->reason release];
  [self->contextGenerator release];
  [self->reasonExtraInformation release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone *)zone
{
  CHChalkError* result = [super copyWithZone:zone];
  if (result)
  {
    result->ranges = [self->ranges copyWithZone:zone];
    result->reason = [self->reason copyWithZone:zone];
    result->contextGenerator = [self->contextGenerator retain];
    result->reasonExtraInformation = ![self->reasonExtraInformation conformsToProtocol:@protocol(NSCopying)] ? nil :
      [self->reasonExtraInformation copyWithZone:zone];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) setContextGenerator:(id)value replace:(BOOL)replace
{
  if ((value != self->contextGenerator) && ((!self->contextGenerator || replace)))
  {
    [self->contextGenerator release];
    self->contextGenerator = [value retain];
  }//end if ((value != self->contextGenerator) && ((!self->contextGenerator || replace)))
}
//end setExtraInformation:replace:

-(void) addRange:(NSRange)range
{
  [self->ranges addIndexesInRange:range];
}
//end addRange:

-(void) removeRange:(NSRange)range
{
  [self->ranges removeIndexesInRange:range];
}
//end removeRange:

+(NSString*) convertFromConversionError:(chalk_conversion_error_t)conversionError
{
  NSString* result = nil;
  switch(conversionError)
  {
    case CHALK_CONVERSION_ERROR_NOERROR:
      result = CHChalkErrorNoError;
      break;
    case CHALK_CONVERSION_ERROR_NO_REPRESENTATION:
      result = CHChalkErrorConversionNoRepresentation;
      break;
    case CHALK_CONVERSION_ERROR_ALLOCATION:
      result = CHChalkErrorAllocation;
      break;
    case CHALK_CONVERSION_ERROR_UNEXPECTED_SIGN:
      result = CHChalkErrorConversionUnexpectedSign;
      break;
    case CHALK_CONVERSION_ERROR_UNEXPECTED_EXPONENT:
      result = CHChalkErrorConversionUnexpectedExponent;
      break;
    case CHALK_CONVERSION_ERROR_UNEXPECTED_SIGNIFICAND:
      result = CHChalkErrorConversionUnexpectedSignificand;
      break;
    case CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGN:
      result = CHChalkErrorConversionUnsupportedSign;
      break;
    case CHALK_CONVERSION_ERROR_UNSUPPORTED_EXPONENT:
      result = CHChalkErrorConversionUnsupportedExponent;
      break;
    case CHALK_CONVERSION_ERROR_UNSUPPORTED_SIGNIFICAND:
      result = CHChalkErrorConversionUnsupportedSignificand;
      break;
    case CHALK_CONVERSION_ERROR_UNSUPPORTED_INFINITY:
      result = CHChalkErrorConversionUnsupportedInfinity;
      break;
    case CHALK_CONVERSION_ERROR_UNSUPPORTED_NAN:
      result = CHChalkErrorConversionUnsupportedNan;
      break;
    case CHALK_CONVERSION_ERROR_OVERFLOW:
      result = CHChalkErrorConversionOverflow;
      break;
  }//end switch(conversionError)
  return result;
};
//end chalk_conversion_error_t

-(NSString*) friendlyDescription
{
  NSString* result = self.description;
  if ([self->reason isEqualToString:CHChalkErrorNoError])
    result = NSLocalizedString(@"No error", @"");
  else if ([self->reason isEqualToString:CHChalkErrorUnknown])
    result = NSLocalizedString(@"Unknown error", @"");
  else if ([self->reason isEqualToString:CHChalkErrorParseError])
    result = NSLocalizedString(@"Syntax error", @"");
  else if ([self->reason isEqualToString:CHChalkErrorUnimplemented])
    result = NSLocalizedString(@"Not implemented", @"");
  else if ([self->reason isEqualToString:CHChalkErrorAllocation])
    result = NSLocalizedString(@"Not enough memory", @"");
  else if ([self->reason isEqualToString:CHChalkErrorIdentifierUndefined])
    result = NSLocalizedString(@"Undefined identifier", @"");
  else if ([self->reason isEqualToString:CHChalkErrorIdentifierFunctionUndefined])
    result = NSLocalizedString(@"Undefined function identifier", @"");
  else if ([self->reason isEqualToString:CHChalkErrorIdentifierReserved])
    result = NSLocalizedString(@"Identifier is reserved", @"");
  else if ([self->reason isEqualToString:CHChalkErrorIntegerOverflow])
    result = NSLocalizedString(@"Integer overflow. You might have to consider increasing the integer bits limit.", @"");
  else if ([self->reason isEqualToString:CHChalkErrorOperatorUnknown])
    result = NSLocalizedString(@"Unknown operator", @"");
  else if ([self->reason isEqualToString:CHChalkErrorOperatorArgumentsError])
    result = NSLocalizedString(@"Invalid operands", @"");
  else if ([self->reason isEqualToString:CHChalkErrorOperatorArgumentsCountError])
    result = NSLocalizedString(@"Invalid operands count", @"");
  else if ([self->reason isEqualToString:CHChalkErrorOperatorOperationNonImplemented])
    result = NSLocalizedString(@"Operation not implemented", @"");
  else if ([self->reason isEqualToString:CHChalkErrorMatrixMalformed])
    result = NSLocalizedString(@"Malformed matrix", @"");
  else if ([self->reason isEqualToString:CHChalkErrorMatrixNotInvertible])
    result = NSLocalizedString(@"Matrix is not invertible", @"");
  else if ([self->reason isEqualToString:CHChalkErrorDimensionsMismatch])
    result = NSLocalizedString(@"Dimensions mismatch", @"");
  else if ([self->reason isEqualToString:CHChalkErrorNumericInvalid])
    result = NSLocalizedString(@"Invalid numeric operation", @"");
  else if ([self->reason isEqualToString:CHChalkErrorNumericDivideByZero])
    result = NSLocalizedString(@"Division by zero", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpUnsupported])
    result = NSLocalizedString(@"Unsupported number", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpOverflow])
    result = NSLocalizedString(@"Internal overflow", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpUnderflow])
    result = NSLocalizedString(@"Internal underflow", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpPrecisionOverflow])
    result = NSLocalizedString(@"Internal precision overflow", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpValueCannotInit])
    result = NSLocalizedString(@"Internal initialization failed", @"");
  else if ([self->reason isEqualToString:CHChalkErrorGmpBaseInvalid])
    result = NSLocalizedString(@"Invalid base", @"");
  else if ([self->reason isEqualToString:CHChalkErrorBaseDecorationAmbiguity])
    result = NSLocalizedString(@"Base identifiers are ambiguous", @"");
  else if ([self->reason isEqualToString:CHChalkErrorBaseDecorationConflict])
    result = NSLocalizedString(@"Base identifier conflict", @"");
  else if ([self->reason isEqualToString:CHChalkErrorBaseDecorationInvalid])
    result = NSLocalizedString(@"Invalid base identifier", @"");
  else if ([self->reason isEqualToString:CHChalkErrorBaseDigitsInvalid])
    result = NSLocalizedString(@"Invalid digits for base", @"");
  else if ([self->reason isEqualToString:CHChalkErrorDataOpen])
    result = NSLocalizedString(@"Cannot open data", @"");
  else if ([self->reason isEqualToString:CHChalkErrorDataRead])
    result = NSLocalizedString(@"Cannot read data", @"");
  else if ([self->reason isEqualToString:CHChalkErrorDataWrite])
    result = NSLocalizedString(@"Cannot write data", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionNoRepresentation])
    result = NSLocalizedString(@"No possible representation", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnexpectedSign])
    result = NSLocalizedString(@"Unexpected sign", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnexpectedExponent])
    result = NSLocalizedString(@"Unexpected exponent", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnexpectedSignificand])
    result = NSLocalizedString(@"Unexpected significand", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnsupportedSign])
    result = NSLocalizedString(@"Unsupported sign", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnsupportedExponent])
    result = NSLocalizedString(@"Unsupported exponent", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnsupportedSignificand])
    result = NSLocalizedString(@"Unsupported significand", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnsupportedInfinity])
    result = NSLocalizedString(@"Unsupported infinity", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionUnsupportedNan])
    result = NSLocalizedString(@"Unsupported NaN", @"");
  else if ([self->reason isEqualToString:CHChalkErrorConversionOverflow])
    result = NSLocalizedString(@"Overflow", @"");
  else if ([self->reason isEqualToString:CHChalkErrorUserCancellation])
    result = NSLocalizedString(@"User cancellation", @"");
  if (self->reasonExtraInformation)
    result = [NSString stringWithFormat:@"%@ (%@)", result, self->reasonExtraInformation];
  return result;
}
//end friendlyDescription

-(NSString*) description
{
  NSMutableString* result = [NSMutableString string];
  [result appendFormat:@"%@:", self->ranges];
  [result appendFormat:@"<%@>", self->reason];
  if (self->contextGenerator)
    [result appendFormat:@"(%@)", self->contextGenerator];
  if (self->reasonExtraInformation)
    [result appendFormat:@"(%@)", self->reasonExtraInformation];
  return [[result copy] autorelease];
}
//end description

@end
