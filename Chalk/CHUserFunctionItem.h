//
//  CHUserFunctionItem.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifierFunction.h"
#import "CHParserContext.h"

@class CHChalkContext;
@class CHUserFunctionEntity;

extern NSString* CHUserFunctionItemNameKey;
extern NSString* CHUserFunctionItemDefinitionKey;
extern NSString* CHUserFunctionItemArgumentNamesKey;

@interface CHUserFunctionItem : NSObject {
  CHUserFunctionEntity* userFunctionEntity;
  CHChalkIdentifierFunction* identifier;
  NSArray* argumentNames;
  NSString* definition;
  CHChalkContext* chalkContext;
}

@property(readonly) BOOL isProtected;

@property(readonly,retain) CHChalkIdentifierFunction* identifier;
@property(nonatomic,copy) NSArray* argumentNames;
@property(nonatomic,copy) NSString* definition;
@property(nonatomic,readonly,copy) NSString* inputWithAssignation;
@property(readonly,assign) CHChalkContext* chalkContext;

@property(nonatomic,readonly,copy) NSString* name;

-(instancetype) initWithUserFunctionEntity:(CHUserFunctionEntity*)userFunctionEntity context:(CHChalkContext*)chalkContext;
-(instancetype) initWithIdentifier:(CHChalkIdentifierFunction*)identifier context:(CHChalkContext*)chalkContext managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

-(void) reset;
-(void) removeFromManagedObjectContext;
-(void) update:(CHChalkIdentifierFunction*)identifier;

@end
