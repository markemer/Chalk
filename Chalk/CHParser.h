//
//  CHParser.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHParserContext.h"

@class CHChalkContext;
@class CHParserContext;
@protocol CHParserFeeding;

extern NSString* CHChalkParseDidEndNotification;
extern NSString* CHChalkEvaluationDidEndNotification;

@interface CHParser : NSObject <CHParserListener> {
  CHParserContext* parserContext;
  NSMutableArray* rootNodes;
}

@property(readonly,copy) NSArray* rootNodes;

-(void) reset;

-(void) parseTo:(id<CHParserListener>)parserListener fromString:(NSString*)input context:(CHChalkContext*)context;
-(void) parseTo:(id<CHParserListener>)parserListener fromData:(NSData*)input context:(CHChalkContext*)context;
-(void) parseTo:(id<CHParserListener>)parserListener fromFile:(FILE*)input context:(CHChalkContext*)context;
-(void) parseTo:(id<CHParserListener>)parserListener fromFileDescriptor:(int)input context:(CHChalkContext*)context;
-(void) parseTo:(id<CHParserListener>)parserListener from:(id<CHParserFeeding>)parserFeeder withContext:(CHChalkContext*)context;

@end
