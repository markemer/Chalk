//
//  CHChalkValueQuaternion.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueQuaternion.h"

#import "CHChalkContext.h"
#import "CHChalkUtils.h"
#import "CHChalkValueNumber.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueQuaternion

@synthesize partReal;
@synthesize partI;
@synthesize partJ;
@synthesize partK;
@dynamic    isZero;
@dynamic    isReal;
@dynamic    isComplex;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) zeroWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = [[[[self class] alloc] initWithToken:token
     partReal:[CHChalkValueNumberGmp zeroWithToken:token context:context] partRealWrapped:YES
     partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
     partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
     partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
     context:nil] autorelease];
  return result;
}
//end zeroWithToken:context:

+(instancetype) oneI
{
  id result = [self oneIWithToken:nil context:nil];
  return result;
}
//end oneI

+(instancetype) oneJ
{
  id result = [self oneJWithToken:nil context:nil];
  return result;
}
//end oneJ

+(instancetype) oneK
{
  id result = [self oneKWithToken:nil context:nil];
  return result;
}
//end oneK

+(instancetype) oneIWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = nil;
  CHChalkValueNumberGmp* oneValue = [[[CHChalkValueNumberGmp alloc] initWithToken:token integer:1 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:nil] autorelease];
  result = [[[[self class] alloc] initWithToken:token
    partReal:[CHChalkValueNumberGmp zeroWithToken:token context:context] partRealWrapped:YES
    partI:oneValue partIWrapped:YES
    partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
    partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
    context:nil] autorelease];
  return result;
}
//end oneIWithToken:context:

+(instancetype) oneJWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = nil;
  CHChalkValueNumberGmp* oneValue = [[[CHChalkValueNumberGmp alloc] initWithToken:token integer:1 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  result = [[[[self class] alloc] initWithToken:token
    partReal:[CHChalkValueNumberGmp zeroWithToken:token context:context] partRealWrapped:YES
    partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
    partJ:oneValue partJWrapped:YES
    partK:[CHChalkValueNumberGmp zeroWithToken:token context:context] partKWrapped:YES
    context:nil] autorelease];
  return result;
}
//end oneJWithToken:context:

+(instancetype) oneKWithToken:(CHChalkToken*)token context:(CHChalkContext*)context
{
  id result = nil;
  CHChalkValueNumberGmp* oneValue = [[[CHChalkValueNumberGmp alloc] initWithToken:token integer:1 naturalBase:(!context ? 10 : context.computationConfiguration.baseDefault) context:context] autorelease];
  result = [[[[self class] alloc] initWithToken:token
    partReal:[CHChalkValueNumberGmp zeroWithToken:token context:context] partRealWrapped:YES
    partI:[CHChalkValueNumberGmp zeroWithToken:token context:context] partIWrapped:YES
    partJ:[CHChalkValueNumberGmp zeroWithToken:token context:context] partJWrapped:YES
    partK:oneValue partKWrapped:YES
    context:nil] autorelease];
  return result;
}
//end oneKWithToken:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken
                     partReal:(CHChalkValueNumber*)aPartReal partRealWrapped:(BOOL)aPartRealWrapped
                     partI:(CHChalkValueNumber*)aPartI partIWrapped:(BOOL)aPartIWrapped
                     partJ:(CHChalkValueNumber*)aPartJ partJWrapped:(BOOL)aPartJWrapped
                     partK:(CHChalkValueNumber*)aPartK partKWrapped:(BOOL)aPartKWrapped
                   context:(CHChalkContext*)context;
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->partReal        = aPartRealWrapped ? [aPartReal retain] : [aPartReal copy];
  self->partRealWrapped = aPartRealWrapped;
  self->partI           = aPartIWrapped ? [aPartI retain] : [aPartI copy];
  self->partIWrapped    = aPartIWrapped;
  self->partJ           = aPartJWrapped ? [aPartJ retain] : [aPartJ copy];
  self->partJWrapped    = aPartJWrapped;
  self->partK           = aPartKWrapped ? [aPartK retain] : [aPartK copy];
  self->partKWrapped    = aPartKWrapped;
  self->evaluationComputeFlags =
    self->partReal.evaluationComputeFlags |
    self->partI.evaluationComputeFlags |
    self->partJ.evaluationComputeFlags |
    self->partK.evaluationComputeFlags;
  return self;
}
//end initWithRealPart:realPartWrapped:imagPart:imagPartWrapped:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->partReal = [[aDecoder decodeObjectOfClass:[CHChalkValueNumber class] forKey:@"partReal"] retain];
  self->partRealWrapped = [aDecoder decodeBoolForKey:@"partRealWrapped"];
  self->partI = [[aDecoder decodeObjectOfClass:[CHChalkValueNumber class] forKey:@"partI"] retain];
  self->partIWrapped = [aDecoder decodeBoolForKey:@"partIWrapped"];
  self->partJ = [[aDecoder decodeObjectOfClass:[CHChalkValueNumber class] forKey:@"partJ"] retain];
  self->partJWrapped = [aDecoder decodeBoolForKey:@"partJWrapped"];
  self->partK = [[aDecoder decodeObjectOfClass:[CHChalkValueNumber class] forKey:@"partK"] retain];
  self->partKWrapped = [aDecoder decodeBoolForKey:@"partKWrapped"];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->partReal forKey:@"partReal"];
  [aCoder encodeBool:self->partRealWrapped forKey:@"partRealWrapped"];
  [aCoder encodeObject:self->partI forKey:@"partI"];
  [aCoder encodeBool:self->partIWrapped forKey:@"partIWrapped"];
  [aCoder encodeObject:self->partJ forKey:@"partJ"];
  [aCoder encodeBool:self->partJWrapped forKey:@"partJWrapped"];
  [aCoder encodeObject:self->partK forKey:@"partK"];
  [aCoder encodeBool:self->partKWrapped forKey:@"partKWrapped"];
}
//end encodeWithCoder:

