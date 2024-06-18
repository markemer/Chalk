//
//  CHChalkValueList.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueList.h"

#import "CHStreamWrapper.h"
#import "CHPresentationConfiguration.h"

@implementation CHChalkValueList

+(BOOL) supportsSecureCoding {return YES;}

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mfenced open=\"{\" close=\"}\" separators=\",\">"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\{"];
  else
    [stream writeString:@"{"];
}
//end writeHeaderToStream:context:description:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mfenced>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\}"];
  else
    [stream writeString:@"}"];
}
//end writeFooterToStream:context:description:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [super writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeBodyToStream:description:

@end
