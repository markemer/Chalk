//
//  CHParser.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParser.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHParserContext.h"
#import "CHParseConfiguration.h"
#import "CHUtils.h"

#import "chalk-parser.h"
#import "chalk-parser-rpn.h"

NSString* CHChalkParseDidEndNotification = @"CHChalkParseDidEndNotification";
NSString* CHChalkEvaluationDidEndNotification = @"CHChalkEvaluationDidEndNotification";

extern void chalk_scan_buffer(const char* bytes, NSUInteger length, CHParserContext* context);
extern void chalk_scan_nsstring(NSString* input, CHParserContext* context);
extern void chalk_scan_file(FILE* file, CHParserContext* context);
extern void chalk_scan_fileDescriptor(int fd, CHParserContext* context);
extern void chalk_scan(CHParserContext* context);
extern void chalk_scan_rpn_buffer(const char* bytes, NSUInteger length, CHParserContext* context);
extern void chalk_scan_rpn_nsstring(NSString* input, CHParserContext* context);
extern void chalk_scan_rpn_file(FILE* file, CHParserContext* context);
extern void chalk_scan_rpn_fileDescriptor(int fd, CHParserContext* context);
extern void chalk_scan_rpn(CHParserContext* context);

extern void Parse(void *yyp, int yymajor, CHChalkToken* token, CHParserContext* context);
extern void Parse_rpn(void *yyp, int yymajor, CHChalkToken* token, CHParserContext* context);

void tokenizerEmit(int tokenId, const unsigned char* input, size_t length, NSRange range, CHParserContext* context)
{
  void* internalParser = context.internalParser;
  BOOL shouldStop = context.stop;
  if (shouldStop)
    Parse(internalParser, 0, 0, context);
  else//if (!shouldStop)
  {
    context.lastTokenRange = range;
    NSString* tokenValue = [[[NSString alloc] initWithBytes:input length:length encoding:NSUTF8StringEncoding] autorelease];
    CHChalkToken* token = [CHChalkToken chalkTokenWithValue:tokenValue range:range];
    Parse(internalParser, tokenId, token, context);
  }//end if (!shouldStop)
}
//end tokenizerEmit()

void tokenizerEmit_rpn(int tokenId, const unsigned char* input, size_t length, NSRange range, CHParserContext* context)
{
  void* internalParser = context.internalParser;
  BOOL shouldStop = context.stop;
  if (shouldStop)
    Parse_rpn(internalParser, 0, 0, context);
  else//if (!shouldStop)
  {
    context.lastTokenRange = range;
    NSString* tokenValue = [[[NSString alloc] initWithBytes:input length:length encoding:NSUTF8StringEncoding] autorelease];
    NSString* tokenValueTrimmed = [tokenValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRange tokenValueTrimmedSubRange = [tokenValue rangeOfString:tokenValueTrimmed];
    NSRange tokenValueTrimmedRange = NSRangeShift(range, tokenValueTrimmedSubRange.location);
    CHChalkToken* token = [CHChalkToken chalkTokenWithValue:tokenValueTrimmed range:tokenValueTrimmedRange];
    Parse_rpn(internalParser, tokenId, token, context);
  }//end if (!shouldStop)
}
//end tokenizerEmit_rpn()

@implementation CHParser

@dynamic rootNodes;

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->parserContext = [[CHParserContext alloc] init];
  self->rootNodes = [[NSMutableArray alloc] init];
  return self;
}
//end init

-(void) dealloc
{
  [self->parserContext release];
  [self->rootNodes release];
  [super dealloc];
}
//end dealloc

-(NSArray*) rootNodes
{
  NSArray* result = [[self->rootNodes copy] autorelease];
  return result;
}
//end rootNodes

-(void) reset
{
  [self->parserContext reset];
  [self->rootNodes removeAllObjects];
}
//end reset

-(void) parseTo:(id<CHParserListener>)parserListener fromString:(NSString*)input context:(CHChalkContext*)context
{
  [self reset];
  self->parserContext.parserFeeder = nil;
  self->parserContext.parserListener = parserListener;
  switch(context.parseConfiguration.parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      self->parserContext.stop = YES;
      break;
    case CHALK_PARSE_MODE_INFIX:
      chalk_scan_nsstring(input, self->parserContext);
      Parse(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
    case CHALK_PARSE_MODE_RPN:
      chalk_scan_rpn_nsstring(input, self->parserContext);
      Parse_rpn(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
  }//end switch(context.parseConfiguration.parseMode)
  if (self->parserContext.stop)
  {
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:self->parserContext.lastTokenRange] replace:NO];
    DebugLog(1, @"parse error at range %@", NSStringFromRange(self->parserContext.lastTokenRange));
  }//end if (self->parserContext.stop)
}
//end parseTo:fromString:context:

