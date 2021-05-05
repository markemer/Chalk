//
//  CHPrimesManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 11/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHPrimesManager.h"

#import "CHUtils.h"
#import "CHAKSUtils.h"
#import "CHChalkContext.h"
#import "CHChalkErrorContext.h"
#import "NSObjectExtended.h"
#import "NSDataExtended.h"
#import "NSStringExtended.h"
#import "NSWorkspaceExtended.h"

#include <gmp.h>

#include <algorithm>
#include <vector>

typedef struct mpz_wrapper_t
{
  mpz_t z;
} mpz_wrapper_t;

struct mpz_wrapper_comparer
{
  bool operator()(const mpz_wrapper_t& o1, const mpz_wrapper_t& o2) const {
    bool result = (mpz_cmp(o1.z, o2.z)<0);
    return result;
  }//end operator()
};
//end mpz_wrapper_comparer

typedef struct sprp_base_set_t {
  mpz_t threshold;
  mpz_wrapper_t* baseSet;
  size_t baseSetLength;
} sprp_base_set_t;

sprp_base_set_t* SPRPBaseSetCreate(void)
{
  sprp_base_set_t* result = (sprp_base_set_t*)calloc(1, sizeof(sprp_base_set_t));
  if (result)
    mpz_init_set_ui(result->threshold, 0);
  return result;
}
//end SPRPBaseSetCreate()

void SPRPBaseSetRelease(sprp_base_set_t** pSprp_base_set)
{
  sprp_base_set_t* sprp_base_set = *pSprp_base_set;
  if (sprp_base_set)
  {
    mpz_clear(sprp_base_set->threshold);
    if (sprp_base_set->baseSet)
    for(size_t i = 0 ; i<sprp_base_set->baseSetLength ; ++i)
      mpz_clear(sprp_base_set->baseSet[i].z);
    free(sprp_base_set->baseSet);
    free(sprp_base_set);
  }//end if (sprp_base_set)
  if (pSprp_base_set)
    *pSprp_base_set = 0;
}
//end SPRPBaseSetCreate()

struct sprp_base_set_comparer
{
  bool operator()(const sprp_base_set_t& o1, const sprp_base_set_t& o2) const {
    bool result = (*this)(o1.threshold, o2.threshold);
    return result;
  }//end operator()
  bool operator()(const sprp_base_set_t* o1, const sprp_base_set_t* o2) const {
    bool result = (*this)(*o1, *o2);
    return result;
  }//end operator()
  bool operator()(const sprp_base_set_t* o1, mpz_srcptr o2) const {
    bool result = (*this)(o1->threshold, o2);
    return result;
  }//end operator()
  bool operator()(mpz_srcptr o1, const sprp_base_set_t* o2) const {
    bool result = (*this)(o1, o2->threshold);
    return result;
  }//end operator()
  bool operator()(mpz_srcptr o1, mpz_srcptr o2) const {
    bool result = (mpz_cmp(o1, o2)<0);
    return result;
  }//end operator()
};

BOOL SPRPBaseSetFill(sprp_base_set_t* sprp_base_set, mpz_srcptr threshold, mpz_srcptr* baseSet, size_t baseSetLength)
{
  BOOL result = NO;
  if (sprp_base_set)
  {
    mpz_set(sprp_base_set->threshold, threshold);
    if (sprp_base_set->baseSet)
    {
      for(size_t i = 0 ; i<sprp_base_set->baseSetLength ; ++i)
        mpz_clear(sprp_base_set->baseSet[i].z);
    }//end if (sprp_base_set->baseSet)
    sprp_base_set->baseSet = (mpz_wrapper_t*)reallocf(sprp_base_set->baseSet, sizeof(mpz_wrapper_t)*baseSetLength);
    sprp_base_set->baseSetLength = !sprp_base_set->baseSet ? 0 : baseSetLength;
    if (sprp_base_set->baseSet)
    {
      for(size_t i = 0 ; i<baseSetLength ; ++i)
        mpz_init_set(sprp_base_set->baseSet[i].z, baseSet[i]);
      std::sort(sprp_base_set->baseSet, sprp_base_set->baseSet+sprp_base_set->baseSetLength, mpz_wrapper_comparer());
    }//end if (sprp_base_set->baseSet)
    result = (sprp_base_set->baseSet != 0);
  }//end if (sprp_base_set)
  return result;
}
//end SPRPBaseSetCreate()

extern "C" prime_algorithm_flag_t convertToPrimeAlgorithmFlag(NSUInteger index, BOOL* outError)
{
  prime_algorithm_flag_t result = PRIMES_ALGORITHM_DEFAULT;
  BOOL error = NO;
  switch(index)
  {
    case 0:result = PRIMES_ALGORITHM_DEFAULT;break;
    case 1:result = PRIMES_ALGORITHM_CACHE;break;
    case 2:result = PRIMES_ALGORITHM_NEXTPRIME;break;
    case 3:result = PRIMES_ALGORITHM_MILLER_RABIN_PROBABILISTIC;break;
    case 4:result = PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC;break;
    case 5:result = PRIMES_ALGORITHM_AKS;break;
    default:error=YES;break;
  }//end switch(index)
  if (outError)
    *outError = error;
  return result;
}
//end convertToAlgorithmPrime()

