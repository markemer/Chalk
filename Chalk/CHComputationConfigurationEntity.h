//
//  CHComputationConfigurationEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "CHChalkUtils.h"

@class CHComputationConfiguration;

@interface CHComputationConfigurationEntity : NSManagedObject

+(NSString*) entityName;

@property(nonatomic) NSUInteger softIntegerMaxBits;
@property(nonatomic) NSUInteger softIntegerDenominatorMaxBits;
@property(nonatomic) NSUInteger softFloatSignificandBits;
@property(nonatomic) chalk_compute_mode_t computeMode;
@property(nonatomic) BOOL propagateNaN;
@property(nonatomic) int  baseDefault;

@property(nonatomic,copy) id plist;
@property(nonatomic,copy) CHComputationConfiguration* computationConfiguration;

@end
