//
//  CHChalkItemDependencyManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 02/01/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifier.h"

@interface CHChalkItemDependencyManager : NSObject {
  NSMutableArray* items;
  NSMutableSet* identifiersWithCircularDependencies;
}

@property(readonly,copy) NSArray* items;

-(instancetype) init;
-(NSSet*) dependingIdentifiersFor:(id<CHChalkIdentifierDependent>)chalkIdentifierDependent recursively:(BOOL)recursively circularDependency:(BOOL*)outCircularDependency;
-(BOOL) addItem:(id<CHChalkIdentifierDependent>)userVariableItem;
-(BOOL) removeItem:(id<CHChalkIdentifierDependent>)userVariableItem;
-(BOOL) removeItemsAtIndexes:(NSIndexSet*)indexes;
-(void) removeAllItems;
-(id<CHChalkIdentifierDependent>) objectForIdentifier:(CHChalkIdentifier*)identifier;
-(NSArray*) identifierDependentObjectsToUpdateFrom:(NSArray*)objects;
-(void) updateCircularDependencies;
-(void) updateIdentifiers:(NSArray*)identifier;
-(void) updateAllIdentifiers;

@end
