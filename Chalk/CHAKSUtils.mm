//
//  CHAKSUtils.cpp
//  Chalk
//
//  Created by Pierre Chatelier on 22/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#include "CHAKSUtils.h"

#include "CHUtils.h"

#include <pthread.h>

#include <algorithm>
#include <limits>
#include <new>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif

class mpz_pool
{
  public:
    mpz_pool(void){
      pthread_mutex_init(&this->mutex, NULL);
      pthread_mutex_init(&this->userMutex, NULL);
    }//end mpz_pool()
    ~mpz_pool(){
      pthread_mutex_lock(&this->mutex);
      for(std::vector<mpz_t*>::iterator it = this->pool.begin(), itEnd = this->pool.end() ; it != itEnd ; ++it)
      {
        mpz_clear(**it);
        free(*it);
      }//end for each element
      pthread_mutex_unlock(&this->mutex);
      pthread_mutex_destroy(&this->mutex);
      pthread_mutex_destroy(&this->userMutex);
    }//end ~mpz_pool()
  public:
    mpz_t* depool(void){
      mpz_t* result = 0;
      pthread_mutex_lock(&this->mutex);
      if (pool.empty())
      {
        result = (mpz_t*)calloc(1, sizeof(mpz_t));
        if (result)
          mpz_init(*result);
      }//end if (pool.empty())
      else//if (!pool.empty())
      {
        result = this->pool.back();
        this->pool.pop_back();
      }//end if (!pool.empty())
      pthread_mutex_unlock(&this->mutex);
      return result;
    }//end depool()
    void repool(mpz_t* src){
      if (src)
      {
        pthread_mutex_lock(&this->mutex);
        this->pool.push_back(src);
        pthread_mutex_unlock(&this->mutex);
      }//end if (src)
    }//end repool()
  public:
    pthread_mutex_t* getUserMutex(void) {return &this->userMutex;}
    void userLock(void) {pthread_mutex_lock(&this->userMutex);}
    void userUnlock(void) {pthread_mutex_unlock(&this->userMutex);}
  private:
    std::vector<mpz_t*> pool;
    pthread_mutex_t mutex;
    pthread_mutex_t userMutex;
};
//end class mpz_pool

class aks_sieve {
  public:
    aks_sieve(void):size(2){
      mpz_init(table);
    }//end aks_sieve()
    ~aks_sieve() {
      mpz_clear(table);
    }//end ~aks_sieve()
  private:
    aks_sieve(const aks_sieve& other) {}
    aks_sieve& operator=(const aks_sieve& other) {return *this;}
  public:
    chalk_bool_t isPrime(mpz_srcptr r) {
      chalk_bool_t result = CHALK_BOOL_MAYBE;
      if (mpz_fits_nsui_p(r))
      {
        mp_bitcnt_t rul = mpz_get_nsui(r);
        if (this->size >= rul)
          result = !mpz_tstbit(this->table, rul) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
        else if (this->size<=std::numeric_limits<mp_bitcnt_t>::max()/2)
        {
          this->size *= 2;
          mp_bitcnt_t i = 2;
          bool stopI = false;
          while(!stopI)
          {
            if (!mpz_tstbit(this->table, i))
            {
              mp_bitcnt_t j = 2*i;
              bool stopJ = (j<=i);//in case of overflow
              while(!stopJ)
              {
                mpz_setbit(this->table, j);
                stopJ |= (j >= this->size);
                j += i;
                stopJ |= (j<=i);//overflow
              }//end while(!stop)
            }//end if (!mpz_tstbit(this->table, i) && (i<=(this->size/2)))
            stopI |= (i == this->size);
            ++i;
          }//end for each i
          result = !mpz_tstbit(this->table, rul) ? CHALK_BOOL_YES : CHALK_BOOL_NO;
        }//end if (this->size<=std::numeric_limits<mp_bitcnt_t>::max()/2)
      }//end if (mpz_fits_nsui_p(r))
      return result;
    }//end isPrime()
  private:
    mpz_t table;
    mp_bitcnt_t size;
};
//end class aks_sieve

