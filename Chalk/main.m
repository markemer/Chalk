///
//  main.m
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHUtils.h"
#import "CHChalkUtils.h"

int main(int argc, const char * argv[])
{
  int debugLogLevelShift = 0;
  BOOL shiftIsPressed = (([NSEvent modifierFlags] & NSShiftKeyMask) != 0);
  if (shiftIsPressed)
  {
    NSLog(@"Shift key pressed during launch");
    debugLogLevelShift += 1;
  }//end if (shiftIsPressed)
  
  int i = 0;
  for(i = 1 ; i<argc ; ++i)
  {
    if (!strcasecmp(argv[i], "-v"))
    {
      DebugLogLevel = 1;
      if (i+1 < argc)
      {
        char* endPtr = 0;
        long level = strtol(argv[i+1], &endPtr, 10);
        int error = (endPtr && (*endPtr != '\0'));
        DebugLogLevel = error ? DebugLogLevel : level;
      }//end if -v something
    }//end if -v
  }//end for each arg
  DebugLogLevel += debugLogLevelShift;
  if (DebugLogLevel >= 1){
    NSLog(@"Launching with DebugLogLevel = %ld", DebugLogLevel);
  }
  
  /*mpfr_prec_t prec = 128;
  mpfr_t af;
  mpfr_t bf;
  mpfr_init2(af, prec);
  mpfr_init2(bf, prec);
  mpfr_set_inf(af, -1);
  mpfr_set_d(bf,  2, MPFR_RNDN);
  
  arb_t a;
  arb_init(a);
  arb_set_interval_mpfr(a, af, bf, prec);
  arb_get_interval_mpfr(af, bf, a);
  printf("[%f;%f]\n", mpfr_get_d(af, MPFR_RNDN), mpfr_get_d(bf, MPFR_RNDN));*/
  
  DebugLogStatic(1, @"gmp %s", gmp_version);
  DebugLogStatic(1, @"mpfr %s", mpfr_get_version());
  DebugLogStatic(1, @"mpfr_get_emin_min : %ld", (long)mpfr_get_emin_min());
  DebugLogStatic(1, @"mpfr_get_emin_max : %ld", (long)mpfr_get_emin_max());
  DebugLogStatic(1, @"mpfr_get_emax_min : %ld", (long)mpfr_get_emax_min());
  DebugLogStatic(1, @"mpfr_get_emax_max : %ld", (long)mpfr_get_emax_max());
  DebugLogStatic(1, @"mpfr_buildopt_tls_p : %d", mpfr_buildopt_tls_p());
  DebugLogStatic(1, @"mpfr_buildopt_sharedcache_p : %d", mpfr_buildopt_sharedcache_p());
  mpfr_set_emin(mpfr_get_emin_min());
  mpfr_set_emax(mpfr_get_emax_max());
  DebugLogStatic(1, @"mpfr_get_emin : %ld", (long)mpfr_get_emin());
  DebugLogStatic(1, @"mpfr_get_emax : %ld", (long)mpfr_get_emax());
  DebugLogStatic(1, @"mpfi %s", mpfi_get_version());
  DebugLogStatic(1, @"arb %s", arb_version);
  DebugLogStatic(1, @"flint %@", @(FLINT_VERSION));
  
  return NSApplicationMain(argc, argv);
}
