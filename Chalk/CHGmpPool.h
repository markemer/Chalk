//
//  CHGmpPool.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/06/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <gmp.h>
#include <mpfr.h>
#include <mpfi.h>
#include <arb.h>
#include "mpfir.h"

@interface CHGmpPool : NSObject {
   NSUInteger capacity;
   void* mpzVector;
   void* mpqVector;
   void* mpfrVector;
   void* mpfiVector;
   void* mpfirVector;
   void* arbVector;
   OSSpinLock mpzSpinlock;
   OSSpinLock mpqSpinlock;
   OSSpinLock mpfrSpinlock;
   OSSpinLock mpfiSpinlock;
   OSSpinLock mpfirSpinlock;
   OSSpinLock arbSpinlock;
   int64_t mpzCounter;
   int64_t mpqCounter;
   int64_t mpfrCounter;
   int64_t mpfiCounter;
   int64_t mpfirCounter;
   int64_t arbCounter;
}

-(instancetype) initWithCapacity:(NSUInteger)aCapacity;

-(__mpz_struct)   depoolMpz;
-(void)           repoolMpz:(mpz_ptr)value;
-(__mpq_struct)   depoolMpq;
-(void)           repoolMpq:(mpq_ptr)value;
-(__mpfr_struct)  depoolMpfr:(mpfr_prec_t)prec;
-(void)           repoolMpfr:(mpfr_ptr)value;
-(__mpfi_struct)  depoolMpfi:(mpfr_prec_t)prec;
-(void)           repoolMpfi:(mpfi_ptr)value;
-(__mpfir_struct) depoolMpfir:(mpfr_prec_t)prec;
-(void)           repoolMpfir:(mpfir_ptr)value;
-(arb_struct)     depoolArb;
-(void)           repoolArb:(arb_ptr)value;

+(void) push:(CHGmpPool*)pool;
+(void) pop;
+(CHGmpPool*) peek;

@end
