//
//  NSAttributedStringExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 18/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSAttributedStringExtended.h"

@implementation NSAttributedString (Extended)

+(instancetype) attributedString
{
  return [[[[self class] alloc] initWithString:@"" attributes:nil] autorelease];
}
//end attributedString

+(instancetype) attributedStringWithString:(NSString*)string
{
  return !string ? nil : [[[[self class] alloc] initWithString:string attributes:nil] autorelease];
}
//end attributedStringWithString:

@end
