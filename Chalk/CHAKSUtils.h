//
//  CHAKSUtils.h
//  Chalk
//
//  Created by Pierre Chatelier on 22/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#ifndef __Chalk__CHAKSUtils__
#define __Chalk__CHAKSUtils__

#include "CHChalkUtils.h"
#include <gmp.h>

#ifdef __cplusplus
extern "C" {
#endif

chalk_bool_t aks_isPrime(mpz_srcptr op);

#ifdef __cplusplus
}
#endif

#endif /* defined(__Chalk__CHAKSUtils__) */
