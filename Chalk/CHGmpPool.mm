//
//  CHGmpPool.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/06/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHGmpPool.h"

#include <vector>

static NSMutableArray* pools = nil;

@implementation CHGmpPool

-(instancetype) init {return [self initWithCapacity:0];}

-(instancetype) initWithCapacity:(NSUInteger)aCapacity
{
  if (!((self = [super init])))
    return nil;
  self->capacity = aCapacity;
  std::vector<__mpz_struct>* _mpzVector = new(std::nothrow) std::vector<__mpz_struct>;
  std::vector<__mpq_struct>* _mpqVector = new(std::nothrow) std::vector<__mpq_struct>;
  std::vector<__mpfr_struct>* _mpfrVector = new(std::nothrow) std::vector<__mpfr_struct>;
  std::vector<__mpfi_struct>* _mpfiVector = new(std::nothrow) std::vector<__mpfi_struct>;
  std::vector<__mpfir_struct>* _mpfirVector = new(std::nothrow) std::vector<__mpfir_struct>;
  std::vector<arb_struct>* _arbVector = new(std::nothrow) std::vector<arb_struct>;
  if (_mpzVector)
    _mpzVector->reserve(MIN(1024U, self->capacity));
  if (_mpqVector)
    _mpqVector->reserve(MIN(1024U, self->capacity));
  if (_mpfrVector)
    _mpfrVector->reserve(MIN(1024U, self->capacity));
  if (_mpfiVector)
    _mpfiVector->reserve(MIN(1024U, self->capacity));
  if (_mpfirVector)
    _mpfirVector->reserve(MIN(1024U, self->capacity));
  if (_arbVector)
    _arbVector->reserve(MIN(1024U, self->capacity));
  self->mpzVector = _mpzVector;
  self->mpqVector = _mpqVector;
  self->mpfrVector = _mpfrVector;
  self->mpfiVector = _mpfiVector;
  self->mpfirVector = _mpfirVector;
  self->arbVector = _arbVector;
  self->mpzSpinlock = OS_SPINLOCK_INIT;
  self->mpqSpinlock = OS_SPINLOCK_INIT;
  self->mpfrSpinlock = OS_SPINLOCK_INIT;
  self->mpfiSpinlock = OS_SPINLOCK_INIT;
  self->mpfirSpinlock = OS_SPINLOCK_INIT;
  self->arbSpinlock = OS_SPINLOCK_INIT;
  return self;
}
//end init

-(void) dealloc
{
  std::vector<__mpz_struct>* _mpzVector = reinterpret_cast<std::vector<__mpz_struct>*>(self->mpzVector);
  std::vector<__mpq_struct>* _mpqVector = reinterpret_cast<std::vector<__mpq_struct>*>(self->mpqVector);
  std::vector<__mpfr_struct>* _mpfrVector = reinterpret_cast<std::vector<__mpfr_struct>*>(self->mpfrVector);
  std::vector<__mpfi_struct>* _mpfiVector = reinterpret_cast<std::vector<__mpfi_struct>*>(self->mpfiVector);
  std::vector<__mpfir_struct>* _mpfirVector = reinterpret_cast<std::vector<__mpfir_struct>*>(self->mpfirVector);
  std::vector<arb_struct>* _arbVector = reinterpret_cast<std::vector<arb_struct>*>(self->arbVector);
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_apply(!_mpzVector ? 0 : _mpzVector->size(), queue, ^(size_t i) {
    mpz_clear(&(*_mpzVector)[i]);
  });
  dispatch_apply(!_mpqVector ? 0 : _mpqVector->size(), queue, ^(size_t i) {
    mpq_clear(&(*_mpqVector)[i]);
  });
  dispatch_apply(!_mpfrVector ? 0 : _mpfrVector->size(), queue, ^(size_t i) {
    mpfr_clear(&(*_mpfrVector)[i]);
  });
  dispatch_apply(!_mpfiVector ? 0 : _mpfiVector->size(), queue, ^(size_t i) {
    mpfi_clear(&(*_mpfiVector)[i]);
  });
  dispatch_apply(!_mpfirVector ? 0 : _mpfirVector->size(), queue, ^(size_t i) {
    mpfir_clear(&(*_mpfirVector)[i]);
  });
  dispatch_apply(!_arbVector ? 0 : _arbVector->size(), queue, ^(size_t i) {
    arb_clear(&(*_arbVector)[i]);
  });
  delete _mpzVector;
  delete _mpqVector;
  delete _mpfrVector;
  delete _mpfiVector;
  delete _mpfirVector;
  delete _arbVector;
  [super dealloc];
}
//end dealloc