class mpz_pX {
  public:
    inline mpz_pX(mp_bitcnt_t initialLength = 0);
    inline mpz_pX(const mpz_pX& other);
    inline ~mpz_pX();
  public:
    inline mpz_pX& operator=(const mpz_pX& other);
  public:
    inline mp_bitcnt_t getDegree(void) const {return this->degree;}
    inline mpz_srcptr getCoef(mp_bitcnt_t i) const;
    inline void getCoef(mpz_t rop, mp_bitcnt_t i) const;
    inline void setCoef(NSUInteger newCoef, mp_bitcnt_t i);
    inline void setCoef(mpz_srcptr newCoef, mp_bitcnt_t i);
    inline bool isEqual(const mpz_pX& other);
  public:
    void clear(void);
    void compact(void);
  private:
    mpz_t* coefs;
    mpz_t  coefsValids;
    mp_bitcnt_t degree;
    mpz_t zero;
    mpz_pool pool;
};
//end class mpz_pX

mpz_pX::mpz_pX(mp_bitcnt_t initialLength)
       :coefs(0),degree(initialLength)
{
  mpz_init_set_ui(this->zero, 0);
  if (this->degree == std::numeric_limits<mp_bitcnt_t>::max())
    throw std::bad_alloc();
  this->coefs = (mpz_t*)calloc(this->degree+1, sizeof(mpz_t));
  if (!this->coefs)
    throw std::bad_alloc();
  mpz_init2(this->coefsValids, this->degree+1);
}
//end mpz_pX::mpz_pX(mp_bitcnt_t)

mpz_pX::mpz_pX(const mpz_pX& other)
       :coefs(0),degree(other.degree)
{
  mpz_init_set_ui(this->zero, 0);
  this->coefs = (mpz_t*)calloc(this->degree+1, sizeof(mpz_t));
  if (!this->coefs)
    throw std::bad_alloc();
  mpz_init2(this->coefsValids, this->degree+1);
  mpz_set(this->coefsValids, other.coefsValids);
  for(mp_bitcnt_t i = 0 ; i<=this->degree ; ++i)
  {
    if (mpz_tstbit(this->coefsValids, i))
      mpz_init_set(this->coefs[i], other.coefs[i]);
  }//end for each coef
}
//end mpz_pX::mpz_pX(const mpz_pX&)

mpz_pX& mpz_pX::operator=(const mpz_pX& other)
{
  for(mp_bitcnt_t i = 0 ; i<=this->degree ; ++i)
  {
    if (mpz_tstbit(this->coefsValids, i))
    {
      mpz_clear(this->coefs[i]);
      mpz_clrbit(this->coefsValids, i);
    }//end if (mpz_tstbit(this->coefsValids, i))
  }//end for each coef
  free(this->coefs);
  this->degree = other.degree;
  this->coefs = (mpz_t*)calloc(this->degree+1, sizeof(mpz_t));
  if (!this->coefs)
    throw std::bad_alloc();
  mpz_set(this->coefsValids, other.coefsValids);
  for(mp_bitcnt_t i = 0 ; i<=this->degree ; ++i)
  {
    if (mpz_tstbit(this->coefsValids, i))
      mpz_init_set(this->coefs[i], other.coefs[i]);
  }//end for each coef
  return *this;
}
//end mpz_pX::mpz_pX(const mpz_pX&)

mpz_pX::~mpz_pX()
{
  mpz_clear(this->zero);
  if (this->coefs)
  {
    for(mp_bitcnt_t i = 0 ; i<=this->degree ; ++i)
    {
      if (mpz_tstbit(this->coefsValids, i))
      {
        mpz_clear(this->coefs[i]);
        mpz_clrbit(this->coefsValids, i);
      }//end if (mpz_tstbit(this->coefsValids, i))
    }//end for each coef
    free(this->coefs);
  }//end if (this->coefs)
  mpz_clear(this->coefsValids);
}
//end mpz_pX::~mpz_pX()

mpz_srcptr mpz_pX::getCoef(mp_bitcnt_t i) const
{
  mpz_srcptr result = this->zero;
  if ((i<=this->degree) && mpz_tstbit(this->coefsValids, i))
    result = this->coefs[i];
  return result;
}
//end mpz_pX::getCoef()

