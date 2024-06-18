//
//  CHParserIfThenElseNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 18/12/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

@interface CHParserIfThenElseNode : CHParserNode {
  CHParserNode* ifNode;
  CHParserNode* thenNode;
  CHParserNode* elseNode;
}

+(instancetype) parserNodeWithIf:(CHParserNode*)ifNode Then:(CHParserNode*)thenNode Else:(CHParserNode*)elseNode;
-(instancetype) initWithIf:(CHParserNode*)ifNode Then:(CHParserNode*)thenNode Else:(CHParserNode*)elseNode;

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