-(__mpz_struct) depoolMpz
{
  __mpz_struct result;
  BOOL takenInPool = NO;
  std::vector<__mpz_struct>* pool = reinterpret_cast<std::vector<__mpz_struct>*>(self->mpzVector);
  if (pool)
  {
    OSSpinLockLock(&self->mpzSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      pool->pop_back();
      takenInPool = YES;
      //assert((result._mp_d != 0) && (result._mp_alloc != 0));
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->mpzSpinlock);
  }//end if (pool)
  if (!takenInPool)
    mpz_init(&result);
  OSAtomicAdd64(-1, &self->mpzCounter);
  return result;
}
//end depoolMpz:

-(void) repoolMpz:(mpz_ptr)value
{
  if (value)
  {
    //assert(value->_mp_alloc != 0);
    BOOL repooled = NO;
    std::vector<__mpz_struct>* pool = reinterpret_cast<std::vector<__mpz_struct>*>(self->mpzVector);
    if (pool)
    {
      OSSpinLockLock(&self->mpzSpinlock);
      if (pool->size() < self->capacity)
      {
        //assert((value->_mp_d != 0) && (value->_mp_alloc != 0));
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->mpzSpinlock);
    }//end if (pool)
    if (!repooled)
      mpz_clear(value);
    OSAtomicAdd64(1, &self->mpzCounter);
  }//end if (value)
}
//end repoolMpz:

-(__mpq_struct) depoolMpq
{
  __mpq_struct result = {0};
  BOOL takenInPool = NO;
  std::vector<__mpq_struct>* pool = reinterpret_cast<std::vector<__mpq_struct>*>(self->mpqVector);
  if (pool)
  {
    OSSpinLockLock(&self->mpqSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      pool->pop_back();
      takenInPool = YES;
      //assert((result._mp_num._mp_d != 0) && (result._mp_num._mp_alloc != 0));
      //assert((result._mp_den._mp_d != 0) && (result._mp_den._mp_alloc != 0));
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->mpqSpinlock);
  }//end if (pool)
  if (!takenInPool)
    mpq_init(&result);
  OSAtomicAdd64(-1, &self->mpqCounter);
  return result;
}
//end depoolMpq:

-(void) repoolMpq:(mpq_ptr)value
{
  if (value)
  {
    BOOL repooled = NO;
    std::vector<__mpq_struct>* pool = reinterpret_cast<std::vector<__mpq_struct>*>(self->mpqVector);
    if (pool)
    {
      OSSpinLockLock(&self->mpqSpinlock);
      if (pool->size() < self->capacity)
      {
        //assert((value->_mp_num._mp_d != 0) && (value->_mp_num._mp_alloc != 0));
        //assert((value->_mp_den._mp_d != 0) && (value->_mp_den._mp_alloc != 0));
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->mpqSpinlock);
    }//end if (pool)
    if (!repooled)
      mpq_clear(value);
    OSAtomicAdd64(1, &self->mpqCounter);
  }//end if (value)
}
//end repoolMpq:

-(__mpfr_struct) depoolMpfr:(mpfr_prec_t)prec
{
  __mpfr_struct result = {0};
  BOOL takenInPool = NO;
  std::vector<__mpfr_struct>* pool = reinterpret_cast<std::vector<__mpfr_struct>*>(self->mpfrVector);
  if (pool)
  {
    OSSpinLockLock(&self->mpfrSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      mpfr_set_prec(&result, prec);
      pool->pop_back();
      takenInPool = YES;
      //assert(result._mpfr_d != 0);
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->mpfrSpinlock);
  }//end if (pool)
  if (!takenInPool)
    mpfr_init2(&result, prec);
  OSAtomicAdd64(-1, &self->mpfrCounter);
  return result;
}
//end depoolMpfr:

-(void) repoolMpfr:(mpfr_ptr)value
{
  if (value)
  {
    BOOL repooled = NO;
    std::vector<__mpfr_struct>* pool = reinterpret_cast<std::vector<__mpfr_struct>*>(self->mpfrVector);
    if (pool)
    {
      OSSpinLockLock(&self->mpfrSpinlock);
      if (pool->size() < self->capacity)
      {
        //assert(value->_mpfr_d != 0);
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->mpfrSpinlock);
    }//end if (pool)
    if (!repooled)
      mpfr_clear(value);
    OSAtomicAdd64(1, &self->mpfrCounter);
  }//end if (value)
}
//end repoolMpfr:

-(__mpfi_struct) depoolMpfi:(mpfr_prec_t)prec
{
  __mpfi_struct result = {0};
  BOOL takenInPool = NO;
  std::vector<__mpfi_struct>* pool = reinterpret_cast<std::vector<__mpfi_struct>*>(self->mpfiVector);
  if (pool)
  {
    OSSpinLockLock(&self->mpfiSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      mpfi_set_prec(&result, prec);
      pool->pop_back();
      takenInPool = YES;
      //assert(result.left._mpfr_d != 0);
      //assert(result.right._mpfr_d != 0);
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->mpfiSpinlock);
  }//end if (pool)
  if (!takenInPool)
    mpfi_init2(&result, prec);
  OSAtomicAdd64(-1, &self->mpfiCounter);
  return result;
}
//end depoolMpfi:

