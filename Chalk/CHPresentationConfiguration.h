//
//  CHPresentationConfiguration.h
//  Chalk
//
//  Created by Pierre Chatelier on 20/03/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@interface CHPresentationConfiguration : NSObject <NSCoding, NSCopying, NSSecureCoding>

@property(nonatomic) NSUInteger softFloatDisplayBits;
@property(nonatomic) NSUInteger softMaxPrettyPrintNegativeExponent;
@property(nonatomic) NSUInteger softMaxPrettyPrintPositiveExponent;
@property(nonatomic) int base;
@property(nonatomic) BOOL baseUseLowercase;
@property(nonatomic) BOOL baseUseDecimalExponent;
@property(nonatomic) NSInteger integerGroupSize;
@property(nonatomic) chalk_value_description_t description;
@property(nonatomic) chalk_value_print_options_t printOptions;

@property(nonatomic,copy) id plist;

+(instancetype) presentationConfigurationWithDescription:(chalk_value_description_t)description;
+(instancetype) presentationConfigurationWithPlist:(id)plist;
+(instancetype) presentationConfiguration;
-(instancetype) initWithDescription:(chalk_value_description_t)description;
-(instancetype) initWithPlist:(id)plist;
-(instancetype) init;

-(void) reset;

@end