static chalk_bool_t getBestIsPrimeResult(chalk_bool_t value1, chalk_bool_t value2)
{
  chalk_bool_t result = value1;
  if ((value1 == CHALK_BOOL_NO) || (value1 == CHALK_BOOL_YES)){
  }//do nothing
  else if (value1 == CHALK_BOOL_MAYBE)
    result = value2;//cannot be worse
  else if (value1 == CHALK_BOOL_CERTAINLY)
  {
    if ((value2 == CHALK_BOOL_NO) || (value2 == CHALK_BOOL_YES))
      result = value2;
  }//end if (value1 == CHALK_BOOL_CERTAINLY)
  return result;
}
//end getBestIsPrimeResult()

static chalk_bool_t getBestNextPrimeResult(chalk_bool_t value1, chalk_bool_t value2)
{
  chalk_bool_t result = value1;
  if (value1 == CHALK_BOOL_YES){
  }
  else if (value1 == CHALK_BOOL_NO)
    result = value2;
  else if (value1 == CHALK_BOOL_MAYBE)
  {
    if (value2 != CHALK_BOOL_NO)
      result = value2;
  }//end if (value1 == CHALK_BOOL_MAYBE)
  else if (value1 == CHALK_BOOL_CERTAINLY)
  {
    if (value2 == CHALK_BOOL_YES)
      result = value2;
  }//end if (value1 == CHALK_BOOL_CERTAINLY)
  return result;
}
//end getBestNextPrimeResult()

static chalk_bool_t getBestNthPrimeResult(chalk_bool_t value1, chalk_bool_t value2)
{
  return getBestNextPrimeResult(value1, value2);
}
//end getBestNthPrimeResult()

@interface CHPrimesManager()
-(void) loadCache;
-(void) waitCacheLoaded;
@end

@implementation CHPrimesManager

+(CHPrimesManager*) sharedManager
{
  static CHPrimesManager* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] init];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sharedManager

-(id) init
{
  if (!((self = [super init])))
    return nil;
  mpz_init_set_ui(self->cache_mpz, 0);
  mpz_init_set_ui(self->cachedPrimesCountZ, 0);
  mpz_init_set_ui(self->maxCachedPrimeZ, 0);
  self->cacheLoadSemaphore = dispatch_semaphore_create(0);
  if (!self->cacheLoadSemaphore)
  {
    [self release];
    return nil;
  }//end if (!self->cacheLoadSemaphore)
  [self loadCache];
  
  NSString* knownMillerRabinPrimalityASubsetsPath = [[NSBundle mainBundle] pathForResource:@"knownMillerRabinPrimalityASubsets" ofType:@"plist"];
  NSData* knownMillerRabinPrimalityASubsetsData = !knownMillerRabinPrimalityASubsetsPath ? nil :
    [NSData dataWithContentsOfFile:knownMillerRabinPrimalityASubsetsPath options:NSDataReadingUncached error:0];
  id knownMillerRabinPrimalityASubsetsPlist = !knownMillerRabinPrimalityASubsetsData ? nil :
    [NSPropertyListSerialization propertyListWithData:knownMillerRabinPrimalityASubsetsData options:NSPropertyListImmutable format:0 error:0];
  NSDictionary* knownMillerRabinPrimalityASubsetsDict =
    [knownMillerRabinPrimalityASubsetsPlist dynamicCastToClass:[NSDictionary class]];
  std::vector<sprp_base_set_t*> tmpBaseSets;
  std::vector<sprp_base_set_t*>* pTmpBaseSets = &tmpBaseSets;
  mpz_t _threshold;
  mpz_ptr threshold = _threshold;
  mpz_init_set_ui(threshold, 0);
  [knownMillerRabinPrimalityASubsetsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
    NSString* thresholdString = [key dynamicCastToClass:[NSString class]];
    NSArray* values = [obj dynamicCastToClass:[NSArray class]];
    if (thresholdString.length && values && values.count)
    {
      mpz_set_str(threshold, [thresholdString UTF8String], 10);
      if (mpz_sgn(threshold)>0)
      {
        std::vector<mpz_wrapper_t> tmpValues;
        std::vector<mpz_wrapper_t>* pTmpValues = &tmpValues;
        [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
          NSNumber* valueAsNumber = [obj dynamicCastToClass:[NSNumber class]];
          NSString* valueAsString = [obj dynamicCastToClass:[NSString class]];
          if (valueAsNumber && ([valueAsNumber compare:@0] == NSOrderedDescending))
          {
            NSUInteger valueUnsignedInteger = valueAsNumber.unsignedIntegerValue;
            if (valueUnsignedInteger)
            {
              mpz_wrapper_t value;
              mpz_init_set_nsui(value.z, valueUnsignedInteger);
              pTmpValues->push_back(value);
            }//end if (valueUnsignedInteger)
          }//end if (valueAsNumber && ([valueAsNumber compare:@0] == NSOrderedDescending))
          else if (valueAsString.length)
          {
            mpz_wrapper_t value;
            mpz_init_set_str(value.z, [valueAsString UTF8String], 10);
            if (mpz_sgn(value.z)>0)
              pTmpValues->push_back(value);
            else//if (mpz_sgn(*pValue)<=0)
              mpz_clear(value.z);
           }//end if (valueAsString.length)
        }];
        sprp_base_set_t* sprp_base_set = tmpValues.empty() ? 0 : SPRPBaseSetCreate();
        if (sprp_base_set && !tmpValues.empty())
        {
          std::vector<mpz_srcptr> tmpValues2;
          tmpValues2.reserve(tmpValues.size());
          for(std::vector<mpz_wrapper_t>::const_iterator it = tmpValues.begin() ; it != tmpValues.end() ; ++it)
            tmpValues2.push_back(it->z);
          if (tmpValues2.empty()){
          }
          else if (!SPRPBaseSetFill(sprp_base_set, threshold, &tmpValues2[0], tmpValues2.size()))
            SPRPBaseSetRelease(&sprp_base_set);
          else
            pTmpBaseSets->push_back(sprp_base_set);
        }//end if (sprp_base_set && !tmpValues.empty())
        for(size_t i = 0 ; i<tmpValues.size() ; ++i)
          mpz_clear(tmpValues[i].z);
      }//end if (mpz_sgn(threshold)>0)
    }//end if (thresholdString.length && values && values.count)
  }];
  mpz_clear(_threshold);
  std::sort(tmpBaseSets.begin(), tmpBaseSets.end(), sprp_base_set_comparer());
  if (!tmpBaseSets.empty())
  {
    self->sprpBaseSets = (struct sprp_base_set_t**)calloc(tmpBaseSets.size(), sizeof(struct sprp_base_set_t*));
    if (self->sprpBaseSets)
    {
      self->sprpBaseSetsLength = tmpBaseSets.size();
      memcpy(self->sprpBaseSets, &tmpBaseSets[0], tmpBaseSets.size()*sizeof(sprp_base_set_t*));
    }//end if (self->sprpBaseSets)
    else//if (!self->sprpBaseSets)
    {
      for(std::vector<sprp_base_set_t*>::iterator it = tmpBaseSets.begin() ; it != tmpBaseSets.end() ; ++it)
      {
        sprp_base_set_t* sprp_base_set = *it;
        SPRPBaseSetRelease(&sprp_base_set);
      }//end for each sprp_base_set
    }//end if (!self->sprpBaseSets)
    tmpBaseSets.clear();
  }//end if (!tmpBaseSets.empty())
  
  return self;
}
//end init

