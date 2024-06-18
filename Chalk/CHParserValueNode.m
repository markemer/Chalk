//
//  CHParserValueNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNode.h"

#import "CHChalkToken.h"
#import "CHChalkValueBoolean.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserValueNode

-(BOOL) isPredicate
{
  BOOL result = ([self->evaluatedValue dynamicCastToClass:[CHChalkValueBoolean class]] != nil);
  return result;
}
//end isPredicate

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, self->token.value]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
    [super writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeBodyToStream:context:options:

@end
