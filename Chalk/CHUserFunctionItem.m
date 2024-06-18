//
//  CHUserFunctionItem.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUserFunctionItem.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifierConstant.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierFunction.h"
#import "CHParser.h"
#import "CHParserNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUserFunctionEntity.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

NSString* CHUserFunctionItemNameKey = @"name";
NSString* CHUserFunctionItemDefinitionKey = @"definition";
NSString* CHUserFunctionItemArgumentNamesDependencyKey = @"argumentNames";

@implementation CHUserFunctionItem

@dynamic    isProtected;
@synthesize identifier;
@synthesize argumentNames;
@synthesize definition;
@dynamic    inputWithAssignation;
@dynamic    name;
@synthesize chalkContext;

+(void) initialize
{
  [self exposeBinding:CHUserFunctionItemNameKey];
  [self exposeBinding:CHUserFunctionItemDefinitionKey];
  [self exposeBinding:CHUserFunctionItemArgumentNamesDependencyKey];
}
//end initialize

-(instancetype) initWithUserFunctionEntity:(CHUserFunctionEntity*)aUserFunctionEntity context:(CHChalkContext*)aChalkContext
{
  if (!((self = [super init])))
    return nil;
  self->userFunctionEntity = [aUserFunctionEntity retain];
  self->chalkContext = [aChalkContext retain];
  self->identifier = [[[self->chalkContext.identifierManager identifierForName:userFunctionEntity.identifierName createClass:[CHChalkIdentifierFunction class]] dynamicCastToClass:[CHChalkIdentifierFunction class]] retain];
  self->argumentNames = [[self->userFunctionEntity.argumentNames componentsSeparatedByString:@";" allowEmpty:NO] retain];
  self->definition = [self->userFunctionEntity.inputRawString copy];
  self->identifier.argsPossibleCount = NSMakeRange(self->argumentNames.count, 1);
  self->identifier.argumentNames = self->argumentNames;
  self->identifier.definition = self->definition;
  return self;
}
//end initWithUserFunctionEntity:

-(instancetype) initWithIdentifier:(CHChalkIdentifierFunction*)aIdentifier context:(CHChalkContext*)aChalkContext managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
  if (!((self = [super init])))
    return nil;
  self->identifier = [aIdentifier retain];
  self->argumentNames = [self->identifier.argumentNames copy];
  self->definition = [self->identifier.definition copy];
  self->chalkContext = [aChalkContext retain];
  if (managedObjectContext)
  {
    self->userFunctionEntity =
      [[CHUserFunctionEntity alloc] initWithEntity:[NSEntityDescription entityForName:[CHUserFunctionEntity entityName] inManagedObjectContext:managedObjectContext]
        insertIntoManagedObjectContext:managedObjectContext];
    self->userFunctionEntity.identifierName = self->identifier.name;
    self->userFunctionEntity.inputRawString = self->definition;
    self->userFunctionEntity.argumentNames = [self->argumentNames componentsJoinedByString:@";"];
  }//end if (managedObjectContext)
  return self;
}
//end initWithIdentifier:context:managedObjectContext:

-(void) dealloc
{
  [self->identifier release];
  [self->definition release];
  [self->argumentNames release];
  [self->chalkContext release];
  [self->userFunctionEntity release];
  [super dealloc];
}
//end dealloc

-(NSString*) inputWithAssignation
{
  NSString* result = [NSString stringWithFormat:@"%@(%@)%@%@",
    self->identifier.name,
    [self->argumentNames componentsJoinedByString:@","],
    @":=",
    self.definition];
  return result;
}
//end inputWithAssignation

-(void) reset
{
  [self->argumentNames release];
  self->argumentNames = nil;
  [self->definition release];
  self->definition = nil;
  self->userFunctionEntity.inputRawString = nil;
  self->userFunctionEntity.argumentNames = nil;
}
//end reset

-(void) removeFromManagedObjectContext
{
  [self.chalkContext.undoManager beginUndoGrouping];
  [[self->userFunctionEntity managedObjectContext] deleteObject:self->userFunctionEntity];
  [self->userFunctionEntity release];
  self->userFunctionEntity = nil;
  [self.chalkContext.undoManager endUndoGrouping];
}
//end removeFromManagedObjectContext

-(BOOL) isProtected
{
  BOOL result = [[CHChalkIdentifierManager defaultIdentifiersFunctions] containsObject:self->identifier];
  return result;
}
//end isProtected

-(NSString*) name
{
  NSString* result = self->identifier.name;
  return result;
}
//end name

-(void) update:(CHChalkIdentifierFunction*)aIdentifier
{
  if (self->identifier == aIdentifier)
  {
    [self->argumentNames release];
    self->argumentNames = [self->identifier.argumentNames copy];
    [self->definition release];
    self->definition = [self->identifier.definition copy];
    self->userFunctionEntity.inputRawString = self->definition;
    self->userFunctionEntity.argumentNames = [self->argumentNames componentsJoinedByString:@";"];
  }//end if (self->identifier == aIdentifier)
}
//end update:

@end