void mpz_pX::getCoef(mpz_t rop, mp_bitcnt_t i) const
{
  if ((i>this->degree) || !mpz_tstbit(this->coefsValids, i))
    mpz_set_ui(rop, 0);
  else
    mpz_set(rop, this->coefs[i]);
}
//end mpz_pX::getCoef()

void mpz_pX::setCoef(mpz_srcptr newCoef, mp_bitcnt_t i)
{
  if (i <= this->degree)
  {
    if (mpz_tstbit(this->coefsValids, i))
      mpz_set(this->coefs[i], newCoef);
    else//if (!mpz_tstbit(this->coefsValids, i))
    {
      mpz_init_set(this->coefs[i], newCoef);
      mpz_setbit(this->coefsValids, i);
    }//end if (!mpz_tstbit(this->coefsValids, i))
  }//end if (i <= this->degree)
  else if (i == std::numeric_limits<mp_bitcnt_t>::max())
    throw std::bad_alloc();
  else//if ((i > this->degree) && (i < std::numeric_limits<mp_bitcnt_t>::max()))
  {
    mpz_t* newCoefs = (mpz_t*)realloc(this->coefs, (i+1)*sizeof(mpz_t));
    if (!newCoefs)
      throw std::bad_alloc();
    else//if (newCoefs)
    {
      this->coefs = newCoefs;
      mpz_realloc2(this->coefsValids, this->degree+1);
      mpz_init_set(this->coefs[i], newCoef);
      mpz_setbit(this->coefsValids, i);
      this->degree = i;
    }//end if (newCoefs)
  }//end if ((i > this->degree) && (i < std::numeric_limits<mp_bitcnt_t>::max()))
}
//end mpz_pX::setCoef(mpz_srcptr, mp_bitcnt_t)

void mpz_pX::setCoef(NSUInteger newCoef, mp_bitcnt_t i)
{
  if (i <= this->degree)
  {
    if (mpz_tstbit(this->coefsValids, i))
      mpz_set_nsui(this->coefs[i], newCoef);
    else//if (!mpz_tstbit(this->coefsValids, i))
    {
      mpz_init_set_nsui(this->coefs[i], newCoef);
      mpz_setbit(this->coefsValids, i);
    }//end if (!mpz_tstbit(this->coefsValids, i))
  }//end if (i <= this->degree)
  else if (i == std::numeric_limits<mp_bitcnt_t>::max())
    throw std::bad_alloc();
  else//if ((i > this->degree) && (i < std::numeric_limits<mp_bitcnt_t>::max()))
  {
    mpz_t* newCoefs = (mpz_t*)realloc(this->coefs, (i+1)*sizeof(mpz_t));
    if (!newCoefs)
      throw std::bad_alloc();
    else//if (newCoefs)
    {
      this->coefs = newCoefs;
      mpz_realloc2(this->coefsValids, this->degree+1);
      mpz_init_set_nsui(this->coefs[i], newCoef);
      mpz_setbit(this->coefsValids, i);
      this->degree = i;
    }//end if (newCoefs)
  }//end if ((i > this->degree) && (i < std::numeric_limits<mp_bitcnt_t>::max()))
}
//end mpz_pX::setCoef(NSUInteger, mp_bitcnt_t)

bool mpz_pX::isEqual(const mpz_pX& other)
{
  bool result = false;
  if (this->degree == other.degree)
  {
    result = true;
    for(mp_bitcnt_t i = 0 ; result && (i<=this->degree) ; ++i)
      result &= !mpz_cmp(this->getCoef(i), other.getCoef(i));
  }//end if (this->degree == other.degree)
  return result;
}
//end mpz_pX::isEqual()