-(void) dealloc
{
  [self->partReal release];
  [self->partI release];
  [self->partJ release];
  [self->partK release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueQuaternion* result = [super copyWithZone:zone];
  if (result)
  {
    result->partReal        = [self->partReal copyWithZone:zone];
    result->partRealWrapped = NO;
    result->partI           = [self->partI copyWithZone:zone];
    result->partIWrapped    = NO;
    result->partJ           = [self->partJ copyWithZone:zone];
    result->partJWrapped    = NO;
    result->partK           = [self->partK copyWithZone:zone];
    result->partKWrapped    = NO;
    result->evaluationComputeFlags = self->evaluationComputeFlags;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueQuaternion* dstComplex = !result ? nil : [dst dynamicCastToClass:[CHChalkValueQuaternion class]];
  if (result && dstComplex)
  {
    dstComplex->partReal = self->partReal;
    self->partReal = nil;
    dstComplex->partRealWrapped = self->partRealWrapped;
    self->partRealWrapped = NO;
    dstComplex->partI = self->partI;
    self->partI = nil;
    dstComplex->partIWrapped = self->partIWrapped;
    self->partIWrapped = NO;
    dstComplex->partJ = self->partJ;
    self->partJ = nil;
    dstComplex->partJWrapped = self->partJWrapped;
    self->partJWrapped = NO;
    dstComplex->partK = self->partK;
    self->partK = nil;
    dstComplex->partKWrapped = self->partKWrapped;
    self->partKWrapped = NO;
  }//end if (result && dstComplex)
  return result;
}
//end moveTo:

-(void) setPartReal:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped
{
  if ((value != self->partReal) || (self->partRealWrapped != wrapped))
  {
    if (value != self->partReal)
    {
      [self->partReal release];
      self->partReal = wrapped ? [value retain] : [value copy];
    }//end if (value != self->partReal)
    self->partRealWrapped = wrapped;
    self->evaluationComputeFlags =
      self->partReal.evaluationComputeFlags |
      self->partI.evaluationComputeFlags |
      self->partJ.evaluationComputeFlags |
      self->partK.evaluationComputeFlags;
  }//end if ((value != self->partReal) || (self->partRealWrapped != wrapped))
}
//end setPartReal:wrapped:

-(void) setPartI:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped
{
  if ((value != self->partI) || (self->partIWrapped != wrapped))
  {
    if (value != self->partI)
    {
      [self->partI release];
      self->partI = wrapped ? [value retain] : [value copy];
    }//end if (value != self->partI)
    self->partIWrapped = wrapped;
    self->evaluationComputeFlags =
      self->partReal.evaluationComputeFlags |
      self->partI.evaluationComputeFlags |
      self->partJ.evaluationComputeFlags |
      self->partK.evaluationComputeFlags;
  }//end if ((value != self->partI) || (self->partIWrapped != wrapped))
}
//end setPartI:wrapped:

-(void) setPartJ:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped
{
  if ((value != self->partJ) || (self->partJWrapped != wrapped))
  {
    if (value != self->partJ)
    {
      [self->partJ release];
      self->partJ = wrapped ? [value retain] : [value copy];
    }//end if (value != self->partJ)
    self->partJWrapped = wrapped;
    self->evaluationComputeFlags =
      self->partReal.evaluationComputeFlags |
      self->partI.evaluationComputeFlags |
      self->partJ.evaluationComputeFlags |
      self->partK.evaluationComputeFlags;
  }//end if ((value != self->partJ) || (self->partJWrapped != wrapped))
}
//end setPartJ:wrapped:

-(void) setPartK:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped
{
  if ((value != self->partK) || (self->partKWrapped != wrapped))
  {
    if (value != self->partK)
    {
      [self->partK release];
      self->partK = wrapped ? [value retain] : [value copy];
    }//end if (value != self->partK)
    self->partKWrapped = wrapped;
    self->evaluationComputeFlags =
      self->partReal.evaluationComputeFlags |
      self->partI.evaluationComputeFlags |
      self->partJ.evaluationComputeFlags |
      self->partK.evaluationComputeFlags;
  }//end if ((value != self->partK) || (self->partKWrapped != wrapped))
}
//end setPartK:wrapped:

-(BOOL) isZero
{
  BOOL result =
    (!self->partReal || self->partReal.isZero) &&
    (!self->partI || self->partI.isZero) &&
    (!self->partJ || self->partJ.isZero) &&
    (!self->partK || self->partK.isZero);
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign
{
  BOOL result = [self->partReal isOne:isOneIgnoringSign] &&
    (!self->partI || self->partI.isZero) &&
    (!self->partJ || self->partJ.isZero) &&
    (!self->partK || self->partK.isZero);
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = NO;
  BOOL nR = [self->partReal negate];
  BOOL nI = [self->partI negate];
  BOOL nJ = [self->partJ negate];
  BOOL nK = [self->partK negate];
  result = nR && nI && nJ && nK;
  if (result){
  }
  else//if (!result)
  {
    if (nR)
      [self->partReal negate];
    if (nI)
      [self->partI negate];
    if (nJ)
      [self->partJ negate];
    if (nK)
      [self->partK negate];
  }//end if (!result)
  return result;
}
//end negate

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_group_t group = dispatch_group_create();
  dispatch_group_async_gmp(group, queue, ^{[self->partReal adaptToComputeMode:computeMode context:context];});
  dispatch_group_async_gmp(group, queue, ^{[self->partI adaptToComputeMode:computeMode context:context];});
  dispatch_group_async_gmp(group, queue, ^{[self->partJ adaptToComputeMode:computeMode context:context];});
  dispatch_group_async_gmp(group, queue, ^{[self->partK adaptToComputeMode:computeMode context:context];});
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  dispatch_release(group);
}
//end adaptToComputeMode:context:

-(BOOL) isReal
{
  BOOL result =
    (!self->partI || self->partI.isZero) &&
    (!self->partJ || self->partJ.isZero) &&
    (!self->partK || self->partK.isZero);
  return result;
}
//end isReal

-(BOOL) isComplex
{
  BOOL result =
    (!self->partJ || self->partJ.isZero) &&
    (!self->partK || self->partK.isZero);
  return result;
}
//end isComplex

-(CHChalkValueQuaternion*) conjugated
{
  CHChalkValueQuaternion* result = [[self copy] autorelease];
  [result conjugate];
  return result;
}
//end conjugated

-(CHChalkValueQuaternion*) conjugate
{
  [self->partI negate];
  [self->partJ negate];
  [self->partK negate];
  return self;
}
//end conjugate

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!self->partReal && !self->partI && !self->partJ && !self->partK)
    [CHChalkValue writeToStream:stream context:context numberString:@"0" presentationConfiguration:presentationConfiguration];
  else if (self.isReal)
    [self->partReal writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
  else//if (!self.isReal)
  {
    __block BOOL hasPreviousPart = (self->partReal && !self->partReal.isZero);
    if (hasPreviousPart)
      [self->partReal writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
    NSArray* parts = @[[NSObject nullAdapter:partI], [NSObject nullAdapter:partJ], [NSObject nullAdapter:partK]];
    [parts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHChalkValueNumberGmp* part = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
      if (part && !part.isZero)
      {
        if (hasPreviousPart && !(part.sign < 0))
          [CHChalkValue writeToStream:stream context:context operatorString:@"+" presentationConfiguration:presentationConfiguration];
        CHChalkValueNumberGmp* partGmp = [part dynamicCastToClass:[CHChalkValueNumberGmp class]];
        const chalk_gmp_value_t* partGmpValue = partGmp.valueConstReference;
        BOOL isFraction = partGmpValue && (partGmpValue->type == CHALK_VALUE_TYPE_FRACTION) && (context.computationConfiguration.computeMode == CHALK_COMPUTE_MODE_EXACT);
        if (isFraction)
        {
          mpz_srcptr num = mpq_numref(partGmpValue->fraction);
          if (!mpz_cmp_si(num, 1)) {
          }
          else if (!mpz_cmp_si(num, -1))
            [stream writeString:@"-"];
          else
          {
            [CHChalkValueNumberGmp writeMpzToStream:stream context:context value:num token:self->token presentationConfiguration:presentationConfiguration];
          }
          if (idx == 2)
            [[self class] writeKToStream:stream context:context presentationConfiguration:presentationConfiguration];
          else if (idx == 1)
            [[self class] writeJToStream:stream context:context presentationConfiguration:presentationConfiguration];
          else
            [[self class] writeIToStream:stream context:context presentationConfiguration:presentationConfiguration];
          [stream writeString:@"/"];
          [CHChalkValueNumberGmp writeMpzToStream:stream context:context value:mpq_denref(partGmpValue->fraction) token:self->token presentationConfiguration:presentationConfiguration];
        }//end if (isFraction)
        else//if (!isFraction)
        {
          BOOL isOneIgnoringSign = NO;
          if (![part isOne:&isOneIgnoringSign] && !isOneIgnoringSign)
            [part writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
          else if (part.sign < 0)
            [stream writeString:@"-"];
          if (idx == 2)
            [[self class] writeKToStream:stream context:context presentationConfiguration:presentationConfiguration];
          else if (idx == 1)
            [[self class] writeJToStream:stream context:context presentationConfiguration:presentationConfiguration];
          else
            [[self class] writeIToStream:stream context:context presentationConfiguration:presentationConfiguration];
        }//end if (!isFraction)
        hasPreviousPart |= !part.isZero;
      }//end if (part && !part.isZero)
    }];
    if (!hasPreviousPart)
      [CHChalkValue writeToStream:stream context:context numberString:@"0" presentationConfiguration:presentationConfiguration];
  }//end if (!self.isReal)
}
//end writeToStream:context:options:

+(void) writeIToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
    [stream writeString:@"i" bold:YES italic:NO];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:@"<span style=\"font-weight:bold\">i</span>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mi>i</mi>"];
  else
    [stream writeString:@"i"];
}
//end writeIToStream:context:options:

+(void) writeJToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
    [stream writeString:@"j" bold:YES italic:NO];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:@"<span style=\"font-weight:bold\">j</span>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mi>j</mi>"];
  else
    [stream writeString:@"j"];
}
//end writeJToStream:context:options:

+(void) writeKToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
    [stream writeString:@"k" bold:YES italic:NO];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:@"<span style=\"font-weight:bold\">k</span>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mi>k</mi>"];
  else
    [stream writeString:@"k"];
}
//end writeKToStream:context:options:

@end
