//
//  CHUserVariableItem.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifier.h"
#import "CHParserContext.h"

@class CHChalkContext;
@class CHChalkError;
@class CHChalkValue;
@class CHParser;
@class CHParserNode;
@class CHUserVariableEntity;

extern NSString* CHUserVariableItemNameKey;
extern NSString* CHUserVariableItemIsDynamicKey;
extern NSString* CHUserVariableItemEvaluatedValueKey;
extern NSString* CHUserVariableItemEvaluatedValueAttributedStringKey;
extern NSString* CHUserVariableItemHasCircularDependencyKey;

@interface CHUserVariableItem : NSObject <CHChalkIdentifierDependent, CHParserListener> {
  CHUserVariableEntity* userVariableEntity;
  CHChalkIdentifier* identifier;
  BOOL isDynamic;
  NSString* input;
  CHParser* chalkParser;
  CHParserNode* chalkParserNode;
  CHChalkContext* chalkContext;
  CHChalkError* parseError;
  BOOL hasCircularDependency;
  CHChalkValue* evaluatedValue;
}

@property(readonly)        BOOL isProtected;

@property(readonly,retain) CHChalkIdentifier* identifier;//CHChalkIdentifierDependent
@property(nonatomic)       BOOL isDynamic;//CHChalkIdentifierDependent
@property(nonatomic,readonly,copy) NSString* input;
@property(nonatomic,readonly,copy) NSString* inputWithAssignation;
@property(readonly,assign) CHParserNode* chalkParserNode;
@property(readonly,assign) CHChalkContext* chalkContext;
@property(readonly,assign) CHChalkError* parseError;
@property                  BOOL hasCircularDependency;//CHChalkIdentifierDependent

@property(copy)             NSString* name;
@property(nonatomic,retain) CHChalkValue* evaluatedValue;
@property(readonly)         NSAttributedString* evaluatedValueAttributedString;
@property(readonly,retain)  NSSet* dependingIdentifiers;//CHChalkIdentifierDependent

-(instancetype) initWithUserVariableEntity:(CHUserVariableEntity*)userVariableEntity context:(CHChalkContext*)chalkContext;
-(instancetype) initWithIdentifier:(CHChalkIdentifier*)identifier isDynamic:(BOOL)isDynamic input:(NSString*)input evaluatedValue:(CHChalkValue*)evaluatedValue context:(CHChalkContext*)chalkContext managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

-(void) reset;
-(void) setInput:(NSString*)value parse:(BOOL)parse evaluate:(BOOL)evaluate;
-(void) setInput:(NSString*)value parserNode:(CHParserNode*)parserNode;
-(void) performParsing;
-(void) performEvaluation;

-(void) removeFromManagedObjectContext;

-(void) refreshIdentifierDependencies;//CHChalkIdentifierDependent

@end
