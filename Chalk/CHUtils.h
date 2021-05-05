//
//  CHUtils.h
//  Chalk
//
//  Created by Pierre Chatelier on 27/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#ifndef Chalk_CHUtils_h
#define Chalk_CHUtils_h

#include <dispatch/dispatch.h>

extern void _Log(NSString* _Nullable s);
extern long DebugLogLevel;
#define DebugLog(level,log,...) do {if (DebugLogLevel>=level) {NSLog(@"[thread %p : %@ %s] \"%@\"",[NSThread currentThread],[self class],sel_getName(_cmd),[NSString stringWithFormat:log,##__VA_ARGS__]);}} while(0)
#define DebugLogStatic(level,log,...) do {if (DebugLogLevel>=level) {NSLog(@"[%p - static] \"%@\"",[NSThread currentThread], [NSString stringWithFormat:log,##__VA_ARGS__]);}} while(0)
#define DebugLogError(level,error,log,...) {if (DebugLogLevel>=level) {char buffer[1024] = {0}; strerror_r(error, buffer, sizeof(buffer)); DebugLog(level,log,##__VA_ARGS__);}}

#if defined(__cplusplus)
extern "C" {
#endif
  
NS_INLINE BOOL isMacOS10_5OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4);}
NS_INLINE BOOL isMacOS10_6OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_5);}
NS_INLINE BOOL isMacOS10_7OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);}
NS_INLINE BOOL isMacOS10_8OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7);}
NS_INLINE BOOL isMacOS10_9OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8);}
NS_INLINE BOOL isMacOS10_10OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9);}
NS_INLINE BOOL isMacOS10_11OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_10);}
NS_INLINE BOOL isMacOS10_12OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_11);}
NS_INLINE BOOL isMacOS10_13OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_12);}
NS_INLINE BOOL isMacOS10_14OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_13);}
NS_INLINE BOOL isMacOS10_15OrAbove(void) {return (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_14);}

NS_INLINE CGFloat    CGFloatClip(CGFloat inf, CGFloat x, CGFloat sup) {return (x<inf) ? inf : (sup<x) ? sup : x;}
NS_INLINE NSInteger  NSIntegerClip(NSInteger inf, NSInteger x, NSInteger sup) {return (x<inf) ? inf : (sup<x) ? sup : x;}
NS_INLINE NSUInteger NSUIntegerClip(NSUInteger inf, NSUInteger x, NSUInteger sup) {return (x<inf) ? inf : (sup<x) ? sup : x;}
NS_INLINE NSInteger  NSIntegerBetween(NSInteger inf, NSInteger x, NSInteger sup) {return (inf<=x) && (x<=sup);}
NS_INLINE NSUInteger NSUIntegerBetween(NSUInteger inf, NSUInteger x, NSUInteger sup) {return (inf<=x) && (x<=sup);}

NS_INLINE NSUInteger NSUIntegerAdd(NSUInteger x, NSUInteger y) {return (NSUIntegerMax-x < y) ? NSUIntegerMax : x+y;}

extern NSRange NSRangeZero;
extern NSRange NSRangeNotFound;
NS_INLINE BOOL NSRangeContains(NSRange range, NSUInteger index) {return (range.location <= index) && ((range.location+range.length<range.location) || (index < range.location+range.length));}
NSRange NSRangeShift(NSRange range, NSUInteger shift);
NSRange NSRangesUnion(const NSRange* ranges, size_t count);
NSRange NSRangeUnion(NSRange range1, NSRange range2);

char* strtolower(char* bytes, size_t length);
char* strtoupper(char* bytes, size_t length);

typedef enum {DISPATCH_NO, DISPATCH_MAIN} dispatch_main_option_t;

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW
void dispatch_with_main_option(dispatch_main_option_t option, DISPATCH_NOESCAPE dispatch_block_t block);

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW void dispatch_async_gmp(dispatch_queue_t queue, dispatch_block_t block);
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW void dispatch_apply_gmp(size_t iterations, dispatch_queue_t DISPATCH_APPLY_QUEUE_ARG_NULLABILITY queue, DISPATCH_NOESCAPE void (^block)(size_t));

typedef NS_ENUM(NSUInteger, dispatch_options_t) {
  DISPATCH_OPTION_NONE = 0,
  DISPATCH_OPTION_SYNCHRONOUS = 1<<0,
  DISPATCH_OPTION_SYNCHRONOUS_REVERSE = 1<<1,
  DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL = 1<<2
};//end dispatch_options_t

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW void dispatch_applyWithOptions_gmp(size_t iterations, dispatch_queue_t queue, dispatch_options_t options, void (^block)(size_t));

DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW void dispatch_group_async_gmp(dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block);
DISPATCH_EXPORT DISPATCH_NONNULL_ALL DISPATCH_NOTHROW void dispatch_range_async_gmp(NSRange range, dispatch_queue_t queue, void (^block)(size_t idx, BOOL* stop));

#if defined(__cplusplus)
}//end extern "C"
#endif


#endif
