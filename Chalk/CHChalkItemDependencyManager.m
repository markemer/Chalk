//
//  CHChalkItemDependencyManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 02/01/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkItemDependencyManager.h"

#import "NSMutableArrayExtended.h"
#import "NSMutableSetExtended.h"
#import "NSObjectExtended.h"

@implementation CHChalkItemDependencyManager

@dynamic items;

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->items = [[NSMutableArray alloc] init];
  self->identifiersWithCircularDependencies = [[NSMutableSet alloc] init];
  return self;
}
//end init

-(void) dealloc
{
  [self->items release];
  [self->identifiersWithCircularDependencies release];
  [super dealloc];
}
//end dealloc

-(NSArray*) items
{
  NSArray* result = [[self->items copy] autorelease];
  return result;
}
//end items

-(id<CHChalkIdentifierDependent>) objectForIdentifier:(CHChalkIdentifier*)identifier
{
  __block id<CHChalkIdentifierDependent> result = nil;
  [self->items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    if (identifierDependent.identifier == identifier)
      result = identifierDependent;
    *stop |= (result != nil);
  }];//end for each userVariableItem
  return result;
}
//end objectForIdentifier:

-(BOOL) addItem:(id<CHChalkIdentifierDependent>)identifierDependent
{
  BOOL result = NO;
  if (identifierDependent)
  {
    [self->items addObject:identifierDependent];
    result = YES;
  }//end if (identifierDependent)
  return result;
}
//end addItem:

-(BOOL) removeItem:(id<CHChalkIdentifierDependent>)identifierDependent
{
  BOOL result = NO;
  if (identifierDependent && [self->items containsObject:identifierDependent])
  {
    [self->items removeObject:identifierDependent];
    [self->identifiersWithCircularDependencies removeObject:identifierDependent.identifier];
    result = YES;
  }//end if (identifierDependent && [self->itemsController.arrangedObjects containsObject:identifierDependent])
  return result;
}
//end removeItem:

-(BOOL) removeItemsAtIndexes:(NSIndexSet*)indexes
{
  BOOL result = NO;
  if (indexes)
  {
    NSArray* subItems = [self->items objectsAtIndexes:indexes];
    [self->items removeObjectsAtIndexes:indexes];
    [subItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
      CHChalkIdentifier* identifier = identifierDependent.identifier;
      if (identifier)
        [self->identifiersWithCircularDependencies removeObject:identifier];
    }];//end for each userVariableItem
    result = YES;
  }//end if (indexes)
  return result;
}
//end removeItemsAtIndexes:

-(void) removeAllItems
{
  [self->items removeAllObjects];
  [self->identifiersWithCircularDependencies removeAllObjects];
}
//end removeAllItems

-(NSSet*) dependingIdentifiersFor:(id<CHChalkIdentifierDependent>)chalkIdentifierDependent recursively:(BOOL)recursively circularDependency:(BOOL*)outCircularDependency
{
  NSSet* result = nil;
  BOOL circularDependency = NO;
  if (!chalkIdentifierDependent){
  }
  else if (!recursively)
    result = chalkIdentifierDependent.dependingIdentifiers;
  else//if (recursively)
  {
    NSMutableSet* identifiersDone = [NSMutableSet set];
    NSMutableArray* queue = [NSMutableArray arrayWithArray:chalkIdentifierDependent.dependingIdentifiers.allObjects];
    BOOL stop = !queue.count;
    while(!stop)
    {
      CHChalkIdentifier* identifier = [[queue objectAtIndex:0] dynamicCastToClass:[CHChalkIdentifier class]];
      [queue removeObjectAtIndex:0];
      if (identifier)
      {
        circularDependency |= [identifiersDone containsObject:identifier];
        stop |= circularDependency;
        if (!stop)
        {
          [identifiersDone addObject:identifier];
          NSArray* dependingIdentifiers =
            [self objectForIdentifier:identifier].dependingIdentifiers.allObjects;
          if (dependingIdentifiers)
            [queue addObjectsFromArray:dependingIdentifiers];
        }//end if (!stop)
      }//end if (identifier)
      stop |= !queue.count;
    }//end while(!stop)
    result = [[identifiersDone copy] autorelease];
  }//end if (recursively)
  if (outCircularDependency)
    *outCircularDependency = circularDependency;
  return result;
}
//end dependingIdentifiersFor:recursively:circularDependency:

