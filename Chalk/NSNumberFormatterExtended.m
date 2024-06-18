//
//  NSNumberFormatterExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 05/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSNumberFormatterExtended.h"

@implementation NSNumberFormatter (Extended)

-(NSNumber*) clip:(NSNumber*)value
{
  NSNumber* result = value;
  NSNumber* inf = self.minimum;
  NSNumber* sup = self.maximum;
  result = inf && ([inf compare:result] == NSOrderedDescending) ? inf : result;
  result = sup && ([sup compare:result] == NSOrderedAscending) ? sup : result;
  return result;
}
//end clip:

@end