-(void) repoolMpfi:(mpfi_ptr)value
{
  if (value)
  {
    BOOL repooled = NO;
    std::vector<__mpfi_struct>* pool = reinterpret_cast<std::vector<__mpfi_struct>*>(self->mpfiVector);
    if (pool)
    {
      OSSpinLockLock(&self->mpfiSpinlock);
      if (pool->size() < self->capacity)
      {
        //assert(value->left._mpfr_d != 0);
        //assert(value->right._mpfr_d != 0);
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->mpfiSpinlock);
    }//end if (pool)
    if (!repooled)
      mpfi_clear(value);
    OSAtomicAdd64(1, &self->mpfiCounter);
  }//end if (value)
}
//end repoolMpfi:

-(__mpfir_struct) depoolMpfir:(mpfr_prec_t)prec
{
  __mpfir_struct result = {0};
  BOOL takenInPool = NO;
  std::vector<__mpfir_struct>* pool = reinterpret_cast<std::vector<__mpfir_struct>*>(self->mpfirVector);
  if (pool)
  {
    OSSpinLockLock(&self->mpfirSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      mpfir_set_prec(&result, prec);
      pool->pop_back();
      takenInPool = YES;
      //assert(result.estimation._mpfr_d != 0);
      //assert(result.interval.left._mpfr_d != 0);
      //assert(result.interval.right._mpfr_d != 0);
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->mpfirSpinlock);
  }//end if (pool)
  if (!takenInPool)
    mpfir_init2(&result, prec);
  OSAtomicAdd64(-1, &self->mpfirCounter);
  return result;
}
//end depoolMpfir:

-(void) repoolMpfir:(mpfir_ptr)value
{
  if (value)
  {
    BOOL repooled = NO;
    std::vector<__mpfir_struct>* pool = reinterpret_cast<std::vector<__mpfir_struct>*>(self->mpfirVector);
    if (pool)
    {
      OSSpinLockLock(&self->mpfirSpinlock);
      if (pool->size() < self->capacity)
      {
        //assert(value->estimation._mpfr_d != 0);
        //assert(value->interval.left._mpfr_d != 0);
        //assert(value->interval.right._mpfr_d != 0);
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->mpfirSpinlock);
    }//end if (pool)
    if (!repooled)
      mpfir_clear(value);
    OSAtomicAdd64(1, &self->mpfirCounter);
  }//end if (value)
}
//end repoolMpfir:

-(arb_struct) depoolArb
{
  arb_struct result;
  BOOL takenInPool = NO;
  std::vector<arb_struct>* pool = reinterpret_cast<std::vector<arb_struct>*>(self->arbVector);
  if (pool)
  {
    OSSpinLockLock(&self->arbSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      pool->pop_back();
      takenInPool = YES;
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->arbSpinlock);
  }//end if (pool)
  if (!takenInPool)
    arb_init(&result);
  OSAtomicAdd64(-1, &self->arbCounter);
  return result;
}
//end depoolArb

-(void) repoolArb:(arb_ptr)value
{
  if (value)
  {
    BOOL repooled = NO;
    std::vector<arb_struct>* pool = reinterpret_cast<std::vector<arb_struct>*>(self->arbVector);
    if (pool)
    {
      OSSpinLockLock(&self->arbSpinlock);
      if (pool->size() < self->capacity)
      {
        pool->push_back(*value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->arbSpinlock);
    }//end if (pool)
    if (!repooled)
      arb_clear(value);
    OSAtomicAdd64(1, &self->arbCounter);
  }//end if (value)
}
//end repoolArb:

+(void) push:(CHGmpPool*)pool
{
  if (pool)
  {
    if (!pools)
    {
      @synchronized(self)
      {
        if (!pools)
          pools = [[NSMutableArray alloc] init];
      }//end @synchronized(self)
    }//end if (!pools)
    @synchronized(pools)
    {
      [pools addObject:pool];
    }//end @synchronized(pools)
  }//end if (pool)
}
//end push:

+(void) pop
{
  if (pools)
  {
    @synchronized(pools)
    {
      if (pools.count)
        [pools removeLastObject];
    }//end @synchronized(pools)
  }//end if (pools)
}
//end pop

+(CHGmpPool*) peek
{
  CHGmpPool* result = nil;
  if (pools)
  {
    @synchronized(pools)
    {
      if (pools.count)
        result = [pools lastObject];
    }//end @synchronized(pools)
  }//end if (pools)
  return result;
}
//end peek

@end
