//
//  CHParserNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHParserFunctionNode.h"
#import "CHParserIdentifierNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSIndexSetExtended.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"
#import "NSString+HTML.h"

@implementation CHParserNode

@synthesize token;
@synthesize parent;
@synthesize children;
@synthesize evaluatedValue;
@synthesize evaluationComputeFlags;
@dynamic    evaluationComputeFlagsCumulated;
@dynamic    isTerminal;
@dynamic    isPredicate;
@dynamic    evaluationErrors;

+(instancetype) parserNodeWithToken:(CHChalkToken*)token
{
  return [[[[self class] alloc] initWithToken:token] autorelease];
}
//end parserNode

-(instancetype) initWithToken:(CHChalkToken*)aToken
{
  if(!((self = [super init])))
    return nil;
  self->token = [aToken copy];
  self->children = [[NSMutableArray alloc] init];
  self->evaluationErrors = [[NSMutableArray alloc] init];
  self->evaluationComputeFlags = CHALK_COMPUTE_FLAG_NONE;
  return self;
}
//end initWithToken:

-(void) dealloc
{
  [self->token release];
  [self->evaluatedValue release];
  [self->children release];
  [self->evaluationErrors release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHParserNode* result = [[[self class] allocWithZone:zone] initWithToken:self->token];
  if (result)
  {
    result->parent = self.parent;
    __block BOOL error = NO;
    NSUInteger childCount = self->children.count;
    while(childCount--)
      [result->children addObject:[NSNull null]];
    [self->children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      id childClone = [obj copyWithZone:zone];
      CHParserNode* childCloneParserNode =
        [childClone dynamicCastToClass:[CHParserNode class]];
      if (childCloneParserNode)
      {
        childCloneParserNode->parent = result;
        [result->children replaceObjectAtIndex:idx withObject:childCloneParserNode];
      }//end if (childCloneParserNode)
      else//if (!childCloneParserNode)
      {
        *stop = YES;
        error = YES;
      }//end if (!childCloneParserNode)
      [childClone release];
    }];
    if (error)
    {
      [result release];
      result = nil;
    }//end if (error)
    if (result)
    {
      [result->evaluationErrors setArray:[[self->evaluationErrors copyWithZone:zone] autorelease]];
      result->evaluatedValue = [self->evaluatedValue copyWithZone:zone];
      result->evaluationComputeFlags = self->evaluationComputeFlags;
    }//endif (result)
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) isTerminal
{
  BOOL result = (self->children.count < 2);
  return result;
}
//end isTerminal

-(BOOL) isPredicate
{
  BOOL result = NO;
  return result;
}
//end isPredicate

-(NSArray*) evaluationErrors
{
  NSArray* result = nil;
  @synchronized(self->evaluationErrors)
  {
    result = [[self->evaluationErrors copy] autorelease];
  }//end @synchronized(self->evaluationErrors)
  return result;
}
//end evaluationErrors:

-(void) addError:(CHChalkError*)error
{
  if (error)
  {
    @synchronized(self->evaluationErrors)
    {
      [self->evaluationErrors addObject:error];
    }//end @synchronized(self->evaluationErrors)
  }//end if (error)
}
//end addError:

-(void) addError:(CHChalkError*)error context:(CHChalkContext*)context
{
  [self addError:error];
  [context.errorContext setError:error replace:NO];
}
//end addError:context:

-(void) removeFromParent
{
  if (self->parent)
  {
    [self->parent->children removeObject:self];
    self->parent = nil;
  }//end if (self->parent)
}

-(void) setParent:(CHParserNode*)value
{
  if (value != self->parent)
  {
    [self removeFromParent];
    if (value)
      [value->children addObject:self];
    self->parent = value;
  }//end if (value != self->parent)
}
//end setParent:

-(void) addChild:(CHParserNode*)node
{
  if (node && (node.parent != self))
  {
    [node removeFromParent];
    node.parent = self;
  }//end if (node && (node.parent != self))
}
//end addChild:

-(chalk_compute_flags_t) evaluationComputeFlagsCumulated
{
  __block chalk_compute_flags_t result = self->evaluationComputeFlags;
  [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      result |= [obj evaluationComputeFlagsCumulated];
    }];
  return result;
}
//end evaluationComputeFlagsCumulated

