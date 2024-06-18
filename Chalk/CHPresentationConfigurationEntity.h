//
//  CHPresentationConfigurationEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

@class CHPresentationConfiguration;

@interface CHPresentationConfigurationEntity : NSManagedObject

+(NSString*) entityName;

@property(nonatomic) NSUInteger softFloatDisplayBits;
@property(nonatomic) NSUInteger softPrettyPrintEndNegativeExponent;
@property(nonatomic) NSUInteger softPrettyPrintEndPositiveExponent;
@property(nonatomic) NSInteger base;
@property(nonatomic) BOOL baseUseLowercase;
@property(nonatomic) BOOL baseUseDecimalExponent;
@property(nonatomic) NSInteger integerGroupSize;
@property(nonatomic) NSInteger printOptions;

@property(nonatomic,copy) id plist;
@property(nonatomic,copy) CHPresentationConfiguration* presentationConfiguration;

@end
