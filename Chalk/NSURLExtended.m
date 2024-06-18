//
//  NSURLExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 07/02/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSURLExtended.h"

@implementation NSURL (Extended)

+(NSURL*) URLAutoWithPath:(NSString*)path
{
  NSURL* result = nil;
  NSURL* tmpURL = !path ? nil : [NSURL URLWithString:path];
  NSString* scheme = tmpURL.scheme;
  if (!scheme || [scheme isEqualToString:@""])
    result = [NSURL fileURLWithPath:path];
  else
    result = tmpURL;
  return result;
}
//end URLAutoWithPath:

@end
