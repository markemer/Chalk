//
//  CHParserContext.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserContext.h"

#import "NSMutableArrayExtended.h"

extern void *ParseAlloc(void *(*mallocProc)(size_t));
extern void ParseFree(void *p, void (*freeProc)(void*));

@implementation CHParserContext

@synthesize internalParser;
@synthesize lastTokenRange;
@synthesize stop;
@synthesize parserFeeder;
@synthesize parserListener;

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->internalParser = ParseAlloc(&malloc);
  return self;
}
//end initWithInternalParser:

-(void) dealloc
{
  if (self->internalParser)
    ParseFree(self->internalParser, &free);
  [super dealloc];
}
//end dealloc

-(void) reset
{
  self->stop = NO;
}
//end reset

@end
