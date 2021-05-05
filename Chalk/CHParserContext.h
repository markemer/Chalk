//
//  CHParserContext.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHParser;
@class CHParserContext;
@class CHParserNode;

@protocol CHParserFeeding
-(NSUInteger) feedBuffer:(char*)buffer length:(NSUInteger)length;
@end

@protocol CHParserListener
-(void) parserContext:(CHParserContext*)parserContext didEncounterRootNode:(CHParserNode*)node;
@end

@interface CHParserContext : NSObject {
  void* internalParser;
  NSRange lastTokenRange;
  BOOL stop;
}

@property(nonatomic,readonly) void* internalParser;
@property(nonatomic) NSRange lastTokenRange;
@property(nonatomic) BOOL stop;
@property(nonatomic,assign) id<CHParserFeeding> parserFeeder;
@property(nonatomic,assign) id<CHParserListener> parserListener;

-(instancetype) init;

-(void) reset;

@end