-(void) dealloc
{
  mpz_clear(self->cache_mpz);
  mpz_clear(self->cachedPrimesCountZ);
  mpz_clear(self->maxCachedPrimeZ);
  [self waitCacheLoaded];
  if (self->cacheLoadSemaphore)
    dispatch_release(self->cacheLoadSemaphore);
  for(NSUInteger i = 0 ; i<self->sprpBaseSetsLength ; ++i)
    SPRPBaseSetRelease(&self->sprpBaseSets[i]);
  free(self->sprpBaseSets);
  [super dealloc];
}
//end dealloc

-(void) loadCache
{
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async_gmp(queue, ^{
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    NSString* applicationSupport = [workspace getBestStandardPath:NSApplicationSupportDirectory domain:NSUserDomainMask defaultValue:nil];
    NSString* cachedPrimesFilePath = [[applicationSupport stringByAppendingPathComponent:[workspace applicationName]] stringByAppendingPathComponent:@"primes.mpz"];
    NSData* cachedPrimesFileData = !cachedPrimesFilePath ? nil :
      [NSData dataWithContentsOfFile:cachedPrimesFilePath options:NSDataReadingUncached error:0];
    FILE* cachedPrimesFileDataAsFile = [cachedPrimesFileData openAsFile];
    BOOL cachedLoaded = cachedPrimesFileDataAsFile && (mpz_inp_raw(self->cache_mpz, cachedPrimesFileDataAsFile) != 0);
    if (cachedPrimesFileDataAsFile)
      fclose(cachedPrimesFileDataAsFile);
    if (!cachedLoaded)
    {
      NSString* cachedPrimesCompressedFilePath = [[NSBundle mainBundle] pathForResource:@"primes.mpz" ofType:@"bz2"];
      NSData* cachedPrimesCompressedData = !cachedPrimesCompressedFilePath ? nil :
        [NSData dataWithContentsOfFile:cachedPrimesCompressedFilePath options:NSDataReadingUncached error:0];
      NSData* cachedPrimesUncompressedData = [cachedPrimesCompressedData bzip2Decompressed];
      [[NSFileManager defaultManager] createDirectoryAtPath:[cachedPrimesFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:0];
      [cachedPrimesUncompressedData writeToFile:cachedPrimesFilePath atomically:YES];
      FILE* cachedPrimesUncompressedDataAsFile = [cachedPrimesUncompressedData openAsFile];
      cachedLoaded = cachedPrimesUncompressedDataAsFile && (mpz_inp_raw(self->cache_mpz, cachedPrimesUncompressedDataAsFile) != 0);
      if (cachedPrimesUncompressedDataAsFile)
        fclose(cachedPrimesUncompressedDataAsFile);
    }//end if (!cachedLoaded)
    
    if (mpz_sgn(self->cache_mpz)>0)
    {
      NSUInteger maxMaxBitIndex = (NSUIntegerMax-1)/2;
      mp_bitcnt_t bitIndex = mpz_size(self->cache_mpz)*mp_bits_per_limb;
      while(bitIndex--)
      {
        int test = mpz_tstbit(self->cache_mpz, bitIndex);
        if (test)
        {
          if (!bitIndex || (bitIndex<=maxMaxBitIndex))
          {
            self->maxCachedPrime = !bitIndex ? 0 : 2*bitIndex+1;
            bitIndex = 0;
          }//end if (!bitIndex || (bitIndex<=maxMaxBitIndex))
        }//end if (test)
      }//end while(bitIndex--)
      mpz_set_nsui(self->maxCachedPrimeZ, self->maxCachedPrime);
      self->cachedPrimesCount = mpz_popcount(self->cache_mpz);
      mpz_set_nsui(self->cachedPrimesCountZ, self->cachedPrimesCount);
    }//end if (mpz_sgn(self->cache_mpz)>0)
    dispatch_semaphore_signal(self->cacheLoadSemaphore);
  });
}
//end loadCache

-(void) waitCacheLoaded
{
  if (self->cacheLoadSemaphore)
  {
    dispatch_semaphore_wait(self->cacheLoadSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_release(self->cacheLoadSemaphore);
    self->cacheLoadSemaphore = 0;
  }//end if (self->cacheLoadSemaphore)
}
//end waitCacheLoaded

-(mpz_srcptr) maxCachedPrime
{
  return self->maxCachedPrimeZ;
}
//end maxCachedPrime

-(chalk_bool_t) isMersennePrime:(mpz_srcptr)op
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  mpz_t tmp;
  mpz_init_set(tmp, op);
  mpz_abs(tmp, tmp);
  mpz_add_ui(tmp, tmp, 1);
  const mp_bitcnt_t maxBitCount = (mp_bitcnt_t)(-1);
  mp_bitcnt_t firstBit = mpz_scan1(tmp, 0);
  mp_bitcnt_t nextBit = (firstBit == maxBitCount) ? maxBitCount : mpz_scan1(tmp, firstBit+1);
  BOOL isPowerOfTwo = (firstBit != maxBitCount) && (nextBit == maxBitCount);
  if (!isPowerOfTwo)
    result = CHALK_BOOL_NO;
  else if (firstBit <= NSUIntegerMax)
  {
    static NSSet* mersennePrimesPowersOfTwo = nil;
    if (!mersennePrimesPowersOfTwo)
    {
      @synchronized(self)
      {
        if (!mersennePrimesPowersOfTwo)
        {
          NSString* path = [[NSBundle mainBundle] pathForResource:@"knownMersennePrimesPowersOfTwo" ofType:@"plist"];
          NSData* data = !path ? nil : [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:0];
          id plist = !data ? nil : [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:0 error:0];
          NSArray* list = [plist dynamicCastToClass:[NSArray class]];
          mersennePrimesPowersOfTwo = !list ? [[NSSet alloc] init] : [[NSSet alloc] initWithArray:list];
        }//end if (!mersennePrimesPowersOfTwo)
      }//end @synchronized(self)
    }//end if (!mersennePrimesPowersOfTwo)
    result =
      [mersennePrimesPowersOfTwo containsObject:@(firstBit)] ? CHALK_BOOL_YES :
      (firstBit <= 43112609U) ? CHALK_BOOL_NO ://last certain power of two of max mersenne prime (beware of undiscovered numbers yet)
      CHALK_BOOL_MAYBE;
  }//end if (firstBit <= NSUIntegerMax)
  mpz_clear(tmp);
  return result;
}
//end isMersennePrime:

-(chalk_bool_t) isPrime:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  int sgn = mpz_sgn(op);
  mpz_srcptr opAbs = op;
  mpz_t tmp;
  if (sgn<0)
  {
    mpz_init_set(tmp, op);
    mpz_neg(tmp, tmp);
    opAbs = tmp;
  }//end if (sgn<0)
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT)))
  {
    if ([self isMersennePrime:opAbs])
      result = CHALK_BOOL_YES;
  }
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      ((algorithmFlags & PRIMES_ALGORITHM_CACHE) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
    result = getBestIsPrimeResult(result, [self isPrimeWithCache:opAbs context:context]);
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      (algorithmFlags & PRIMES_ALGORITHM_NEXTPRIME))
    result = getBestIsPrimeResult(result, [self isPrimeWithNextPrime:opAbs context:context]);
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT)))
  {
    mpz_srcptr maxMillerRabbinDeterministicThreshold = !self->sprpBaseSetsLength ? 0 :
      self->sprpBaseSets[self->sprpBaseSetsLength-1]->threshold;
    if (maxMillerRabbinDeterministicThreshold && (mpz_cmp(opAbs, maxMillerRabbinDeterministicThreshold)<0))
      result = getBestIsPrimeResult(result, [self isPrimeWithMillerRabinDeterministic:opAbs context:context]);
  }
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      ((algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_PROBABILISTIC) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
    result = getBestIsPrimeResult(result, [self isPrimeWithMillerRabinProbabilistic:opAbs context:context]);
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      (algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC))
    result = getBestIsPrimeResult(result, [self isPrimeWithMillerRabinDeterministic:opAbs context:context]);
  if (((result != CHALK_BOOL_YES) && (result != CHALK_BOOL_NO)) &&
      (algorithmFlags & PRIMES_ALGORITHM_AKS))
    result = getBestIsPrimeResult(result, [self isPrimeWithAKS:opAbs context:context]);
  if (sgn<0)
    mpz_clear(tmp);
  return result;
}
//end isPrime:withAlgorithms:context:

-(chalk_bool_t) isPrimeWithCache:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  int sgn = mpz_sgn(op);
  mpz_srcptr opAbs = op;
  mpz_t tmp;
  if (sgn<0)
  {
    mpz_init_set(tmp, op);
    mpz_neg(tmp, tmp);
    opAbs = tmp;
  }//end if (sgn<0)
  if (!sgn)
    result = CHALK_BOOL_NO;
  else if (!mpz_cmp_ui(opAbs, 1))
    result = CHALK_BOOL_NO;
  else if (!mpz_cmp_ui(opAbs, 2))
    result = CHALK_BOOL_YES;
  else if (mpz_even_p(opAbs))
    result = CHALK_BOOL_NO;
  else//if (mpz_odd_p(opAbs))
  {
    [self waitCacheLoaded];
    if (mpz_cmp(opAbs, self->maxCachedPrimeZ)<=0)
    {
      mp_bitcnt_t bit = (mpz_get_nsui(opAbs)-1)/2;
      int test = mpz_tstbit(self->cache_mpz, bit);
      result = !test ? CHALK_BOOL_NO : CHALK_BOOL_YES;
    }//end if (mpz_cmp(opAbs, self->maxCachedPrimeZ)<=0)
  }//end if (mpz_odd_p(opAbs))
  if (sgn<0)
    mpz_clear(tmp);
  return result;
}
//end isPrimeWithCache:context:

