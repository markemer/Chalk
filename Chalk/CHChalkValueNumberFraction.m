//
//  CHChalkValueNumberFraction.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueNumberFraction.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueNumberGmp.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueNumberFraction

@synthesize numberValue;
@synthesize fraction;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithToken:(CHChalkToken*)aToken numberValue:(CHChalkValueNumberGmp*)aNumberValue fraction:(NSUInteger)aFraction context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->numberValue = [aNumberValue retain];
  self->fraction = aFraction;
  return self;
}
//end initWithToken:numberValue:fraction:context:

-(void) dealloc
{
  [self->numberValue release];
  [super dealloc];
}
//end dealloc

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->numberValue = [[aDecoder decodeObjectOfClass:[CHChalkValueNumberGmp class] forKey:@"numberValue"] retain];
  self->fraction = [(NSNumber*)[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"fraction"] unsignedIntegerValue];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->numberValue forKey:@"numberValue"];
  [aCoder encodeObject:@(self->fraction) forKey:@"fraction"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueNumberFraction* result = [super copyWithZone:zone];
  if (result)
  {
    result->numberValue = [self->numberValue retain];
    result->fraction = self->fraction;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueNumberFraction* dstNumberFraction = !result ? nil : [dst dynamicCastToClass:[CHChalkValueNumberFraction class]];
  if (dstNumberFraction)
  {
    [dstNumberFraction->numberValue release];
    dstNumberFraction->numberValue = self->numberValue;
    self->numberValue = nil;
    dstNumberFraction->fraction = self->fraction;
  }//end if (dstNumberFraction)
  return result;
}
//end moveTo:

-(BOOL) isZero
{
  BOOL result = !self->fraction || self->numberValue.isZero;
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
{
  BOOL result = NO;
  if (isOneIgnoringSign)
    *isOneIgnoringSign = NO;
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = NO;
  return result;
}
//end negate

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (self->evaluationErrors.count)
  {
    NSString* errorsString = [[[self->evaluationErrors valueForKey:@"friendlyDescription"] componentsJoinedByString:@","] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    {
      NSString* htmlErrorsString = [NSString stringWithFormat:@"<span class=\"errorFlag\">%@</span>", errorsString];
      NSString* htmlElementString = [NSString stringWithFormat:@"<span class=\"hasTooltip\" onmouseover=\"tooltip.show('%@');\" onmouseout=\"tooltip.hide();\">", htmlErrorsString];
      [stream writeString:htmlElementString];
    }//end
    else
      [stream writeString:errorsString];
  }//end if (self->evaluationErrors.count)
  else if (!self->evaluationErrors.count)
  {
    [self->numberValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    if (self->fraction == 100U)
      [stream writeString:@"%"];
    else if (self->fraction == 1000U)
      [stream writeString:@"\u2030"];
    else if (self->fraction == 10000U)
      [stream writeString:@"\u2031"];
    else if (self->fraction == 1000000U)
      [stream writeString:@"ppm"];
    else
      [stream writeString:[NSString stringWithFormat:@"%%%@%%", @(self->fraction)]];
  }//end if (!self->evaluationErrors.count)
}
//end writeBodyToStream:description:options:

@end
