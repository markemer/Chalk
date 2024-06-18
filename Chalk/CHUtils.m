//
//  CHUtils.m
//  Chalk
//
//  Created by Pierre Chatelier on 27/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUtils.h"

#import <mpfr.h>

long DebugLogLevel = 0;

void _Log(NSString* s)
{
  static FILE* fp = 0;
  if (!fp)
  {
    NSString* folder = NSHomeDirectory();
    NSString* filePath = [folder stringByAppendingPathComponent:@"Chalk.log"];
    fp = fopen([filePath UTF8String], "a+");
  }
  NSData* data = [s dataUsingEncoding:NSUTF8StringEncoding];
  const unsigned char* dataUTF8 = [data bytes];
  if (fp)
  {
    fwrite(dataUTF8, sizeof(unsigned char), data.length, fp);
    fflush(fp);
  }//end if (fp)
}

NSString* NSAppearanceDidChangeNotification = @"NSAppearanceDidChangeNotification";

NSRange NSRangeZero = {0};

NSRange NSRangeNotFound = {NSNotFound, 0};

NSRange NSRangeShift(NSRange range, NSUInteger shift)
{
  NSRange result = NSMakeRange((NSUIntegerMax-range.location)<shift ? NSUIntegerMax : range.location+shift, range.length);
  result.length = (NSUIntegerMax-result.location)<result.length ? (NSUIntegerMax-result.location) : result.length;
  return result;
}
//end NSRangeShift()

NSRange NSRangeUnion(NSRange range1, NSRange range2)
{
  NSRange result = NSRangeZero;
  NSRange input[2] = {range1, range2};
  result = NSRangesUnion(input, 2);
  return result;
}
//end NSRangeUnion()

NSRange NSRangesUnion(const NSRange* ranges, size_t count)
{
  NSRange result = !count ? NSRangeZero : ranges[0];
  for(NSUInteger i = 1 ; i<count ; ++i)
  {
    NSRange range = ranges[i];
    bool isInterestingRange = range.length && (range.location != NSNotFound);
    if (isInterestingRange)
      result = ((result.location == NSNotFound) || !result.length) ? range : NSUnionRange(result, range);
  }//end for each range
  if (result.location == NSNotFound)
    result = NSRangeZero;
  return result;
}
//end NSRangesUnion()

char* strtolower(char* bytes, size_t length)
{
  char* result = bytes;
  const size_t pageSize = 4*1024U;
  const size_t nbPages = length/pageSize;
  const size_t tail = length%pageSize;
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_apply(nbPages+(tail ? 1 : 0), queue, ^(size_t idx) {
    const size_t currentPageBeginIndex = (idx<nbPages) ? idx*pageSize : length-tail;
    const size_t currentPageLength     = (idx<nbPages) ? pageSize : tail;
    for(char* ptr = bytes+currentPageBeginIndex, *ptrEnd = ptr+currentPageLength ; ptr != ptrEnd ; ++ptr)
      *ptr = tolower(*ptr);
  });
  return result;
}
//end strtolower()

char* strtoupper(char* bytes, size_t length)
{
  char* result = bytes;
  const size_t pageSize = 4*1024U;
  const size_t nbPages = length/pageSize;
  const size_t tail = length%pageSize;
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_apply(nbPages+(tail ? 1 : 0), queue, ^(size_t idx) {
    const size_t currentPageBeginIndex = (idx<nbPages) ? idx*pageSize : length-tail;
    const size_t currentPageLength     = (idx<nbPages) ? pageSize : tail;
    for(char* ptr = bytes+currentPageBeginIndex, *ptrEnd = ptr+currentPageLength ; ptr != ptrEnd ; ++ptr)
      *ptr = toupper(*ptr);
  });
  return result;
}
//end strtoupper()

__thread BOOL signal_env_saved = NO;
__thread jmp_buf signal_env;

int saveJmp(void) {int res = setjmp(signal_env); signal_env_saved=YES; return res;}
void resumeJmp(void) {if (signal_env_saved) {signal_env_saved=NO; longjmp(signal_env, 1);}}

void signalHandler(int sig)
{
  DebugLogStatic(0, @"signalHandler(%@), gmp_errno=%@", @(sig), @(gmp_errno));
  BOOL shouldIgnore = (sig == SIGABRT) && (gmp_errno != 0);
  if (shouldIgnore)
    resumeJmp();
}
//end signalHandler()

