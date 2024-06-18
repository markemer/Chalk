//
//  CHParseConfiguration.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParseConfiguration.h"

#import "CHPreferencesController.h"
#import "NSObjectExtended.h"

@implementation CHParseConfiguration

@synthesize parseMode;

@dynamic plist;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  [self reset];
  return self;
}
//end init

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super init])))
    return nil;
  self->parseMode =
    [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"parseMode"] unsignedIntegerValue];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:@(self->parseMode) forKey:@"parseMode"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHParseConfiguration* result = [[[self class] alloc] init];
  if (result)
  {
    result->parseMode = self->parseMode;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(void) reset
{
  self->parseMode = CHALK_PARSE_MODE_INFIX;
}
//end reset

-(id) plist
{
  id result = [NSMutableDictionary dictionary];
  [result setValue:@(self.parseMode) forKey:@"parseMode"];
  return [[result copy] autorelease];
}
//end plist

-(void) setPlist:(id)plist
{
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSNumber* number = nil;
  number = [[dict objectForKey:@"parseMode"] dynamicCastToClass:[NSNumber class]];
  if (number)
    self.parseMode = (chalk_parse_mode_t)number.unsignedIntegerValue;
}
//end setPlist:

@end