void mpz_pX::compact(void)
{
  mp_bitcnt_t i = this->degree+1;
  bool done = false;
  while(!done && i--)
  {
    if (!mpz_tstbit(this->coefsValids, i)){
    }
    else if (!mpz_cmp_ui(this->coefs[i], 0))
    {
      mpz_clear(this->coefs[i]);
      mpz_clrbit(this->coefsValids, i);
    }//end if (!mpz_cmp_ui(this->coefs[i], 0))
    else
      done = true;
  }//end while(!done && i--)
  if (i != this->degree)
  {
    if (i == std::numeric_limits<mp_bitcnt_t>::max())//the whole polynomial was 0
      this->clear();
    else//if (i<std::numeric_limits<mp_bitcnt_t>::max())
    {
      mpz_t* newCoefs = (mpz_t*)realloc(this->coefs, (i+1)*sizeof(mpz_t));
      if (!newCoefs)
        throw std::bad_alloc();
      else//if (newCoefs)
      {
        mpz_realloc2(this->coefsValids, i+1);
        this->coefs = newCoefs;
        this->degree = i;
      }//end if (newCoefs)
    }//end if (i<std::numeric_limits<mp_bitcnt_t>::max())
  }//end if (i != this->degree)
}
//end mpz_pX::compact()

void mpz_pX::clear(void)
{
  for(mp_bitcnt_t i = 0 ; i <= this->degree ; ++i)
  {
    if (mpz_tstbit(this->coefsValids, i))
    {
      mpz_clear(this->coefs[i]);
      mpz_clrbit(this->coefsValids, i);
    }//end if (mpz_tstbit(this->coefsValids, i))
  }//end for each coef
  this->degree = 0;
  mpz_t* newCoefs = (mpz_t*)realloc(this->coefs, 1*sizeof(mpz_t));
  if (!newCoefs)
    throw std::bad_alloc();
  else//if (newCoefs)
    this->coefs = newCoefs;
}
//end mpz_pX::clear()