-(NSArray*) identifierDependentObjectsToUpdateFrom:(NSArray*)objects
{
  NSMutableArray* result = [NSMutableArray array];
  NSMutableSet* doneIdentifiers = [NSMutableSet set];
  NSMutableSet* modifiedIdentifiers = [NSMutableSet set];
  [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    CHChalkIdentifier* identifier = identifierDependent.identifier;
    if (identifier)
    {
      [modifiedIdentifiers addObject:identifier];
      [doneIdentifiers addObject:identifier];
    }//end if (identifier)
  }];//end for each object
  NSMutableArray* queue = [NSMutableArray array];
  [self->items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    if (identifierDependent)
      [queue addObject:identifierDependent];
  }];
  BOOL stop = !queue.count;
  NSUInteger iterationsWithoutRequeuing = 0;
  NSUInteger initialQueueCount = queue.count;
  while(!stop)
  {
    id head = [queue objectAtIndex:0];
    [queue removeObjectAtIndex:0];
    id<CHChalkIdentifierDependent> chalkIdentifierDependent = [head dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    CHChalkIdentifier* identifier = [head dynamicCastToClass:[CHChalkIdentifier class]];
    if (chalkIdentifierDependent && !identifier)
      identifier = chalkIdentifierDependent.identifier;
    else if (!chalkIdentifierDependent && identifier)
      chalkIdentifierDependent = [self objectForIdentifier:identifier];
    BOOL circularDependency = NO;
    NSSet* dependingIdentifiers =
      [self dependingIdentifiersFor:chalkIdentifierDependent recursively:YES circularDependency:&circularDependency];
    BOOL isDirty = (!identifier || ![doneIdentifiers containsObject:identifier]) && [dependingIdentifiers intersectsSet:modifiedIdentifiers];
    BOOL requeued = NO;
    if (!isDirty)
      [doneIdentifiers safeAddObject:identifier];
    else if (!dependingIdentifiers.count || [dependingIdentifiers intersectsSet:doneIdentifiers])
    {
      [result safeAddObject:chalkIdentifierDependent];
      [doneIdentifiers safeAddObject:identifier];
    }//end if (!dependingIdentifiers.count || [dependingIdentifiers intersectsSet:evaluatedIdentifiers])
    else if (!chalkIdentifierDependent.hasCircularDependency)
    {
      [queue safeAddObject:chalkIdentifierDependent];//retry later
      requeued = YES;
    }//end if (!chalkIdentifierDependent.hasCircularDependency)
    if (requeued)
    {
      iterationsWithoutRequeuing = 0;
      initialQueueCount = queue.count;
    }//end if (requeued)
    else
      ++iterationsWithoutRequeuing;
    stop = circularDependency || !queue.count || (initialQueueCount<iterationsWithoutRequeuing);
  }//end while(!stop)
  return [[result copy] autorelease];
}
//end identifierDependentObjectsToUpdateFrom:

-(void) updateCircularDependencies
{
  [self->identifiersWithCircularDependencies removeAllObjects];
  [self->items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    if (identifierDependent)
    {
      NSMutableSet* set = [NSMutableSet setWithSet:identifierDependent.dependingIdentifiers];
      NSMutableArray* queue = [NSMutableArray array];
      [queue addObjectsFromArray:[set allObjects]];
      BOOL hasCircularDependency = NO;
      BOOL stop = !queue.count;
      while(!stop)
      {
        CHChalkIdentifier* head = [[queue objectAtIndex:0] dynamicCastToClass:[CHChalkIdentifier class]];
        [queue removeObjectAtIndex:0];
        if (head)
          hasCircularDependency |= (head == identifierDependent.identifier);
        id<CHChalkIdentifierDependent> headItem = [self objectForIdentifier:head];
        NSSet* newDependencies = headItem.dependingIdentifiers;
        if (newDependencies)
          [queue addObjectsFromArray:newDependencies.allObjects];
        stop |= hasCircularDependency || !queue.count;
      }//end while(!stop)
      if (hasCircularDependency)
      {
        CHChalkIdentifier* identifier = identifierDependent.identifier;
        if (identifier)
          [self->identifiersWithCircularDependencies addObject:identifier];
      }//end if (hasCircularDependency)
    }//end if (identifierDependent)
  }];//end for each userVariableItem
  [self->items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> item = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    item.hasCircularDependency = item && [self->identifiersWithCircularDependencies containsObject:item.identifier];
  }];
}
//end updateCircularDependencies

-(void) updateIdentifiers:(NSArray*)identifier
{
  [identifier enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> item  = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    if ([self->items containsObject:item])
      [item refreshIdentifierDependencies];
  }];//end for each item
}
//end updateIdentifiers:

-(void) updateAllIdentifiers
{
  [self->items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> item  = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    [item refreshIdentifierDependencies];
  }];//end for each item
}
//end updateAllIdentifiers:

@end
