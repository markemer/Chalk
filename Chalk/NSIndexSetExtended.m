//
//  NSIndexSetExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSIndexSetExtended.h"

typedef struct
{
  NSRange range;
  BOOL flag;
} NSRangeExtended;

NSRangeExtended NSMakeRangeExtended(NSRange range, BOOL flag) {return (NSRangeExtended){range, flag};}

@implementation NSIndexSet (Extended)

+(instancetype) indexSetWithRange1:(NSRange)range1 range2:(NSRange)range2
{
  NSMutableIndexSet* result = [NSMutableIndexSet indexSetWithIndexesInRange:range1];
  [result addIndexesInRange:range2];
  return [[result copy] autorelease];
}
//end indexSetWithRange1:range2:

-(void) enumerateRangesWithin:(NSRange)fullRange usingBlock:(void (^)(NSRange range, BOOL inside, BOOL* stop))block
{
  NSMutableIndexSet* selfcut = [[self mutableCopy] autorelease];
  [selfcut removeIndexesInRange:NSMakeRange(0, fullRange.location)];
  [selfcut removeIndexesInRange:NSMakeRange(NSMaxRange(fullRange), NSNotFound-NSMaxRange(fullRange))];
  NSMutableIndexSet* complement = [NSMutableIndexSet indexSetWithIndexesInRange:fullRange];
  [complement removeIndexes:self];
  NSMutableArray* allRanges = [NSMutableArray array];
  [selfcut enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
    NSRangeExtended rangeExtended = NSMakeRangeExtended(range, YES);
    [allRanges addObject:[NSValue valueWithBytes:&rangeExtended objCType:@encode(NSRangeExtended)]];
  }];
  [complement enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
    NSRangeExtended rangeExtended = NSMakeRangeExtended(range, NO);
    [allRanges addObject:[NSValue valueWithBytes:&rangeExtended objCType:@encode(NSRangeExtended)]];
  }];
  [allRanges sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSRangeExtended rangeExtended1 = {0};
    NSRangeExtended rangeExtended2 = {0};
    [(NSValue*)obj1 getValue:&rangeExtended1];
    [(NSValue*)obj2 getValue:&rangeExtended2];
    return
      (rangeExtended1.range.location < rangeExtended2.range.location) ? NSOrderedAscending :
      (rangeExtended2.range.location < rangeExtended1.range.location) ? NSOrderedDescending :
      NSOrderedSame;
  }];
  [allRanges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSRangeExtended rangeExtended = {0};
    [(NSValue*)obj getValue:&rangeExtended];
    block(rangeExtended.range, rangeExtended.flag, stop);
  }];
}
//end enumerateRangesWithin:

@end