bool mpz_pX_mod_mult(mpz_pX& rop, const mpz_pX& x, const mpz_pX& y, mpz_srcptr mod, mp_bitcnt_t polymod, mpz_pool& pool)
{
  bool result = false;
  bool shouldCloneX = (&rop == &x);
  bool shouldCloneY = (&rop == &y);
  mpz_pX* xClone = shouldCloneX ? new(std::nothrow) mpz_pX(x) : 0;
  mpz_pX* yClone = shouldCloneY ? new(std::nothrow) mpz_pX(y) : 0;
  if ((xClone || !shouldCloneX) && (yClone || !shouldCloneY))
  {
    const mpz_pX& localX = xClone ? *xClone : x;
    const mpz_pX& localY = yClone ? *yClone : y;
    
    rop.clear();
    mp_bitcnt_t xdeg = localX.getDegree();
    mp_bitcnt_t ydeg = localY.getDegree();
    mp_bitcnt_t maxdeg = std::max(xdeg, ydeg);

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block size_t maxK = polymod;
    dispatch_range_async_gmp(NSMakeRange(0, polymod), queue, ^(size_t k, BOOL* stop) {
      BOOL shouldIterate = NO;
      pool.userLock();
      shouldIterate = !*stop && (k<maxK);
      pool.userUnlock();
      if (shouldIterate)
      {
        mpz_t* sumPool = pool.depool();
        mpz_t* tmp1Pool = pool.depool();
        mpz_t localSum;
        mpz_t localTmp1;
        mpz_ptr localSumPtr = !sumPool ? 0 : *sumPool;
        mpz_ptr localTmp1Ptr = !tmp1Pool ? 0 : *tmp1Pool;
        if (!sumPool)
        {
          mpz_init(localSum);
          localSumPtr = localSum;
        }//end tmp1Pool (!sumPool)
        if (!tmp1Pool)
        {
          mpz_init(localTmp1);
          localTmp1Ptr = localTmp1;
        }//end if (!tmp1Pool)
        mpz_set_ui(localSumPtr, 0);
        for(mp_bitcnt_t i = 0 ; !*stop && (i<=k) ; ++i)
        {
          mpz_srcptr op1 = localX.getCoef(i);
          mpz_srcptr op2 = !mpz_sgn(op1) ? 0 : localY.getCoef(k-i);
          mpz_srcptr op3 = !op2 ? 0 : localY.getCoef(k-i+polymod);
          if (op2 && op3)
          {
            mpz_add(localTmp1Ptr, op2, op3);
            mpz_addmul(localSumPtr, op1, localTmp1Ptr);
          }//end if (op2 && op3)
        }//end for each i
        for(mp_bitcnt_t i = k+1 ; !*stop && (i<=k+polymod) ; ++i)
        {
          mpz_srcptr op1 = localX.getCoef(i);
          mpz_srcptr op2 = !mpz_sgn(op1) ? 0 : localY.getCoef(k+polymod-i);
          if (op2 && mpz_sgn(op2))
            mpz_addmul(localSumPtr, op1, op2);
        }//end for each i
        mpz_mod(localTmp1Ptr, localSumPtr, mod);
        if (!*stop)
        {
          pool.userLock();
          rop.setCoef(localTmp1Ptr, k);
          pool.userUnlock();
        }//end if (!*stop)

        if ((k>maxdeg && !mpz_cmp_ui(localSumPtr, 0)))
        {
          pool.userLock();
          maxK = std::min(maxK, k);
          pool.userUnlock();
          *stop = YES;
        }//end if ((k>maxdeg && !mpz_cmp_ui(localSumPtr, 0)))
        if (sumPool)
          pool.repool(sumPool);
        else
          mpz_clear(localSum);
        if (tmp1Pool)
          pool.repool(tmp1Pool);
        else
          mpz_clear(localTmp1);
      }//end if (shouldIterate)
    });
    /*
    mpz_t sum;
    mpz_t tmp1;
    mpz_init(sum);
    mpz_init(tmp1);
    bool stopK = false;
    for(mp_bitcnt_t k = 0 ; !stopK && (k<polymod) ; ++k)
    {
      mpz_set_ui(sum, 0);
      for(mp_bitcnt_t i = 0 ; i<=k ; ++i)
      {
        mpz_srcptr op1 = localX.getCoef(i);
        mpz_srcptr op2 = !mpz_sgn(op1) ? 0 : localY.getCoef(k-i);
        mpz_srcptr op3 = !op2 ? 0 : localY.getCoef(k-i+polymod);
        if (op2 && op3)
        {
          mpz_add(tmp1, op2, op3);
          mpz_addmul(sum, op1, tmp1);
        }//end if (op2 && op3)
      }//end for each i
      for(mp_bitcnt_t i = k+1 ; i<=k+polymod ; ++i)
      {
        mpz_srcptr op1 = localX.getCoef(i);
        mpz_srcptr op2 = !mpz_sgn(op1) ? 0 : localY.getCoef(k+polymod-i);
        if (op2 && mpz_sgn(op2))
          mpz_addmul(sum, op1, op2);
      }//end for each i
      mpz_mod(tmp1, sum, mod);
      rop.setCoef(tmp1, k);
      stopK |= (k>maxdeg && !mpz_cmp_ui(sum, 0));
    }//end for each k
    mpz_clear(sum);
    mpz_clear(tmp1);*/
    rop.compact();
    result = true;
  }//end if ((xClone || !shouldCloneX) && (yClone || !shouldCloneY))
  if (xClone)
    delete xClone;
  if (yClone)
    delete yClone;
  return result;
}
//end mpz_pX_mod_mult()

bool mpz_pX_mod_power(mpz_pX &rop, const mpz_pX& x, mpz_srcptr power, mpz_srcptr mult_mod, mp_bitcnt_t polymod, mpz_pool& pool)
{
  bool result = false;
  bool error = false;
  mpz_t one;
  mpz_init_set_ui(one, 1);
  rop.clear();
  rop.setCoef(one, 0);
  mpz_clear(one);
  mp_bitcnt_t i = mpz_sizeinbase(power, 2);
  while(i-- && !error)
  {
    mp_bitcnt_t bit = i+1;
    error = error || !mpz_pX_mod_mult(rop, rop, rop, mult_mod, polymod, pool);
    if (mpz_tstbit(power, bit))
      error = error || !mpz_pX_mod_mult(rop, rop, x, mult_mod, polymod, pool);
  }//end while(i-- && !error)
  rop.compact();
  result = !error;
  return result;
}
//end mpz_pX_mod_power()

