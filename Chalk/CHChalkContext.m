//
//  CHChalkContext.m
//  Chalk
//
//  Created by Pierre Chatelier on 26/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkContext.h"

#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkUtils.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHUtils.h"
#import "CHParseConfiguration.h"
#import "CHPreferencesController.h"
#import "CHPresentationConfiguration.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHChalkContext

@synthesize undoManager;
@synthesize parseConfiguration;
@synthesize computationConfiguration;
@synthesize presentationConfiguration;
@synthesize concurrentEvaluations;
@synthesize outputRawToken;
@synthesize basePrefixesSuffixes;
@synthesize errorContext;
@synthesize identifierManager;
@synthesize operatorManager;
@synthesize gmpPool;
@synthesize referenceAge;
@synthesize delegate;

-(instancetype) initWithGmpPool:(CHGmpPool*)pool
{
  if (!((self = [super init])))
    return nil;
  self->parseConfiguration = [[CHParseConfiguration alloc] init];
  self->computationConfiguration = [[CHComputationConfiguration alloc] init];
  self->presentationConfiguration = [[CHPresentationConfiguration alloc] init];
  self->hardMaxExponent = mpfr_get_emax();
  self->errorContext = [[CHChalkErrorContext alloc] init];
  self->cachedSoftIntegerMaxDigitsByBase = [[NSMutableDictionary alloc] init];
  self->cachedSoftIntegerMaxDenominatorDigitsByBase = [[NSMutableDictionary alloc] init];
  self->cachedSoftFloatSignificandDigitsByBase = [[NSMutableDictionary alloc] init];
  self->cachedSoftFloatDisplayDigitsByBase = [[NSMutableDictionary alloc] init];
  self->gmpPool = [pool retain];
  if (!self->gmpPool)
  {
    [self release];
    return nil;
  }//end if (!self->gmpPool)
  [self reset];
  return self;
}
//end initWithGmpPool:

-(void) dealloc
{
  [self->parseConfiguration release];
  [self->computationConfiguration release];
  [self->presentationConfiguration release];
  [self->errorContext release];
  [self->cachedSoftIntegerMaxDigitsByBase release];
  [self->cachedSoftIntegerMaxDenominatorDigitsByBase release];
  [self->cachedSoftFloatSignificandDigitsByBase release];
  [self->cachedSoftFloatDisplayDigitsByBase release];
  [self->identifierManager release];
  [self->operatorManager release];
  [self->gmpPool release];
  [self->basePrefixesSuffixes release];
  [self->basePrefixesSuffixesDictionary release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkContext* result = [[[self class] alloc] initWithGmpPool:self->gmpPool];
  if (result)
  {
    [result->parseConfiguration release];
    result->parseConfiguration = [self->parseConfiguration copyWithZone:zone];
    [result->computationConfiguration release];
    result->computationConfiguration = [self->computationConfiguration copyWithZone:zone];
    [result->presentationConfiguration release];
    result->presentationConfiguration = [self->presentationConfiguration copyWithZone:zone];
    result->concurrentEvaluations = self->concurrentEvaluations;
    result->outputRawToken = self->outputRawToken;
    result.basePrefixesSuffixes = self.basePrefixesSuffixes;
    [result->identifierManager release];
    result->identifierManager = [self->identifierManager retain];
    [result->operatorManager release];
    result->operatorManager = [self->operatorManager retain];
    result->referenceAge = self->referenceAge;
    result->delegate = self->delegate;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) reset
{
  [self reclaimResources];
  [self->parseConfiguration reset];
  [self->computationConfiguration reset];
  [self->presentationConfiguration reset];
  [self invalidateCaches];
  [self->errorContext reset:nil];
  self->outputRawToken = NO;
  self.basePrefixesSuffixes = nil;
}
//end reset

-(void) invalidateCaches
{
  @synchronized(self)
  {
    [self->cachedSoftIntegerMaxDigitsByBase removeAllObjects];
    [self->cachedSoftIntegerMaxDenominatorDigitsByBase removeAllObjects];
    [self->cachedSoftFloatSignificandDigitsByBase removeAllObjects];
    [self->cachedSoftFloatDisplayDigitsByBase removeAllObjects];
  }//end @synchronized(self)
}
//end invalidateCaches

-(NSUInteger) softIntegerMaxDigitsWithBase:(int)base
{
  NSUInteger result = 0;
  NSNumber* cachedValue = nil;
  if (base == 2)
    result = self->computationConfiguration.softIntegerMaxBits;
  else//if (base != 2)
  {
    @synchronized(self->cachedSoftIntegerMaxDigitsByBase)
    {
      cachedValue =
        [[self->cachedSoftIntegerMaxDigitsByBase objectForKey:[NSNumber numberWithInteger:base]]
          dynamicCastToClass:[NSNumber class]];
    }//end @synchronized(self->cachedSoftIntegerMaxDigitsByBase)
    if (cachedValue)
      result = [cachedValue unsignedIntegerValue];
    else//if (!cachedValue)
    {
      result = chalkGmpGetMaximumDigitsCountFromBitsCount(self->computationConfiguration.softIntegerMaxBits, base);
      cachedValue = [NSNumber numberWithUnsignedInteger:result];
      if (cachedValue)
      {
        @synchronized(self->cachedSoftIntegerMaxDigitsByBase)
        {
          [self->cachedSoftIntegerMaxDigitsByBase setObject:cachedValue forKey:[NSNumber numberWithInteger:base]];
        }//end @synchronized(self->cachedSoftIntegerMaxDigitsByBase)
      }//end if (cachedValue)
    }//end if (!cachedValue)
  }//end if (base != 2)
  return result;
}
//end softIntegerMaxDigitsWithBase:

-(NSUInteger) softIntegerMaxDenominatorDigitsWithBase:(int)base
{
  NSUInteger result = 0;
  NSNumber* cachedValue = nil;
  if (base == 2)
    result = self->computationConfiguration.softIntegerDenominatorMaxBits;
  else//if (base != 2)
  {
    @synchronized(self->cachedSoftIntegerMaxDenominatorDigitsByBase)
    {
      cachedValue =
        [[self->cachedSoftIntegerMaxDenominatorDigitsByBase objectForKey:[NSNumber numberWithInteger:base]]
          dynamicCastToClass:[NSNumber class]];
    }//end @synchronized(self->cachedSoftIntegerMaxDenominatorDigitsByBase)
    if (cachedValue)
      result = [cachedValue unsignedIntegerValue];
    else//if (!cachedValue)
    {
      result = chalkGmpGetMaximumDigitsCountFromBitsCount(self->computationConfiguration.softIntegerDenominatorMaxBits, base);
      cachedValue = [NSNumber numberWithUnsignedInteger:result];
      if (cachedValue)
      {
        @synchronized(self->cachedSoftIntegerMaxDenominatorDigitsByBase)
        {
          [self->cachedSoftIntegerMaxDenominatorDigitsByBase setObject:cachedValue forKey:[NSNumber numberWithInteger:base]];
        }//end @synchronized(self->cachedSoftIntegerMaxDenominatorDigitsByBase)
      }//end if (cachedValue)
    }//end if (!cachedValue)
  }//end if (base != 2)
  return result;
}
//end softIntegerMaxDenominatorDigitsWithBase:

-(NSUInteger) softFloatSignificandDigitsWithBase:(int)base
{
  NSUInteger result = 0;
  NSNumber* cachedValue = nil;
  @synchronized(self->cachedSoftFloatSignificandDigitsByBase)
  {
    cachedValue =
      [[self->cachedSoftFloatSignificandDigitsByBase objectForKey:[NSNumber numberWithInteger:base]]
       dynamicCastToClass:[NSNumber class]];
  }//end @synchronized(self->cachedSoftFloatSignificandDigitsByBase)
  if (cachedValue)
    result = [cachedValue unsignedIntegerValue];
  else//if (!cachedValue)
  {
    result = chalkGmpGetMaximumDigitsCountFromBitsCount(self->computationConfiguration.softFloatSignificandBits, base);
    cachedValue = [NSNumber numberWithUnsignedInteger:result];
    if (cachedValue)
    {
      @synchronized(self->cachedSoftFloatSignificandDigitsByBase)
      {
        [self->cachedSoftFloatSignificandDigitsByBase setObject:cachedValue forKey:[NSNumber numberWithInteger:base]];
      }//end @synchronized(self->cachedSoftFloatSignificandDigitsByBase)
    }//end if (cachedValue)
  }//end if (!cachedValue)
  return result;
}
//end softFloatSignificandDigitsWithBase:

-(NSUInteger) softFloatDisplayDigitsWithBase:(int)base
{
  NSUInteger result = 0;
  NSNumber* cachedValue = nil;
  @synchronized(self->cachedSoftFloatDisplayDigitsByBase)
  {
    cachedValue =
      [[self->cachedSoftFloatDisplayDigitsByBase objectForKey:[NSNumber numberWithInteger:base]]
       dynamicCastToClass:[NSNumber class]];
  }//end @synchronized(self->cachedSoftFloatDisplayDigitsByBase)
  if (cachedValue)
    result = [cachedValue unsignedIntegerValue];
  else//if (!cachedValue)
  {
    result = chalkGmpGetMaximumDigitsCountFromBitsCount(self->presentationConfiguration.softFloatDisplayBits, base);
    cachedValue = [NSNumber numberWithUnsignedInteger:result];
    if (cachedValue)
    {
      @synchronized(self->cachedSoftFloatDisplayDigitsByBase)
      {
        [self->cachedSoftFloatDisplayDigitsByBase setObject:cachedValue forKey:[NSNumber numberWithInteger:base]];
      }//end @synchronized(self->cachedSoftFloatDisplayDigitsByBase)
    }//end if (cachedValue)
  }//end if (!cachedValue)
  return result;
}
//end softFloatDisplayDigitsWithBase:

-(void) setBasePrefixesSuffixes:(NSArray*)value
{
  if (value != self->basePrefixesSuffixes)
  {
    [self->basePrefixesSuffixes release];
    [self->basePrefixesSuffixesDictionary release];
    self->basePrefixesSuffixes = [value copy];
    self->basePrefixesSuffixesDictionary = [[NSMutableDictionary alloc] initWithCapacity:self->basePrefixesSuffixes.count];
    for(id object in self->basePrefixesSuffixes)
    {
      NSNumber* key = [[[object dynamicCastToClass:[NSDictionary class]] objectForKey:CHBaseBaseKey]dynamicCastToClass:[NSNumber class]];
      if (key)
        [self->basePrefixesSuffixesDictionary setObject:object forKey:key];
    }//end for each object
  }//end if (value != self->basePrefixesSuffixes)
}
//end setBasePrefixesSuffixes:

-(NSArray*) inputPrefixesForBase:(int)base
{
  NSArray* result = nil;
  NSArray* components = [[[[self->basePrefixesSuffixesDictionary objectForKey:@(base)] dynamicCastToClass:[NSDictionary class]] objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSArray class]];
  result = [components
      filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
      BOOL result = NO;
      NSString* string = [evaluatedObject dynamicCastToClass:[NSString class]];
      result = chalkGmpBaseIsValidPrefix(string);
      return result;
    }]];
  return result;
}
//end inputPrefixesForBase:

-(NSArray*) inputSuffixesForBase:(int)base
{
  NSArray* result = nil;
  NSArray* components = [[[[self->basePrefixesSuffixesDictionary objectForKey:@(base)] dynamicCastToClass:[NSDictionary class]] objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSArray class]];
  result = [components
      filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
      BOOL result = NO;
      NSString* string = [evaluatedObject dynamicCastToClass:[NSString class]];
      result = chalkGmpBaseIsValidSuffix(string);
      return result;
    }]];
  return result;
}
//end inputSuffixesForBase:

-(NSString*) inputPrefixForBase:(int)base
{
  NSString* result = [self inputPrefixesForBase:base].firstObject;
  return result;
}
//end inputPrefixForBase:

-(NSString*) inputSuffixForBase:(int)base
{
  NSString* result = [self inputSuffixesForBase:base].firstObject;
  return result;
}
//end inputSuffixForBase:

-(NSArray*) outputPrefixesForBase:(int)base
{
  NSArray* result = nil;
  NSArray* components = [[[[self->basePrefixesSuffixesDictionary objectForKey:@(base)] dynamicCastToClass:[NSDictionary class]] objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSArray class]];
  result =
    [components
      filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
          BOOL result = NO;
          NSString* string = [evaluatedObject dynamicCastToClass:[NSString class]];
          result = chalkGmpBaseIsValidPrefix(string);
          return result;}
        ]
    ];
  return result;
}
//end outputPrefixesForBase:

