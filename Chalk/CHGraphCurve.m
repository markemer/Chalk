//
//  CHGraphCurve.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphCurve.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkToken.h"
#import "CHParserNode.h"
#import "CHParser.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

NSString* CHGraphCurveDidInvalidateNotification = @"CHGraphCurveDidInvalidateNotification";

@implementation CHGraphCurve

@synthesize input;
@synthesize elementPixelSize;
@synthesize visible;
@dynamic    graphMode;
@synthesize chalkParser;
@synthesize chalkParserNode;
@synthesize chalkContext;
@synthesize parseError;
@dynamic    identifier;
@dynamic    isDynamic;
@dynamic    dependingIdentifiers;
@synthesize hasCircularDependency;

+(void) initialize
{
  [self exposeBinding:@"visible"];
}
//end initialize

-(instancetype) initWithContext:(CHChalkContext*)aChalkContext
{
  if (!((self = [super init])))
    return nil;
  self->elementPixelSize = 1;
  self->chalkContext = [aChalkContext retain];
  self->chalkParser = [[CHParser alloc] init];
  return self;
}
//end initWithContext:

-(void) dealloc
{
  [self->input release];
  [self->chalkParser release];
  [self->chalkParserNode release];
  [self->chalkContext release];
  [self->parseError release];
  self.name = nil;
  [super dealloc];
}
//end dealloc

-(chgraph_mode_t) graphMode
{
  chgraph_mode_t result =
    !self->chalkParserNode ? CHGRAPH_MODE_UNDEFINED :
    self->chalkParserNode.isPredicate ? CHGRAPH_MODE_XY_PREDICATE :
    CHGRAPH_MODE_Y_FROM_X;
  return result;
}
//end graphMode

-(NSUInteger) elementPixelSize
{
  return MAX(1, self->elementPixelSize);
}
//end elementPixelSize

-(void) setElementPixelSize:(NSUInteger)value
{
  NSUInteger validValue = MAX(1, value);
  if (validValue != self->elementPixelSize)
  {
    self->elementPixelSize = validValue;
    if ([self.delegate respondsToSelector:@selector(graphCurveDidInvalidate:)])
      [self.delegate graphCurveDidInvalidate:[NSNotification notificationWithName:CHGraphCurveDidInvalidateNotification object:self]];
  }//end if (validValue != self->elementPixelSize)
}
//end setElementPixelSize:

-(void) setInput:(NSString*)value
{
  BOOL isSameValue = [NSString string:value equals:self->input];
  if (!isSameValue)
  {
    [self->input release];
    self->input = [value copy];
    [self performParsing];
  }//end if (!isSameValue)
}
//end setInput:

-(void) performParsing
{
  [self->chalkParserNode release];
  self->chalkParserNode = nil;
  [self->chalkContext.errorContext reset:nil];
  [self->chalkParser parseTo:self fromString:(!self->input ? @"" : self->input) context:self->chalkContext];
  [self->parseError release];
  self->parseError = [self->chalkContext.errorContext.error retain];
  if (!self->parseError)
  {
    [self->chalkParserNode dependingIdentifiersWithContext:self->chalkContext outError:&self->parseError];
    [self->parseError retain];
  }//end if (!self->parseError)
  [[NSNotificationCenter defaultCenter] postNotificationName:CHChalkParseDidEndNotification object:self];
}
//end performParsing

-(void) parserContext:(CHParserContext*)parserContext didEncounterRootNode:(CHParserNode*)node
{
  [self->chalkParserNode release];
  self->chalkParserNode = [node retain];
}
//end parserContext:didEncounterRootNode:

#pragma mark CHChalkIdentifierDependent
-(BOOL) isDynamic
{
  return YES;
}
//end isDynamic

-(CHChalkIdentifier*) identifier
{
  return nil;
}
//end identifier

-(NSSet*) dependingIdentifiers
{
  NSSet* result = [self->chalkParserNode dependingIdentifiersWithContext:self->chalkContext outError:nil];
  return result;
}
//end dependingIdentifiers

-(void) refreshIdentifierDependencies
{
  [self performParsing];
}
//end refreshIdentifierDependencies

-(BOOL) hasIdentifierDependency:(CHChalkIdentifier*)aIdentifier
{
  __block BOOL result = NO;
  [self.dependingIdentifiers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    result |= (aIdentifier == [obj dynamicCastToClass:[CHChalkIdentifier class]]);
    *stop |= result;
  }];//end for each identifier
  return result;
}
//end hasIdentifierDependency:

-(BOOL) hasIdentifierDependencyByTokens:(NSArray*)tokens
{
  __block BOOL result = NO;
  if (self->parseError.reason == CHChalkErrorIdentifierUndefined)
  {
    NSIndexSet* errorRanges = self->parseError.ranges;
    NSRange errorFullRange = !errorRanges || !errorRanges.count ? NSRangeZero :
      NSMakeRange(errorRanges.firstIndex, errorRanges.lastIndex-errorRanges.firstIndex+1);
    result = [tokens containsObject:[self->input substringWithRange:errorFullRange]];
  }//end if (self->parseError.reason == CHChalkErrorIdentifierUndefined)
  if (!result)
    [self.dependingIdentifiers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
      CHChalkIdentifier* aIdentifier = [obj dynamicCastToClass:[CHChalkIdentifier class]];
      [tokens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        result |= [aIdentifier matchesToken:[obj dynamicCastToClass:[NSString class]]];
        *stop |= result;
      }];
      *stop |= result;
    }];//end for each identifier
  return result;
}
//end hasIdentifierDependencyByToken:

@end
