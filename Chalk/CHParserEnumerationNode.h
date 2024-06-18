//
//  CHParserEnumerationNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

#import "CHParserSubscriptNode.h"

@interface CHParserEnumerationNode : CHParserNode <CHParserNodeSubscriptable, NSCopying>

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
