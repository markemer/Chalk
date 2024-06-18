//
//  CHChalkValueString.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueString.h"

#import "CHChalkContext.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHParser.h"
#import "CHParserNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"
#import "NSString+HTML.h"

@implementation CHChalkValueString

@synthesize stringValue;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithToken:(CHChalkToken*)aToken string:(NSString*)string context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->stringValue = [string copy];
  return self;
}
//end initWithToken:string:context:

-(void) dealloc
{
  [self->stringValue release];
  [super dealloc];
}
//end dealloc

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->stringValue = [[aDecoder decodeObjectOfClass:[NSString class] forKey:@"stringValue"] copy];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->stringValue forKey:@"stringValue"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueString* result = [super copyWithZone:zone];
  if (result)
  {
    result->stringValue = [self->stringValue copy];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueString* dstString = !result ? nil : [dst dynamicCastToClass:[CHChalkValueString class]];
  if (result && dstString)
  {
    [dstString->stringValue release];
    dstString->stringValue = self->stringValue;
    self->stringValue = nil;
  }//end if (result && dstString)
  return result;
}
//end moveTo:

-(BOOL) isTerminal
{
  return YES;
}
//end isTerminal

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSString* string = self->stringValue;
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    string = [NSString stringWithFormat:@"\\textrm{%@}",
      [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    string = [string encodeHTMLCharacterEntities];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    string = [string encodeHTMLCharacterEntities];
  [stream writeString:string];
}
//end writeBodyToStream:context:description:

@end
