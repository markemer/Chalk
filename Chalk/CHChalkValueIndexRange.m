//
//  CHChalkValueIndexRange.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/04/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueIndexRange.h"

#import "CHChalkToken.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueIndexRange

@synthesize range;
@synthesize joker;
@synthesize exclusive;
@dynamic isEmpty;

+(BOOL) supportsSecureCoding {return YES;}

+(CHChalkValueIndexRange*) emptyValue
{
  return [[[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] range:NSMakeRange(0, 0) joker:NO exclusive:YES context:nil] autorelease];
}
//end emptyValue

-(instancetype) initWithToken:(CHChalkToken*)aToken range:(NSRange)aRange joker:(BOOL)aJoker exclusive:(BOOL)aExclusive context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->range = aRange;
  self->joker = aJoker;
  self->exclusive = aExclusive;
  return self;
}
//end initWithToken:range:context:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->range = [(NSValue*)[aDecoder decodeObjectOfClass:[NSValue class] forKey:@"range"] rangeValue];
  self->joker = [aDecoder decodeBoolForKey:@"joker"];
  self->exclusive = [aDecoder decodeBoolForKey:@"exclusive"];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:[NSValue valueWithRange:self->range] forKey:@"range"];
  [aCoder encodeBool:self->joker forKey:@"joker"];
  [aCoder encodeBool:self->exclusive forKey:@"exclusive"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueIndexRange* result = [super copyWithZone:zone];
  if (result)
  {
    result->range = self->range;
    result->joker = self->joker;
    result->exclusive = self->exclusive;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueIndexRange* dstIndexRange = !result ? nil : [dst dynamicCastToClass:[CHChalkValueIndexRange class]];
  if (result && dstIndexRange)
  {
    dstIndexRange->range = self->range;
    dstIndexRange->joker = self->joker;
    dstIndexRange->exclusive = self->exclusive;
  }//end if (result && dstIndexRange)
  return result;
}
//end moveTo:

-(BOOL) isEmpty
{
  BOOL result = !self->range.length;
  return result;
}
//end isEmpty

-(BOOL) isTerminal
{
  return YES;
}
//end isTerminal

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (self->joker)
    [stream writeString:@"*"];
  else//if (!self->joker)
  {
    [stream writeString:[NSString stringWithFormat:@"%@", @(self->range.location)]];
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_STRING)
      [stream writeString:(self->joker ? @"*" : self->exclusive ? @" ..< " : @" ... ")];
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING)
      [stream writeString:(self->joker ? @"*" : self->exclusive ? @" .. <" : @" ... ")];
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
      [stream writeString:(self->joker ? @"*" : self->exclusive ? @"&nbsp;..&lt;&nbsp;" : @"&nbsp;...&nbsp;")];
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
      [stream writeString:(self->joker ? @"*" : self->exclusive ? @"&nbsp;..&lt;&nbsp;" : @"&nbsp;...&nbsp;")];
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
      [stream writeString:(self->joker ? @"*" : self->exclusive ? @"\\textrm{ ..< }" : @"\\textrm{ ... }")];
    if (!self->range.length || self->exclusive)
      [stream writeString:[NSString stringWithFormat:@"%@", @(self->range.location+self->range.length)]];
    else
      [stream writeString:[NSString stringWithFormat:@"%@", @(self->range.location+self->range.length-1)]];
  }//end if (!self->joker)
}
//end writeBodyToStream:description:

@end