chalk_bool_t aks_isPrime(mpz_srcptr op)
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  if (mpz_perfect_power_p(op))
    result = CHALK_BOOL_NO;
  else//if (!mpz_perfect_power_p(op))
  {
    mpz_pool pool;
    aks_sieve s;
    mpz_t r;
    mpz_init_set_ui(r, 2);
    mpz_t logn;
    mpz_init_set_nsui(logn, mpz_sizeinbase(op,2));
    mpz_t limit;
    mpz_init(limit);
    mpz_mul(limit, logn, logn);
    mpz_mul_2exp(limit, limit, 2);
    bool stopR = false;
    while((result == CHALK_BOOL_MAYBE) && (mpz_cmp(r, op)<0) && !stopR)
    {
      if (mpz_divisible_p(op, r))
        result = CHALK_BOOL_NO;
      if (result == CHALK_BOOL_MAYBE)
      {
        bool failed = false;
        if (s.isPrime(r))
        {
          mpz_t i;
          mpz_init_set_ui(i, 1);
          mpz_t res;
          mpz_init(res);
          bool stopI = NO;
          while(!stopI)
          {
            mpz_set_ui(res, 0);
            mpz_powm(res, op, i, r);
            failed |= !mpz_cmp_ui(res, 1);
            stopI |= failed;
            if (!stopI)
              stopI |= !mpz_cmp(i, limit);
            if (!stopI)
              mpz_add_ui(i, i, 1);
          }//end while(!stopI)
          stopR |= !failed;
          mpz_clear(i);
          mpz_clear(res);
        }//end if (coprimes)
      }//end if (result == CHALK_BOOL_MAYBE)
      if (!stopR)
        mpz_add_ui(r, r, 1);
    }//end while((result == CHALK_BOOL_MAYBE) && (mpz_cmp(r, op)<0) && !stopR)
    if ((result == CHALK_BOOL_MAYBE) && !mpz_cmp(r, op))
      result = CHALK_BOOL_YES;
    if ((result == CHALK_BOOL_MAYBE) && mpz_fits_nsui_p(r))
    {
      //Polynomial check
      mpz_t sqrtr;
      mpz_init(sqrtr);
      //actually the floor, add one later to get the ceil
      mpz_sqrt(sqrtr, r);
      mpz_t polylimit;
      mpz_init_set(polylimit, sqrtr);
      mpz_add_ui(polylimit, polylimit, 1);
      mpz_mul(polylimit, polylimit, logn);
      mpz_mul_2exp(polylimit, polylimit, 1);
      if (mpz_fits_nsui_p(polylimit))
      {
        mp_bitcnt_t polylimit_ui = mpz_get_nsui(polylimit);
        mp_bitcnt_t intr = mpz_get_ui(r);
        mpz_t final_size;
        mpz_init(final_size);
        mp_bitcnt_t a = 1;
        bool stopA = NO;
        bool error = NO;
        while(!stopA && !error)
        {
          mpz_set(final_size, op);
          mpz_mod(final_size, final_size, r);
          mpz_pX compare(mpz_get_ui(final_size));
          compare.setCoef(1, mpz_get_ui(final_size));
          compare.setCoef(a, 0);
          mpz_pX res(intr);
          mpz_pX base(1);
          base.setCoef(a, 0);
          base.setCoef(1, 1);
          error = !mpz_pX_mod_power(res, base, op, op, intr, pool);
          if (error)
            stopA = true;
          else if (!res.isEqual(compare))
          {
            result = CHALK_BOOL_NO;
            stopA = true;
          }//end if (!res.isEqual(compare))
          else
          {
            stopA |= (a == polylimit_ui);
            ++a;
          }
        }//end while(!stopA && !error)
        if (error)
          result = CHALK_BOOL_MAYBE;
        else if (result == CHALK_BOOL_MAYBE)
          result = CHALK_BOOL_YES;
        mpz_clear(final_size);
      }//end if (mpz_fits_nsui_p(polylimit))
      mpz_clear(sqrtr);
      mpz_clear(polylimit);
    }//end if (result == CHALK_BOOL_MAYBE)
    mpz_clear(r);
    mpz_clear(logn);
    mpz_clear(limit);
  }//end if (!mpz_perfect_power_p(op))
  return result;
}
//end aks_isPrime()

#ifdef __cplusplus
}
#endif