-(void) parseTo:(id<CHParserListener>)parserListener fromData:(NSData*)input context:(CHChalkContext*)context
{
  [self reset];
  self->parserContext.parserFeeder = nil;
  self->parserContext.parserListener = parserListener;
  switch(context.parseConfiguration.parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      self->parserContext.stop = YES;
      break;
    case CHALK_PARSE_MODE_INFIX:
      chalk_scan_buffer(input.bytes, input.length, self->parserContext);
      Parse(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
    case CHALK_PARSE_MODE_RPN:
      chalk_scan_rpn_buffer(input.bytes, input.length, self->parserContext);
      Parse_rpn(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
  }//end switch(context.parseConfiguration.parseMode)
  if (self->parserContext.stop)
  {
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:self->parserContext.lastTokenRange] replace:NO];
    DebugLog(1, @"parse error at range %@", NSStringFromRange(self->parserContext.lastTokenRange));
  }//end if (self->parserContext.stop)
}
//end parseTo:fromData:context:

-(void) parseTo:(id<CHParserListener>)parserListener fromFile:(FILE*)input context:(CHChalkContext*)context
{
  [self reset];
  self->parserContext.parserFeeder = nil;
  self->parserContext.parserListener = parserListener;
  switch(context.parseConfiguration.parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      self->parserContext.stop = YES;
      break;
    case CHALK_PARSE_MODE_INFIX:
      chalk_scan_file(input, self->parserContext);
      Parse(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
    case CHALK_PARSE_MODE_RPN:
      chalk_scan_rpn_file(input, self->parserContext);
      Parse_rpn(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
  }//end switch(context.parseConfiguration.parseMode)
  if (self->parserContext.stop)
  {
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:self->parserContext.lastTokenRange] replace:NO];
    DebugLog(1, @"parse error at range %@", NSStringFromRange(self->parserContext.lastTokenRange));
  }//end if (self->parserContext.stop)
}
//end parseTo:fromFile:context:

-(void) parseTo:(id<CHParserListener>)parserListener fromFileDescriptor:(int)input context:(CHChalkContext*)context
{
  [self reset];
  self->parserContext.parserFeeder = nil;
  self->parserContext.parserListener = parserListener;
  switch(context.parseConfiguration.parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      self->parserContext.stop = YES;
      break;
    case CHALK_PARSE_MODE_INFIX:
      chalk_scan_fileDescriptor(input, self->parserContext);
      Parse(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
    case CHALK_PARSE_MODE_RPN:
      chalk_scan_rpn_fileDescriptor(input, self->parserContext);
      Parse_rpn(self->parserContext.internalParser, 0, 0, self->parserContext);//flush
      break;
  }//end switch(context.parseConfiguration.parseMode)
  if (self->parserContext.stop)
  {
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:self->parserContext.lastTokenRange] replace:NO];
    DebugLog(1, @"parse error at range %@", NSStringFromRange(self->parserContext.lastTokenRange));
  }//end if (self->parserContext.stop)
}
//end parseTo:fromFileDescriptor:context:

-(void) parseTo:(id<CHParserListener>)parserListener from:(id<CHParserFeeding>)parserFeeder withContext:(CHChalkContext*)context
{
  [self reset];
  self->parserContext.parserFeeder = parserFeeder;
  self->parserContext.parserListener = parserListener;
  switch(context.parseConfiguration.parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      self->parserContext.stop = YES;
      break;
    case CHALK_PARSE_MODE_INFIX:
      chalk_scan(self->parserContext);
      break;
    case CHALK_PARSE_MODE_RPN:
      chalk_scan_rpn(self->parserContext);
      break;
  }//end switch(context.parseConfiguration.parseMode)
  if (self->parserContext.stop)
  {
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:self->parserContext.lastTokenRange] replace:NO];
    DebugLog(1, @"parse error at range %@", NSStringFromRange(self->parserContext.lastTokenRange));
  }//end if (self->parserContext.stop)
}
//end parseTo:from:context:

#pragma mark CHParserListener
-(void) parserContext:(CHParserContext*)parserContext didEncounterRootNode:(CHParserNode*)node
{
  if (node)
    [self->rootNodes addObject:node];
}
//end parserContext:didEncounterRootNode:

@end