-(chalk_bool_t) isPrimeWithNextPrime:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  int sgn = mpz_sgn(op);
  mpz_srcptr opAbs = op;
  mpz_t tmp;
  if (sgn<0)
  {
    mpz_init_set(tmp, op);
    mpz_neg(tmp, tmp);
    opAbs = tmp;
  }//end if (sgn<0)
  mpz_t prev;
  mpz_init_set(prev, opAbs);
  mpz_sub_ui(prev, prev, 1);
  mpz_nextprime(prev, prev);
  result = !mpz_cmp(prev, opAbs) ? CHALK_BOOL_CERTAINLY : CHALK_BOOL_NO;
  mpz_clear(prev);
  if (sgn<0)
    mpz_clear(tmp);
  return result;
}
//end isPrimeWithNextPrime:context:

-(chalk_bool_t) isPrimeWithMillerRabinProbabilistic:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  int sgn = mpz_sgn(op);
  mpz_srcptr opAbs = op;
  mpz_t tmp;
  if (sgn<0)
  {
    mpz_init_set(tmp, op);
    mpz_neg(tmp, tmp);
    opAbs = tmp;
  }//end if (sgn<0)
  int r = mpz_probab_prime_p(opAbs, 25);
  result = (r == 0) ? CHALK_BOOL_NO :
           (r == 1) ? CHALK_BOOL_CERTAINLY :
           (r == 2) ? CHALK_BOOL_YES :
           CHALK_BOOL_MAYBE;
  if (sgn<0)
    mpz_clear(tmp);
  return result;
}
//end isPrimeWithMillerRabinProbabilistic:context:

