//
//  CHPrimesManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 11/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"
#include <gmp.h>

typedef NS_OPTIONS(NSUInteger,prime_algorithm_flag_t) {
  PRIMES_ALGORITHM_DEFAULT = 0,
  PRIMES_ALGORITHM_CACHE = 1<<1,
  PRIMES_ALGORITHM_NEXTPRIME = 1<<2,
  PRIMES_ALGORITHM_MILLER_RABIN_PROBABILISTIC = 1<<3,
  PRIMES_ALGORITHM_MILLER_RABIN_DETERMINISTIC = 1<<4,
  PRIMES_ALGORITHM_AKS = 1<<5
};//end prime_algorithm_flag_t

#ifdef __cplusplus
extern "C" {
#endif
struct sprp_base_set_t;
prime_algorithm_flag_t convertToPrimeAlgorithmFlag(NSUInteger index, BOOL* outError);
#ifdef __cplusplus
}
#endif

@interface CHPrimesManager : NSObject {
  dispatch_semaphore_t cacheLoadSemaphore;
  mpz_t cache_mpz;
  NSUInteger cachedPrimesCount;
  mpz_t cachedPrimesCountZ;
  NSUInteger maxCachedPrime;
  mpz_t maxCachedPrimeZ;
  struct sprp_base_set_t** sprpBaseSets;
  size_t sprpBaseSetsLength;
}

+(CHPrimesManager*) sharedManager;

-(mpz_srcptr)   maxCachedPrime;
-(chalk_bool_t) isMersennePrime:(mpz_srcptr)op;

-(chalk_bool_t) isPrime:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context;
-(chalk_bool_t) isPrimeWithCache:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) isPrimeWithNextPrime:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) isPrimeWithMillerRabinProbabilistic:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) isPrimeWithMillerRabinDeterministic:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) isPrimeWithAKS:(mpz_srcptr)op context:(CHChalkContext*)context;

-(chalk_bool_t) nextPrime:(mpz_ptr)rop op:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context;
-(chalk_bool_t) nextPrimeWithCache:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nextPrimeWithNextPrime:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nextPrimeWithMillerRabinProbabilistic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nextPrimeWithMillerRabinDeterministic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nextPrimeWithAKS:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;

-(chalk_bool_t) nthPrime:(mpz_ptr)rop op:(mpz_srcptr)op withAlgorithms:(prime_algorithm_flag_t)algorithmFlags context:(CHChalkContext*)context;
-(chalk_bool_t) nthPrimeWithCache:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nthPrimeWithNextPrime:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nthPrimeWithMillerRabinProbabilistic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nthPrimeWithMillerRabinDeterministic:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;
-(chalk_bool_t) nthPrimeWithAKS:(mpz_ptr)rop op:(mpz_srcptr)op context:(CHChalkContext*)context;


@end
