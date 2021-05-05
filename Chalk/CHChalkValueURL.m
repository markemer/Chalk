//
//  CHChalkValueURL.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueURL.h"

#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"
#import "NSString+HTML.h"

@implementation CHChalkValueURL

@synthesize url;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithToken:(CHChalkToken*)aToken url:(NSString*)aURL context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->url = [aURL copy];
  return self;
}
//end initWithToken:url:context:

-(void) dealloc
{
  [self->url release];
  [super dealloc];
}
//end dealloc

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->url = [[aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"] copy];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->url forKey:@"url"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueURL* result = [super copyWithZone:zone];
  if (result)
  {
    result->url = [self->url copy];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueURL* dstURL = !result ? nil : [dst dynamicCastToClass:[CHChalkValueURL class]];
  if (result && dstURL)
  {
    [dstURL->url release];
    dstURL->url = self->url;
    self->url = nil;
  }//end if (result && dstURL)
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
  NSString* string = [self->url absoluteString];
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
//end writeBodyToStream:context:options:

@end
