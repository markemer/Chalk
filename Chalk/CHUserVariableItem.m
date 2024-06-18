//
//  CHUserVariableItem.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUserVariableItem.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifierConstant.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierVariable.h"
#import "CHParser.h"
#import "CHParserNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUserVariableEntity.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

NSString* CHUserVariableItemNameKey = @"name";
NSString* CHUserVariableItemIsDynamicKey = @"isDynamic";
NSString* CHUserVariableItemEvaluatedValueKey = @"evaluatedValue";
NSString* CHUserVariableItemEvaluatedValueAttributedStringKey = @"evaluatedValueAttributedString";
NSString* CHUserVariableItemHasCircularDependencyKey = @"hasCircularDependency";

@implementation CHUserVariableItem


@dynamic    isWriteProtected;
@dynamic    isDeleteProtected;
@synthesize identifier;
@synthesize isDynamic;
@synthesize input;
@dynamic    inputWithAssignation;
@synthesize chalkParserNode;
@synthesize chalkContext;
@synthesize parseError;
@synthesize hasCircularDependency;
@dynamic    name;
@synthesize evaluatedValue;
@dynamic    evaluatedValueAttributedString;
@dynamic    dependingIdentifiers;

+(void) initialize
{
  [self exposeBinding:CHUserVariableItemNameKey];
  [self exposeBinding:CHUserVariableItemIsDynamicKey];
  [self exposeBinding:CHUserVariableItemEvaluatedValueKey];
  [self exposeBinding:CHUserVariableItemHasCircularDependencyKey];
}
//end initialize

+(NSSet*) keyPathsForValuesAffectingEvaluatedValueAttributedString
{
  NSSet* result = [NSSet setWithObjects:CHUserVariableItemEvaluatedValueKey, nil];
  return result;
}
//end keyPathsForValuesAffectingEvaluatedValueAttributedString

-(instancetype) initWithUserVariableEntity:(CHUserVariableEntity*)aUserVariableEntity context:(CHChalkContext*)aChalkContext
{
  if (!((self = [super init])))
    return nil;
  self->userVariableEntity = [aUserVariableEntity retain];
  self->isDynamic = self->userVariableEntity.isDynamic;
  self->chalkContext = [aChalkContext retain];
  NSString* identifierClassName = self->userVariableEntity.identifierClassName;
  Class identifierClass = NSClassFromString(identifierClassName);
  Class requestedClass = [CHChalkIdentifier class];
  Class defaultClass = [CHChalkIdentifierVariable class];
  Class safeIdentifierClass = ![identifierClass isSubclassOfClass:requestedClass] ? defaultClass : identifierClass;
  self->identifier = [[self->chalkContext.identifierManager identifierForName:userVariableEntity.identifierName createClass:safeIdentifierClass] retain];
  self->chalkParser = [[CHParser alloc] init];
  self->input = [self->userVariableEntity.inputRawString copy];
  self->evaluatedValue = [self->userVariableEntity.chalkValue1 retain];
  return self;
}
//end initWithUserVariableEntity:

-(instancetype) initWithIdentifier:(CHChalkIdentifier*)aIdentifier isDynamic:(BOOL)aIsDynamic input:(NSString*)aInput evaluatedValue:(CHChalkValue*)aEvaluatedValue context:(CHChalkContext*)aChalkContext managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
  if (!((self = [super init])))
    return nil;
  self->identifier = [aIdentifier retain];
  self->isDynamic = aIsDynamic;
  self->input = [aInput copy];
  self->evaluatedValue = [aEvaluatedValue copy];
  self->chalkContext = [aChalkContext retain];
  self->chalkParser = [[CHParser alloc] init];
  if (managedObjectContext)
  {
    self->userVariableEntity =
      [[CHUserVariableEntity alloc] initWithEntity:[NSEntityDescription entityForName:[CHUserVariableEntity entityName] inManagedObjectContext:managedObjectContext]
        insertIntoManagedObjectContext:managedObjectContext];
    self->userVariableEntity.inputRawString = self->input;
    NSString* identifierClassName = [self->identifier className];
    self->userVariableEntity.identifierClassName = identifierClassName;
    self->userVariableEntity.identifierName = self->identifier.name;
    self->userVariableEntity.chalkValue1 = self->evaluatedValue;
  }//end if (managedObjectContext)
  return self;
}
//end initWithIdentifier:context:managedObjectContext:

-(void) dealloc
{
  [self->identifier release];
  [self->input release];
  [self->chalkParser release];
  [self->chalkParserNode release];
  [self->evaluatedValue release];
  [self->parseError release];
  [self->chalkContext release];
  [self->userVariableEntity release];
  [super dealloc];
}
//end dealloc

-(BOOL) isDynamic
{
  BOOL result = self->userVariableEntity ? self->userVariableEntity.isDynamic : self->isDynamic;
  return result;
}
//end isDynamic

-(void) setIsDynamic:(BOOL)value
{
  if (value != self->isDynamic)
  {
    [self.chalkContext.undoManager beginUndoGrouping];
    [[self.chalkContext.undoManager prepareWithInvocationTarget:self] setIsDynamic:self->isDynamic];
    [self willChangeValueForKey:CHUserVariableItemIsDynamicKey];
    self->isDynamic = value;
    self->userVariableEntity.isDynamic = self->isDynamic;
    [self didChangeValueForKey:CHUserVariableItemIsDynamicKey];
    [self propagateValue:@(self.isDynamic) forBinding:CHUserVariableItemIsDynamicKey];
    [self.chalkContext.undoManager endUndoGrouping];
  }//end if (value != self->isDynamic)
}
//end setIsDynamic:

-(void) setInput:(NSString*)value parse:(BOOL)parse evaluate:(BOOL)evaluate
{
  if (![NSString string:value equals:self->input])
  {
    [self.chalkContext.undoManager beginUndoGrouping];
    [self reset];
    self->input = [value copy];
    self->userVariableEntity.inputRawString = self->input;
    if (parse)
    {
      [self performParsing];
      if (evaluate)
        [self performEvaluation];
    }//end if (parse)
    [self.chalkContext.undoManager endUndoGrouping];
  }//end if (![NSString string:value equals:self->input])
}
//end setInput:parse:evaluate:

-(void) setInput:(NSString*)value parserNode:(CHParserNode*)parserNode
{
  [self.chalkContext.undoManager beginUndoGrouping];
  if (![self->input isEqualToString:value])
  {
    [self reset];
    self->input = [value copy];
    self->userVariableEntity.inputRawString = self->input;
  }//end if (![self->input isEqualToString:value])
  if (parserNode != self->chalkParserNode)
  {
    [self->chalkParserNode release];
    self->chalkParserNode = [parserNode retain];
  }//end if (parserNode != self->chalkParserNode)
  self.evaluatedValue = self->chalkParserNode.evaluatedValue;
  [self.chalkContext.undoManager endUndoGrouping];
}
//end setInput:parserNode:

-(NSString*) inputWithAssignation
{
  NSString* result = [NSString stringWithFormat:@"%@%@%@",
    self->identifier.name,
    //self->isDynamic ? @"\u219E" : @"\u2190",
    self->isDynamic ? @"::=" : @":=",
    self.input];
  return result;
}
//end inputWithAssignation

-(void) reset
{
  self->hasCircularDependency = NO;
  [self->input release];
  self->input = nil;
  self->userVariableEntity.inputRawString = nil;
  self->userVariableEntity.chalkValue1 = nil;
  [self->chalkParserNode release];
  self->chalkParserNode = nil;
  [self->parseError release];
  self->parseError = nil;
  [self->evaluatedValue release];
  self->evaluatedValue = nil;
}
//end reset

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
  if (self->parseError)
    [self->chalkContext.identifierManager removeValueForIdentifier:self->identifier];
  [[NSNotificationCenter defaultCenter] postNotificationName:CHChalkParseDidEndNotification object:self];    
}
//end performParsing

-(void) performEvaluation
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
  [self->chalkContext.errorContext reset:nil];
  [self->chalkParserNode performEvaluationWithContext:self->chalkContext lazy:NO];
  chalkGmpFlagsRestore(oldFlags);
  self.evaluatedValue = self->chalkParserNode.evaluatedValue;
  [[NSNotificationCenter defaultCenter] postNotificationName:CHChalkEvaluationDidEndNotification object:self];
}
//end performEvaluation

-(void) removeFromManagedObjectContext
{
  [self.chalkContext.undoManager beginUndoGrouping];
  [[self->userVariableEntity managedObjectContext] deleteObject:self->userVariableEntity];
  [self->userVariableEntity release];
  self->userVariableEntity = nil;
  [self.chalkContext.undoManager endUndoGrouping];
}
//end removeFromManagedObjectContext