-(chalk_bool_t) isPrimeWithMillerRabinDeterministic:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  int sgn = mpz_sgn(op);
  mpz_srcptr opAbs = op;
  mpz_t tmp;
  if (sgn<0)
  {
    mpz_init_set(tmp, op);
    mpz_neg(tmp, tmp);
    opAbs = tmp;
  }//end if (sgn<0)
  if (!mpz_cmp_ui(opAbs, 0))
    result = CHALK_BOOL_NO;
  else if (!mpz_cmp_ui(opAbs, 1))
    result = CHALK_BOOL_NO;
  else if (!mpz_cmp_ui(opAbs, 2))
    result = CHALK_BOOL_YES;
  else if (mpz_even_p(opAbs))
    result = CHALK_BOOL_NO;
  else//if (opAbs > 1) and (opAbs is odd)
  {
    mpz_t d;
    mpz_init_set(d, opAbs);
    mpz_sub_ui(d, d, 1);
    const mp_bitcnt_t maxBitCount = (mp_bitcnt_t)(-1);
    mp_bitcnt_t s = mpz_scan1(d, 0);
    if (s < maxBitCount)
    {
      mpz_tdiv_q_2exp(d, d, s);
      
      sprp_base_set_t** sprp_base_set_it = std::lower_bound(self->sprpBaseSets, self->sprpBaseSets+self->sprpBaseSetsLength, opAbs, sprp_base_set_comparer());
      sprp_base_set_t* sprp_base_set =
        (sprp_base_set_it == self->sprpBaseSets+self->sprpBaseSetsLength) ? 0 :
        (mpz_cmp(opAbs, (*sprp_base_set_it)->threshold) < 0) ? *sprp_base_set_it :
        (sprp_base_set_it+1 < self->sprpBaseSets+self->sprpBaseSetsLength) ? *(sprp_base_set_it+1) :
        0;

      mpz_t maxA;
      if (!sprp_base_set)
      {
        chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
        mpfr_t mp;
        mpfr_init2(mp, mpz_size(opAbs)*mp_bits_per_limb);
        mpfr_set_z(mp, opAbs, MPFR_RNDU);
        mpfr_log(mp, mp, MPFR_RNDU);
        mpfr_sqr(mp, mp, MPFR_RNDU);
        mpfr_mul_2exp(mp, mp, 1, MPFR_RNDU);
        mpfr_add_ui(mp, mp, 1, MPFR_RNDN);
        mpfr_floor(mp, mp);
        BOOL minIsN = (mpfr_cmp_z(mp, opAbs) >= 0);
        if (minIsN)
          mpz_init_set(maxA, opAbs);
        else//if (!minIsN)
        {
          mpz_init2(maxA, mpfr_get_prec(mp));
          mpfr_get_z(maxA, mp, MPFR_RNDN);
        }//end if (!minIsN)
        mpz_sub_ui(maxA, maxA, 1);
        mpfr_clear(mp);
        chalkGmpFlagsRestore(oldFlags);
      }//end if (!sprp_base_set)
      mpz_t one;
      mpz_init_set_si(one, 1);
      mpz_t minusOne;
      mpz_init_set_si(minusOne, -1);
      mpz_t twoPowRTimesD;
      mpz_init(twoPowRTimesD);
      mpz_t tmp;
      mpz_init(tmp);
      BOOL composite = NO;
      BOOL sprp_base_set_error = NO;
      CHChalkErrorContext* errorContext = context.errorContext;
      if (sprp_base_set)
      {
        for(size_t i = 0 ; !sprp_base_set_error && !composite && (i<sprp_base_set->baseSetLength) && (!errorContext || !errorContext.hasError) ; ++i)
        {
          mpz_srcptr a = sprp_base_set->baseSet[i].z;
          sprp_base_set_error |= !a;
          mpz_set(twoPowRTimesD, d);
          BOOL allTestsPassed = YES;
          for(mp_bitcnt_t r = 0 ; !sprp_base_set_error && allTestsPassed && (r<s) && (!errorContext || !errorContext.hasError) ; ++r)
          {
            mpz_powm(tmp, a, twoPowRTimesD, opAbs);
            if (!r)
              allTestsPassed &= !mpz_congruent_p(tmp, one, opAbs);
            if (allTestsPassed)
              allTestsPassed &= !mpz_congruent_p(tmp, minusOne, opAbs);
            if (allTestsPassed)
              mpz_mul_2exp(twoPowRTimesD, twoPowRTimesD, 1);
          }//end for each r
          composite |= allTestsPassed;
        }//end for each A
      }//end if (sprp_base_set)
      if (!sprp_base_set || sprp_base_set_error)
      {
        mpz_t a;
        mpz_init_set_ui(a, 2);
        while(!composite && (mpz_cmp(a, maxA) <= 0) && (!errorContext || !errorContext.hasError))
        {
          mpz_set(twoPowRTimesD, d);
          BOOL allTestsPassed = YES;
          for(mp_bitcnt_t r = 0 ; allTestsPassed && (r<s) && (!errorContext || !errorContext.hasError) ; ++r)
          {
            mpz_powm(tmp, a, twoPowRTimesD, opAbs);
            if (!r)
              allTestsPassed &= !mpz_congruent_p(tmp, one, opAbs);
            if (allTestsPassed)
              allTestsPassed &= !mpz_congruent_p(tmp, minusOne, opAbs);
            if (allTestsPassed)
              mpz_mul_2exp(twoPowRTimesD, twoPowRTimesD, 1);
          }//end for each r
          composite |= allTestsPassed;
          if (!composite)
            mpz_add_ui(a, a, 1);
        }//end while(!composite && (mpz_cmp(a, maxA) <= 0) && (!errorContext || !errorContext.hasError))
        mpz_clear(a);
      }//end if (!sprp_base_set || sprp_base_set_error)
      if (composite)
        result = CHALK_BOOL_NO;
      else
        result = CHALK_BOOL_YES;
      if (!sprp_base_set)
        mpz_clear(maxA);
      mpz_clear(one);
      mpz_clear(minusOne);
      mpz_clear(twoPowRTimesD);
      mpz_clear(tmp);
    }//end if (s < maxBitCount)
    mpz_clear(d);
  }//end if (opAbs > 1) and (op is odd)
  if (sgn<0)
    mpz_clear(tmp);
  return result;
}
//end isPrimeWithMillerRabinDeterministic:context:

-(chalk_bool_t) isPrimeWithAKS:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = aks_isPrime(op);
  return result;
}
//end isPrimeWithAKS:context:

