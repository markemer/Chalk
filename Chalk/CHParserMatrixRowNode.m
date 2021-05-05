//
//  CHParserMatrixRowNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserMatrixRowNode.h"

#import "CHChalkValue.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserMatrixRowNode

-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if (idx)
        [stream writeString:@" & "];
      CHParserNode* element = [obj dynamicCastToClass:[CHParserNode class]];
      [element writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@"\\\\"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    [stream writeString:@"<mtr>"];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserNode* element = [obj dynamicCastToClass:[CHParserNode class]];
      [stream writeString:@"<mtd>"];
      [element writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
      [stream writeString:@"</mtd>"];
    }];
    [stream writeString:@"</mtr>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    [stream writeString:@"<tr>"];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserNode* element = [obj dynamicCastToClass:[CHParserNode class]];
      [stream writeString:@"<td>"];
      [element writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
      [stream writeString:@"</td>"];
    }];
    [stream writeString:@"</tr>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  else
  {
    [stream writeString:@"("];
    [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHParserNode* element = [obj dynamicCastToClass:[CHParserNode class]];
      if (idx)
        [stream writeString:@","];
      [element writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    }];
    [stream writeString:@")"];
  }//end if (...)
}
//end writeToStream:context:options:

@end