-(BOOL) resetEvaluationMatchingIdentifiers:(NSSet*)identifiers identifierManager:(CHChalkIdentifierManager*)identifierManager
{
  BOOL result = NO;
  __block uint32_t hasReset = 0;
  if (identifiers)
  {
    [self->children enumerateObjectsWithOptions:NSEnumerationConcurrent
      usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* childNode = [obj dynamicCastToClass:[CHParserNode class]];
        BOOL childHasReset = [childNode resetEvaluationMatchingIdentifiers:identifiers identifierManager:identifierManager];
        OSAtomicOr32(childHasReset, &hasReset);
      }];
  }//end if (identifiers)
  if (!identifiers || hasReset)
  {
    self.evaluatedValue = nil;
    @synchronized(self->evaluationErrors)
    {
      [self->evaluationErrors removeAllObjects];
    }//end @synchronized(self->evaluationErrors)
    self->evaluationComputeFlags = CHALK_COMPUTE_FLAG_NONE;
    result = YES;
  }//end if (!identifiers || hasReset)
  return result;
}
//end resetEvaluationMatchingIdentifiers:

-(BOOL) isUsingIdentifier:(CHChalkIdentifier*)identifier identifierManager:(CHChalkIdentifierManager*)identifierManager
{
  BOOL result = NO;
  __block uint32_t isUsing = 0;
  if (identifier)
  {
    [self->children enumerateObjectsWithOptions:NSEnumerationConcurrent
      usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* childNode = [obj dynamicCastToClass:[CHParserNode class]];
        BOOL childIsUsing = [childNode isUsingIdentifier:identifier identifierManager:identifierManager];
        OSAtomicOr32(childIsUsing, &isUsing);
        if (childIsUsing)
          *stop = YES;
      }];
  }//end if (identifiers)
  result = (isUsing != 0);
  return result;
}
//end isUsingIdentifier:identifierManager:

-(void) checkFunctionIdentifiersWithContext:(CHChalkContext*)context outError:(CHChalkError**)outError
{
  NSMutableSet* set = [[NSMutableSet alloc] init];
  NSMutableArray* queue = [[NSMutableArray alloc] initWithObjects:self, nil];
  BOOL stop = !queue.count;
  while(!stop)
  {
    CHParserNode* current = [[queue objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
    [queue removeObjectAtIndex:0];
    CHParserFunctionNode* functionNode = [current dynamicCastToClass:[CHParserFunctionNode class]];
    CHChalkIdentifier* identifier = [functionNode identifierWithContext:context];
    if (functionNode && !identifier)
    {
      if (outError)
        *outError = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierFunctionUndefined range:current.token.range];
      stop = YES;
    }//end if (functionNode && !identifier)
    else if (identifier)
      [set addObject:identifier];
    else if (current)
      [queue addObjectsFromArray:current.children];
    stop |= !queue.count;
  }//end while(!stop)
  [set release];
  [queue release];
}
//end checkFunctionIdentifiersWithContext:outTokens:

-(NSSet*) dependingIdentifiersWithContext:(CHChalkContext*)context outError:(CHChalkError**)outError
{
  NSSet* result = nil;
  NSMutableSet* set = [[NSMutableSet alloc] init];
  NSMutableArray* queue = [[NSMutableArray alloc] initWithObjects:self, nil];
  BOOL stop = !queue.count;
  while(!stop)
  {
    CHParserNode* current = [[queue objectAtIndex:0] dynamicCastToClass:[CHParserNode class]];
    [queue removeObjectAtIndex:0];
    CHParserIdentifierNode* identifierNode = [current dynamicCastToClass:[CHParserIdentifierNode class]];
    CHParserFunctionNode* functionNode = [current dynamicCastToClass:[CHParserFunctionNode class]];
    CHChalkIdentifier* identifier =
      identifierNode ? [identifierNode identifierWithContext:context] :
      functionNode ? [functionNode identifierWithContext:context] :
      nil;
    if (identifierNode && !identifier)
    {
      if (outError)
        *outError = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierUndefined range:current.token.range];
      stop = YES;
    }//end if (identifierNode && !identifier)
    else if (functionNode && !identifier)
    {
      if (outError)
        *outError = [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorIdentifierFunctionUndefined range:current.token.range];
      stop = YES;
    }//end if (functionNode && !identifier)
    else if (identifierNode && identifier)
      [set addObject:identifier];
    else if (current)
      [queue addObjectsFromArray:current.children];
    stop |= !queue.count;
  }//end while(!stop)
  result = [[set copy] autorelease];
  [set release];
  [queue release];
  return result;
}
//end dependingIdentifiersWithContext:outTokens:

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [self performEvaluationWithChildren:self->children context:context lazy:lazy];
}
//end performEvaluationWithContext:lazy:

-(void) performEvaluationWithChildren:(NSArray*)customChildren context:(CHChalkContext*)context lazy:(BOOL)lazy
{
  if (!lazy || !self.evaluatedValue)
  {
    [customChildren enumerateObjectsWithOptions:(context.concurrentEvaluations ? NSEnumerationConcurrent : 0)
      usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHParserNode* childNode = [obj dynamicCastToClass:[CHParserNode class]];
        [childNode performEvaluationWithContext:context lazy:lazy];
        if (context.errorContext.hasError && stop)
          *stop = YES;
      }];
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithChildren:context:lazy:

-(void) writeDocumentHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSString* header = nil;
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    header = [NSString stringWithFormat:@"<html><head>%@</head><body><math><mrow>",
              @"<script type=\"text/javascript\""
              "src=\"http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML\"></script>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
    header = @"digraph {\n";
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    header = @"$$";
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    header = nil;
  if (header)
    [stream writeString:header];
}
//end writeDocumentHeaderToStream:context:options:

-(void) writeDocumentFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  NSString* footer = nil;
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    footer = @"</mrow></math></body></html>";
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
    footer = @"\n}";
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    footer = @"$$";
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    footer = nil;
  if (footer)
    [stream writeString:footer];
}
//end writeDocumentFooterToStream:context:options:

-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self writeHeaderToStream:stream context:context presentationConfiguration:presentationConfiguration];
  [self writeBodyToStream:stream context:context presentationConfiguration:presentationConfiguration];
  [self writeFooterToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeToStream:context:options:

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    for(CHParserNode* child in children)
    {
      NSString* childNodeIdentifier = [NSString stringWithFormat:@"_%p", child];
      [stream writeString:[NSString stringWithFormat:@"%@ -> %@;\n", selfNodeIdentifier, childNodeIdentifier]];
    }//end for each child
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeHeaderToStream:context:options:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
  {
    NSString* selfNodeIdentifier = [NSString stringWithFormat:@"_%p", self];
    [stream writeString:[NSString stringWithFormat:@"%@ [label=\"%@\"];n", selfNodeIdentifier, self.evaluatedValue]];
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_DOT)
}
//end writeFooterToStream:context:options:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (!context.outputRawToken)
    [self->evaluatedValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
  else//if (context.outputRawToken)
  {
    NSString* string = self->token.value;
    if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    {
      string = [NSString stringWithFormat:@"\\textrm{%@}",
        [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]];
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
      string = [string encodeHTMLCharacterEntities];
    else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    {
      NSMutableString* newString = [NSMutableString string];
      if (!context.errorContext.hasError)
        [newString setString:[string encodeHTMLCharacterEntities]];
      else//if (context.errorContext.hasError)
      {
        NSIndexSet* errorRanges = context.errorContext.error.ranges;
        [errorRanges enumerateRangesWithin:string.range usingBlock:^(NSRange range, BOOL inside, BOOL *stop) {
            if (inside)
              [newString appendString:@"<span class=\"errorFlag\">"];
            [newString appendString:[[string substringWithRange:range] encodeHTMLCharacterEntities]];
            if (inside)
              [newString appendString:@"</span>"];
        }];//end for each range
        string = [[newString copy] autorelease];
      }//end if (context.errorContext.hasError)
    }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:string];
  }//end if (context.outputRawToken)

  for(CHParserNode* child in children)
    [child writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeBodyToStream:context:options:

@end
