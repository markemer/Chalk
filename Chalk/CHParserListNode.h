//
//  CHParserListNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

@interface CHParserListNode : CHParserNode <NSCopying>

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
