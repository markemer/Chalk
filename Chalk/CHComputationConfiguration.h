//
//  CHComputationConfiguration.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "CHChalkUtils.h"

@interface CHComputationConfiguration : NSObject <NSCoding, NSCopying, NSSecureCoding>

@property(nonatomic) NSUInteger softIntegerMaxBits;
@property(nonatomic) NSUInteger softIntegerDenominatorMaxBits;
@property(nonatomic) NSUInteger softFloatSignificandBits;
@property(nonatomic) NSUInteger softMaxExponent;
@property(nonatomic) chalk_compute_mode_t computeMode;
@property(nonatomic) BOOL propagateNaN;
@property(nonatomic) int  baseDefault;

@property(nonatomic,copy) id plist;

+(instancetype) computationConfigurationWithPlist:(id)plist;
+(instancetype) computationConfiguration;

-(instancetype) initWithPlist:(id)plist;
-(instancetype) init;

-(void) reset;

@end