-(NSArray*) outputSuffixesForBase:(int)base
{
  NSArray* result = nil;
  NSArray* components = [[[[self->basePrefixesSuffixesDictionary objectForKey:@(base)] dynamicCastToClass:[NSDictionary class]] objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSArray class]];
  result =
    [components
      filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
          BOOL result = NO;
          NSString* string = [evaluatedObject dynamicCastToClass:[NSString class]];
          result = chalkGmpBaseIsValidSuffix(string);
          return result;}
        ]
    ];
  return result;
}
//end outputSuffixesForBase:

-(NSString*) outputPrefixForBase:(int)base
{
  NSString* result = [self outputPrefixesForBase:base].firstObject;
  return result;
}
//end outputPrefixForBase:

-(NSString*) outputSuffixForBase:(int)base
{
  NSString* result = [self outputSuffixesForBase:base].firstObject;
  return result;
}
//end outputSuffixForBase:

-(int) baseFromPrefix:(NSString*)prefix
{
  int result = 0;
  if ([NSString isNilOrEmpty:prefix])
    result = self->computationConfiguration.baseDefault;
  else//if (![NSString isNilOrEmpty:prefix])
  {
    __block NSNumber* baseNumber = nil;
    __block BOOL conflict = NO;
    [self->basePrefixesSuffixesDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
      NSDictionary* dict = [obj dynamicCastToClass:[NSDictionary class]];
      NSArray* basePrefixes = [[dict objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSArray class]];
      if ([basePrefixes containsObject:prefix])
      {
        conflict |= (baseNumber != nil);
        baseNumber = [[dict objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
      }//end if ([basePrefixes containsObject:prefix])
    }];
    result = conflict ? 0 : [baseNumber intValue];
  }//end if (![NSString isNilOrEmpty:prefix])
  return result;
}
//end baseFromPrefix:

-(int) baseFromSuffix:(NSString*)suffix
{
  int result = 0;
  if ([NSString isNilOrEmpty:suffix])
    result = self->computationConfiguration.baseDefault;
  else//if (![NSString isNilOrEmpty:suffix])
  {
    __block NSNumber* baseNumber = nil;
    __block BOOL conflict = NO;
    [self->basePrefixesSuffixesDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
      NSDictionary* dict = [obj dynamicCastToClass:[NSDictionary class]];
      NSArray* baseSuffixes = [[dict objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSArray class]];
      if ([baseSuffixes containsObject:suffix])
      {
        conflict |= (baseNumber != nil);
        baseNumber = [[dict objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
      }//end if ([baseSuffixesSeparated containsObject:suffix])
    }];
    result = conflict ? 0 : [baseNumber intValue];
  }//end if (![NSString isNilOrEmpty:suffix])
  return result;
}
//end baseFromSuffix:

-(void*) depoolMemoryForMpfrGetStr:(mpfr_srcptr)input nbDigits:(size_t)nbDigits
{
  void* result = 0;
  size_t size = 0;
  BOOL overflow = NO;
  if (!nbDigits)
    overflow = YES;
  else if (!mpfr_number_p(input))
    size = 7;//min required by the doc (for "@NaN@" or "-@Inf@")
  else//if (mpfr_number_p(input))
  {
    int isZero = mpfr_zero_p(input);
    if (isZero)
      size = 1;
    else//if (!isZero)
    {
      size = nbDigits;
      int sgn = mpfr_sgn(input);
      if (sgn < 0)
      {
        overflow |= (size+1U < size);//sign
        ++size;
      }//end if (sgn < 0)
      overflow |= (size+1U < size);//decimal separator
      ++size;
    }//end if (!isZero)
  }//end if (mpfr_number_p(input))
  result = overflow ? 0 : malloc(size);
  return result;
}
//end depoolMemoryForMpfrGetStrWithDigits:

-(void*) depoolMemoryForMpzGetStr:(mpz_srcptr)input base:(int)base
{
  void* result = 0;
  size_t nbDigits = mpz_sizeinbase(input, ABS(base));
  size_t size = 0;
  BOOL overflow = NO;
  overflow |= (size+nbDigits < size);
  size += nbDigits;
  if (mpz_sgn(input)<0)
  {
    overflow |= (size+1U < size);//sign
    ++size;
  }//end if (mpz_sgn(input)<0)
  overflow |= (size+1U < size);//null terminator
  size += 1;
  result = overflow ? 0 : malloc(size);
  return result;
}
//end depoolMemoryForMpzGetStr:

-(void*) depoolMemoryForMpqGetStr:(mpq_srcptr)input base:(int)base
{
  void* result = 0;
  size_t nbDigits1 = mpz_sizeinbase(mpq_numref(input), ABS(base));
  BOOL isDenominatorOne = !mpz_cmp_si(mpq_denref(input), 1) || !mpz_cmp_si(mpq_denref(input), -1);
  size_t nbDigits2 = isDenominatorOne ? 0 : mpz_sizeinbase(mpq_denref(input), ABS(base));
  size_t size = 0;
  BOOL overflow = NO;
  overflow |= (size+nbDigits1 < size);
  size += nbDigits1;
  overflow |= (size+nbDigits2 < size);
  size += nbDigits2;
  if (mpq_sgn(input)<0)
  {
    overflow |= (size+1U < size);//sign
    ++size;
  }//end if (mpq_sgn(input)<0)
  if (!isDenominatorOne)
  {
    overflow |= (size+1U < size);//slash
    ++size;
  }//end if (!isDenominatorOne)
  overflow |= (size+1U < size);//null terminator
  size += 1;
  result = overflow ? 0 : malloc(size);
  return result;
}
//end depoolMemoryForMpqGetStr:

-(void) repoolMemory:(void*)memory
{
  free(memory);
}
//end repoolMemory:

-(BOOL) reclaimResources
{
  BOOL result = NO;
  return result;
}
//end reclaimResources

+(void) repoolMemory:(void*)memory forMpzOutBuffer:(void*)mpzOutBuffer context:(CHChalkContext*)context
{
  if (mpzOutBuffer && (!memory || !context))
    free(mpzOutBuffer);
  else if (memory && context)
    [context repoolMemory:memory];
}
//end repoolMemory:forMpzOutBuffer:context:

+(void) repoolMemory:(void*)memory forMpqOutBuffer:(void*)mpqOutBuffer context:(CHChalkContext*)context
{
  if (mpqOutBuffer && (!memory || !context))
    free(mpqOutBuffer);
  else if (memory && context)
    [context repoolMemory:memory];
}
//end repoolMemory:forMpqOutBuffer:context:

+(void) repoolMemory:(void*)memory forMpfrOutBuffer:(void*)mpfrOutBuffer context:(CHChalkContext*)context
{
  if (mpfrOutBuffer && (!memory || !context))
    mpfr_free_str(mpfrOutBuffer);
  else if (memory && context)
    [context repoolMemory:memory];
}
//end repoolMemory:forMpfrOutBuffer:context:

-(CHComputationEntryEntity*) computationEntryForAge:(NSUInteger)age
{
  CHComputationEntryEntity* result = [self->delegate chalkContext:self computationEntryForAge:age];
  return result;
}
//end computationEntryForAge:

-(NSUInteger) ageForComputationEntry:(CHComputationEntryEntity*)computationEntry
{
  NSUInteger result = [self->delegate chalkContext:self ageForComputationEntry:computationEntry];
  return result;
}
//end ageForComputationEntry:

@end