-(void) parserContext:(CHParserContext*)parserContext didEncounterRootNode:(CHParserNode*)node
{
  [self->chalkParserNode release];
  self->chalkParserNode = [node retain];
}
//end parserContext:didEncounterRootNode:

-(BOOL) isWriteProtected
{
  BOOL result = self->identifier &&
    ![self->identifier isKindOfClass:[CHChalkIdentifierVariable class]];
  return result;
}
//end isWriteProtected

-(BOOL) isDeleteProtected
{
  BOOL result = self->identifier &&
    ![self->identifier isKindOfClass:[CHChalkIdentifierVariable class]] &&
    ![self->identifier isKindOfClass:[CHChalkIdentifierConstant class]];
  return result;
}
//end isDeleteProtected

-(NSString*) name
{
  NSString* result = self->identifier.name;
  return result;
}
//end name

-(void) setName:(NSString*)value
{
  if (![NSString isNilOrEmpty:value] && ![value isEqualToString:self.name])
  {
    [self.chalkContext.undoManager beginUndoGrouping];
    CHChalkIdentifierManager* identifierManager = self->chalkContext.identifierManager;
    CHChalkIdentifier* newIdentifier = [[CHChalkIdentifierVariable alloc] initWithName:value caseSensitive:YES tokens:@[value] symbol:value symbolAsText:value symbolAsTeX:value];
    BOOL added = newIdentifier && [identifierManager addIdentifier:newIdentifier replace:NO preventTokenConflict:YES];
    if (added)
    {
      [self willChangeValueForKey:CHUserVariableItemNameKey];
      id oldValue = [identifierManager valueForIdentifier:self->identifier];
      [identifierManager setValue:oldValue forIdentifier:newIdentifier];
      [self->chalkContext.identifierManager removeIdentifier:self->identifier];
      [self->identifier release];
      self->identifier = [newIdentifier retain];
      self->userVariableEntity.identifierName = self->identifier.name;
      [self didChangeValueForKey:CHUserVariableItemNameKey];
      [self propagateValue:self.name forBinding:CHUserVariableItemNameKey];
    }//end if (added)
    [newIdentifier release];
    [self.chalkContext.undoManager endUndoGrouping];
  }//end if (![NSString isNilOrEmpty:value] && ![value isEqualToString:self.name])
}
//end setName:

-(void) setEvaluatedValue:(CHChalkValue*)value
{
  [self.chalkContext.undoManager beginUndoGrouping];
  [self->evaluatedValue release];
  self->evaluatedValue = [value retain];
  self->userVariableEntity.chalkValue1 = self->evaluatedValue;
  [self willChangeValueForKey:CHUserVariableItemEvaluatedValueKey];
  [self->chalkContext.identifierManager setValue:self->evaluatedValue forIdentifier:self->identifier];
  [self didChangeValueForKey:CHUserVariableItemEvaluatedValueKey];
  [self propagateValue:self.evaluatedValue forBinding:CHUserVariableItemEvaluatedValueKey];
  [self.chalkContext.undoManager endUndoGrouping];
}
//end setEvaluatedValue:

-(NSAttributedString*) evaluatedValueAttributedString
{
  NSAttributedString* result = nil;
  self->chalkContext.outputRawToken = NO;
  CHStreamWrapper* stream = [[[CHStreamWrapper alloc] init] autorelease];
  NSMutableAttributedString* outputAttributedString = [[[NSMutableAttributedString alloc] init] autorelease];
  stream.attributedStringStream = outputAttributedString;
  if (self->parseError)
    [stream writeString:self->parseError.friendlyDescription];
  else if (self->chalkContext.errorContext.error)
    [stream writeString:self->chalkContext.errorContext.error.friendlyDescription];
  else//if (!self->parseError)
  {
    CHPresentationConfiguration* presentationConfiguration =
      [CHPresentationConfiguration presentationConfigurationWithDescription:CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING];
    [self->evaluatedValue writeToStream:stream context:self->chalkContext presentationConfiguration:presentationConfiguration];
  }//end if (!self->parseError)
  NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  paragraphStyle.alignment = NSRightTextAlignment;
  [outputAttributedString addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle}
   range:NSMakeRange(0, outputAttributedString.length)];
  result = [[outputAttributedString copy] autorelease];
  return result;
}
//end evaluatedValueAttributedString

#pragma mark CHChalkIdentifierDependent
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