-(chalk_bool_t) nextPrime:(mpz_ptr)rop op:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  if ((result != CHALK_BOOL_YES) &&
      ((algorithmFlags & PRIMES_ALGORITHM_CACHE) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
    result = getBestNextPrimeResult(result, [self nextPrimeWithCache:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      ((algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
  {
    mpz_srcptr maxMillerRabbinDeterministicThreshold = !self->sprpBaseSetsLength ? 0 :
      self->sprpBaseSets[self->sprpBaseSetsLength-1]->threshold;
    if (maxMillerRabbinDeterministicThreshold && (mpz_cmp(op, maxMillerRabbinDeterministicThreshold)<0))
      result = getBestNextPrimeResult(result, [self nextPrimeWithMillerRabinDeterministic:rop op:op context:context]);
  }
  if ((result != CHALK_BOOL_YES) &&
      ((algorithmFlags & PRIMES_ALGORITHM_NEXTPRIME) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
    result = getBestNextPrimeResult(result, [self nextPrimeWithNextPrime:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_PROBABILISTIC))
    result = getBestNextPrimeResult(result, [self nextPrimeWithMillerRabinProbabilistic:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC))
    result = getBestNextPrimeResult(result, [self nextPrimeWithMillerRabinDeterministic:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_AKS))
    result = getBestNextPrimeResult(result, [self nextPrimeWithAKS:rop op:op context:context]);
  return result;
}
//end nextPrime:op:withAlgorithm:context:

-(chalk_bool_t) nextPrimeWithCache:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  else if (!mpz_cmp_ui(op, 1))
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (!mpz_cmp_ui(op, 1))
  else if (!mpz_cmp_ui(op, 2))
  {
    mpz_set_ui(rop, 3);
    result = CHALK_BOOL_YES;
  }//end if (!mpz_cmp_ui(op, 2))
  else//if (op>2)
  {
    [self waitCacheLoaded];
    if (mpz_cmp(op, self->maxCachedPrimeZ)<0)
    {
      BOOL isOdd = (mpz_odd_p(op) != 0);
      mp_bitcnt_t bit = (mpz_get_nsui(op)-(isOdd ? 1 : 0))/2;
      int test = mpz_tstbit(self->cache_mpz, bit);
      if (test && !isOdd)
      {
        mpz_set_nsui(rop, bit);
        mpz_mul_2exp(rop, rop, 1);
        mpz_add_ui(rop, rop, 1);
        result = CHALK_BOOL_YES;
      }//end if (test && !isOdd)
      else//if (!test || isOdd)
      {
        bit = mpz_scan1(self->cache_mpz, bit+((test && isOdd) ? 1 : 0));
        const mp_bitcnt_t maxBitCount = (mp_bitcnt_t)(-1);
        if (bit != maxBitCount)//that was not the largest btcnt
        {
          mpz_set_nsui(rop, bit);
          mpz_mul_2exp(rop, rop, 1);
          mpz_add_ui(rop, rop, 1);
          result = CHALK_BOOL_YES;
        }//end if (bit != maxBitCount)
      }//end if (!test || isOdd)
    }//end if (mpz_cmp(op, self->maxCachedPrimeZ)<0)
    else
      result = CHALK_BOOL_MAYBE;
  }//end if (op>2)
  return result;
}
//end nextPrimeWithCache:op:context:

-(chalk_bool_t) nextPrimeWithNextPrime:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  else//if (op>0)
  {
    mpz_nextprime(rop, op);
    result = CHALK_BOOL_CERTAINLY;
  }//end if (op>0)
  return result;
}
//end nextPrimeWithNextPrime:op:

-(chalk_bool_t) nextPrimeWithMillerRabinProbabilistic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  else//if (op>0)
  {
    mpz_set(rop, op);
    mpz_add_ui(rop, rop, mpz_even_p(rop) ? 1 : 2);
    CHChalkErrorContext* errorContext = context.errorContext;
    chalk_bool_t r = CHALK_BOOL_NO;
    while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    {
      r = [self isPrimeWithMillerRabinProbabilistic:rop context:context];
      if (r == CHALK_BOOL_NO)
        mpz_add_ui(rop, rop, 2);
    }//end while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    result = r;
  }//end if (op>0)
  return result;
}
//end nextPrimeWithMillerRabinProbabilistic:op:context:

-(chalk_bool_t) nextPrimeWithMillerRabinDeterministic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  else//if (op>0)
  {
    mpz_set(rop, op);
    mpz_add_ui(rop, rop, mpz_even_p(rop) ? 1 : 2);
    CHChalkErrorContext* errorContext = context.errorContext;
    chalk_bool_t r = CHALK_BOOL_NO;
    while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    {
      r = [self isPrimeWithMillerRabinDeterministic:rop context:context];
      if (r == CHALK_BOOL_NO)
        mpz_add_ui(rop, rop, 2);
    }//end while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    result = r;
  }//end if (op>0)
  return result;
}
//end nextPrimeWithMillerRabinDeterministic:op:context:

-(chalk_bool_t) nextPrimeWithAKS:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 2);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  else//if (op>0)
  {
    mpz_set(rop, op);
    mpz_add_ui(rop, rop, mpz_even_p(rop) ? 1 : 2);
    CHChalkErrorContext* errorContext = context.errorContext;
    chalk_bool_t r = CHALK_BOOL_NO;
    while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    {
      r = [self isPrimeWithAKS:rop context:context];
      if (r == CHALK_BOOL_NO)
        mpz_add_ui(rop, rop, 2);
    }//end while((r == CHALK_BOOL_NO) && (!errorContext || !errorContext.hasError))
    result = r;
  }//end if (op>0)
  return result;
}
//end nextPrimeWithAKS:op:context:

-(chalk_bool_t) nthPrime:(mpz_ptr)rop op:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)<=0)
  {
    mpz_set_ui(rop, 0);
    result = CHALK_BOOL_YES;
  }//end if (sgn<=0)
  if ((result != CHALK_BOOL_YES) &&
      ((algorithmFlags & PRIMES_ALGORITHM_CACHE) ||
       (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT))))
  {
    result = [self nthPrimeWithCache:rop op:op context:context];
    if ((result != CHALK_BOOL_YES) &&
        (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT)))
    {
      CHChalkErrorContext* errorContext = context.errorContext;
      result = CHALK_BOOL_YES;
      mpz_t count2;
      mpz_init_set(count2, op);
      mpz_sub(count2, count2, self->cachedPrimesCountZ);
      mpz_set(rop, self->maxCachedPrimeZ);
      mpz_add_ui(rop, rop, 1);
      while((result != CHALK_BOOL_NO) && (mpz_sgn(count2)>0) && (!errorContext || !errorContext.hasError))
      {
        result = MIN(result, [self nextPrime:rop op:rop withAlgorithms:algorithmFlags context:context]);
        mpz_sub_ui(count2, count2, 1);
      }//end while((result != CHALK_BOOL_NO) && (mpz_sgn(count2)>0) && (!errorContext || !errorContext.hasError))
      if (mpz_sgn(count2) != 0)
        result = CHALK_BOOL_NO;
      mpz_clear(count2);
    }//end ((result != CHALK_BOOL_YES) && (!algorithmFlags || (algorithmFlags & PRIMES_ALGORITHM_DEFAULT)))
  }
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_NEXTPRIME))
    result = getBestNthPrimeResult(result, [self nthPrimeWithNextPrime:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_PROBABILISTIC))
    result = getBestNthPrimeResult(result, [self nthPrimeWithMillerRabinProbabilistic:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC))
    result = getBestNthPrimeResult(result, [self nthPrimeWithMillerRabinDeterministic:rop op:op context:context]);
  if ((result != CHALK_BOOL_YES) &&
      (algorithmFlags & PRIMES_ALGORITHM_AKS))
    result = getBestNthPrimeResult(result, [self nthPrimeWithAKS:rop op:op context:context]);
  return result;
}
//end nextPrime:op:withAlgorithm:context:

-(chalk_bool_t) nthPrimeWithCache:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)>0)
  {
    if (!mpz_cmp_ui(op, 1))
    {
      mpz_set_ui(rop, 2);
      result = CHALK_BOOL_YES;
    }//end if (!mpz_cmp_ui(op, 1))
    else//if (op>1)
    {
      [self waitCacheLoaded];
      if (mpz_cmp(op, self->cachedPrimesCountZ)<=0)
      {
        mpz_t count;
        mpz_init_set(count, op);
        mpz_set_ui(rop, 2);
        mpz_sub_ui(count, count, 1);
        const mp_bitcnt_t maxBitCount = (mp_bitcnt_t)(-1);
        mp_bitcnt_t bit = 0;
        while ((result != CHALK_BOOL_YES) && (bit != maxBitCount))
        {
          bit = mpz_scan1(self->cache_mpz, bit+1);
          if (bit != maxBitCount)
            mpz_sub_ui(count, count, 1);
          if (!mpz_sgn(count))
          {
            mpz_set_nsui(rop, bit);
            mpz_mul_2exp(rop, rop, 1);
            mpz_add_ui(rop, rop, 1);
            result = CHALK_BOOL_YES;
          }//end if (mpz_sgn(count) == 0)
        }//end while (!done && (bit != maxBitCount))
      }//end if (mpz_cmp(op, self->cachedPrimesCountZ)<=0)
    }//end if (op>1)
  }//end if (mpz_sgn(op)>0)
  return result;
}
//end nthPrimeWithCache:op:context:

-(chalk_bool_t) nthPrimeWithNextPrime:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)>0)
  {
    CHChalkErrorContext* errorContext = context.errorContext;
    mpz_t count;
    mpz_init_set(count, op);
    mpz_set_ui(rop, 2);
    mpz_sub_ui(count, count, 1);
    while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    {
      mpz_nextprime(rop, rop);
      mpz_sub_ui(count, count, 1);
    }//end while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    result = !mpz_sgn(count) ? CHALK_BOOL_CERTAINLY : CHALK_BOOL_NO;
    mpz_clear(count);
  }//end if (mpz_sgn(op)>0)
  return result;
}
//end nthPrimeWithNextPrime:op:context:

-(chalk_bool_t) nthPrimeWithMillerRabinProbabilistic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)>0)
  {
    CHChalkErrorContext* errorContext = context.errorContext;
    mpz_t count;
    mpz_init_set(count, op);
    mpz_set_ui(rop, 2);
    mpz_sub_ui(count, count, 1);
    chalk_bool_t r = CHALK_BOOL_YES;
    while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    {
      r = MIN(r, [self nextPrimeWithMillerRabinProbabilistic:rop op:rop context:context]);
      mpz_sub_ui(count, count, 1);
    }//end while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    result = !mpz_sgn(count) ? r : CHALK_BOOL_NO;
    mpz_clear(count);
  }//end if (mpz_sgn(op)>0)
  return result;
}
//end nthPrimeWithMillerRabinProbabilistic:op:context:

-(chalk_bool_t) nthPrimeWithMillerRabinDeterministic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)>0)
  {
    CHChalkErrorContext* errorContext = context.errorContext;
    mpz_t count;
    mpz_init_set(count, op);
    mpz_set_ui(rop, 2);
    mpz_sub_ui(count, count, 1);
    chalk_bool_t r = CHALK_BOOL_YES;
    while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    {
      r = MIN(r, [self nextPrimeWithMillerRabinDeterministic:rop op:rop context:context]);
      mpz_sub_ui(count, count, 1);
    }//end while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    result = !mpz_sgn(count) ? r : CHALK_BOOL_NO;
    mpz_clear(count);
  }//end if (mpz_sgn(op)>0)
  return result;
}
//end nthPrimeWithMillerRabinDeterministic:op:context:

-(chalk_bool_t) nthPrimeWithAKS:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_NO;
  if (mpz_sgn(op)>0)
  {
    CHChalkErrorContext* errorContext = context.errorContext;
    mpz_t count;
    mpz_init_set(count, op);
    mpz_set_ui(rop, 2);
    mpz_sub_ui(count, count, 1);
    chalk_bool_t r = CHALK_BOOL_YES;
    while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    {
      r = MIN(r, [self nextPrimeWithAKS:rop op:rop context:context]);
      mpz_sub_ui(count, count, 1);
    }//end while((mpz_sgn(count)>0) && (!errorContext || !errorContext.hasError))
    result = !mpz_sgn(count) ? r : CHALK_BOOL_NO;
    mpz_clear(count);
  }//end if (mpz_sgn(op)>0)
  return result;
}
//end nextPrimeWithAKS:op:context:

@end