void signal_install(void)
{
  signal(SIGABRT, signalHandler);
}
//end signal_install()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_with_main_option(dispatch_main_option_t option, DISPATCH_NOESCAPE dispatch_block_t block)
{
  if (option == DISPATCH_NO)
    block();
  else if (option == DISPATCH_MAIN)
  {
    if ([NSThread isMainThread])
      block();
    else
      dispatch_sync(dispatch_get_main_queue(), block);
  }//end if (option == DISPATCH_MAIN)
}
//end dispatch_with_main_option()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_async_gmp(dispatch_queue_t queue, dispatch_block_t block)
{
  mpfr_exp_t emin_min = mpfr_get_emin_min();
  mpfr_exp_t emax_max = mpfr_get_emax_max();
  dispatch_async(queue, ^{
    mpfr_set_emin(emin_min);
    mpfr_set_emax(emax_max);
    signal_install();
    block();
  });
}
//end dispatch_async_gmp()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_apply_gmp(size_t iterations, dispatch_queue_t DISPATCH_APPLY_QUEUE_ARG_NULLABILITY queue, DISPATCH_NOESCAPE void (^block)(size_t))
{
  mpfr_exp_t emin_min = mpfr_get_emin_min();
  mpfr_exp_t emax_max = mpfr_get_emax_max();
  typedef void (^block_apply_t)(size_t);
  block_apply_t blockAdapted = ^(size_t i){
    mpfr_set_emin(emin_min);
    mpfr_set_emax(emax_max);
    signal_install();
    block(i);
  };
  dispatch_apply(iterations, queue, blockAdapted);
}
//end dispatch_apply_gmp()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_applyWithOptions_gmp(size_t iterations, dispatch_queue_t queue, dispatch_options_t options, void (^block)(size_t))
{
  mpfr_exp_t emin_min = mpfr_get_emin_min();
  mpfr_exp_t emax_max = mpfr_get_emax_max();
  typedef void (^block_apply_t)(size_t);
  block_apply_t blockAdapted = ^(size_t i){
    mpfr_set_emin(emin_min);
    mpfr_set_emax(emax_max);
    signal_install();
    block(i);
  };
  if ((options & DISPATCH_OPTION_SYNCHRONOUS) == 0)
    dispatch_apply(iterations, queue, blockAdapted);
  else//if ((options & DISPATCH_OPTION_SYNCHRONOUS) != 0)
  {
    if ((options & DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL) != 0)
    {
      if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) != 0)
      {
        while(iterations--)
        {
          @autoreleasepool {
            blockAdapted(iterations);
          }//end @autoreleasepool
        }//end while(iterations--)
      }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) != 0)
      else//if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) == 0)
      {
        for(NSUInteger i = 0 ; i<iterations ; ++i)
        {
          @autoreleasepool {
            blockAdapted(i);
          }//end @autoreleasepool
        }//end for each iteration
      }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) == 0)
    }
    else//if ((options & DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL) == 0)
    {
      if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) != 0)
      {
        while(iterations--)
          blockAdapted(iterations);
      }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) != 0)
      else//if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) == 0)
      {
        for(NSUInteger i = 0 ; i<iterations ; ++i)
          blockAdapted(i);
      }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS_REVERSE) == 0)
    }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL) == 0)
  }//end if ((options & DISPATCH_OPTION_SYNCHRONOUS) == 0)
}
//end dispatch_applyWithOptions_gmp()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_group_async_gmp(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block)
{
  mpfr_exp_t emin_min = mpfr_get_emin_min();
  mpfr_exp_t emax_max = mpfr_get_emax_max();
  dispatch_block_t blockAdapted = ^{
    mpfr_set_emin(emin_min);
    mpfr_set_emax(emax_max);
    signal_install();
    block();
  };
  dispatch_group_async(group, queue, blockAdapted);
}
//end dispatch_group_async_gmp()

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_range_async_gmp(NSRange range, dispatch_queue_t queue, void (^block)(size_t idx, BOOL* stop))
{
  mpfr_exp_t emin_min = mpfr_get_emin_min();
  mpfr_exp_t emax_max = mpfr_get_emax_max();
  typedef void (^block_range_t)(size_t, BOOL*);
  block_range_t blockAdapted = ^(size_t idx, BOOL* stop){
    mpfr_set_emin(emin_min);
    mpfr_set_emax(emax_max);
    signal_install();
    block(idx, stop);
  };
  if (!range.length){
  }
  else if (range.length == 1)
  {
    __block BOOL stop = NO;
    blockAdapted(0, &stop);
  }//end if (range.length == 1)
  else//if (range.length > 1)
  {
    __block BOOL stop = NO;
    dispatch_group_t group = dispatch_group_create();
    for(NSUInteger idx = range.location ; idx<range.location+range.length ; ++idx)
      dispatch_group_async(group, queue, ^{
        blockAdapted(idx, &stop);
      });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(group);
  }//end if (range.length > 1)
}
//end dispatch_range_async_gmp()
