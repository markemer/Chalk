//
//  CHUserVariableEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CHValueHolderEntity.h"

@class CHChalkValue;
@class CHComputedValueEntity;

@interface CHUserVariableEntity : CHValueHolderEntity

+(NSString*) entityName;

@property(nonatomic,retain) NSString* identifierClassName;
@property(nonatomic,retain) NSString* identifierName;
@property(nonatomic,retain) NSString* inputRawString;
@property(nonatomic)        BOOL      isDynamic;

@property(nonatomic,readonly,retain) NSMutableOrderedSet* computedValues;
@property(nonatomic,readonly,retain) CHComputedValueEntity* computedValue1;
@property(nonatomic,readonly,retain) CHComputedValueEntity* computedValue2;

@property(nonatomic,retain) CHChalkValue* chalkValue1;
@property(nonatomic,retain) CHChalkValue* chalkValue2;

@end
