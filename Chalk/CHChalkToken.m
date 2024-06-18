//
//  CHChalkToken.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkToken.h"

#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHChalkToken

@synthesize value;
@synthesize range;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) chalkTokenEmpty
{
  return [[[[self class] alloc] init] autorelease];
}
//end chalkTokenEmpty

+(instancetype) chalkTokenUnion:(NSArray*)tokens
{
  CHChalkToken* result = nil;
  if (tokens)
  {
    NSMutableString* unionString = [[NSMutableString alloc] init];
    __block NSRange unionRange = NSRangeZero;
    [tokens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHChalkToken* token = [obj dynamicCastToClass:[CHChalkToken class]];
      if (token)
      {
        [unionString appendString:token.value];
        unionRange = NSRangeUnion(unionRange, token.range);
      }//end if (token)
    }];
    result = [[[[self class] alloc] initWithValue:unionString range:unionRange] autorelease];
    [unionString release];
  }//end if (tokens)
  return result;
}
//end chalkTokenUnion:

+(instancetype) chalkTokenWithValue:(NSString*)value range:(NSRange)range
{
  return [[[[self class] alloc] initWithValue:value range:range] autorelease];
}
//end chalkTokenWithValue:range;

-(instancetype) init
{
  return [self initWithValue:@"" range:NSRangeZero];
}
//end init

-(instancetype) initWithValue:(NSString*)aValue range:(NSRange)aRange
{
  if (!((self = [super init])))
    return nil;
  self->value = [aValue copy];
  self->range = aRange;
  return self;
}
//end initWithValue:range:

-(void) dealloc
{
  [self->value release];
  [super dealloc];
}
//end dealloc

-(id) initWithCoder:(NSCoder*)aDecoder
{
  NSString* aValue = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"value"];
  NSRange aRange   = [(NSValue*)[aDecoder decodeObjectOfClass:[NSValue class] forKey:@"range"] rangeValue];
  return [self initWithValue:aValue range:aRange];
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self->value forKey:@"value"];
  [aCoder encodeObject:[NSValue valueWithRange:self->range] forKey:@"range"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkToken* result = [[[self class] allocWithZone:zone] initWithValue:self->value range:self->range];
  return result;
}
//end copyWithZone:

-(void) unionWithTokens:(NSArray*)tokens
{
  [self unionWithToken:[[self class] chalkTokenUnion:tokens]];
}
//end unionWithTokens:

-(void) unionWithToken:(CHChalkToken*)token
{
  if (token)
  {
    NSString* unionString = [[NSString alloc] initWithFormat:@"%@%@", self->value, token.value];
    [self->value release];
    self->value = unionString;
    self->range = NSRangeUnion(self->range, token.range);
  }//end if (token)
}
//end unionWithToken

-(NSString*) description
{
  return self->value;
}
//end description

@end
