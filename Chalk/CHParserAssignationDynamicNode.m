//
//  CHParserAssignationDynamicNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 26/01/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserAssignationDynamicNode.h"

#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"

@implementation CHParserAssignationDynamicNode

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [stream writeString:@"<mi>"];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"</mi>"];
    [stream writeString:@"<mo>:&lt;&lt;=</mo>"];
    [stream writeString:@"<mi>"];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"</mi>"];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@"\\twoheadleftarrow{}"];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, @":<<="]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  else//if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSUInteger childCount = self->children.count;
    CHParserNode* child1 = (childCount<1) ? nil : [self->children objectAtIndex:0];
    CHParserNode* child2 = (childCount<2) ? nil : [self->children objectAtIndex:1];
    [child1 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
    [stream writeString:@":<<="];
    [child2 writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  }//end if (presentationConfiguration.description != CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeBodyToStream:context:options:

@end
