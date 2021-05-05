//
//  CHUserFunctionEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CHComputedValueEntity;

@interface CHUserFunctionEntity : NSManagedObject

+(NSString*) entityName;

@property(nonatomic,retain) NSString* identifierName;
@property(nonatomic,retain) NSString* inputRawString;
@property(nonatomic,retain) NSString* argumentNames;

@end
