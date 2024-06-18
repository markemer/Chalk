//
//  CHComputationEntryEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CHValueHolderEntity.h"

@class CHChalkValue;
@class CHComputationConfigurationEntity;
@class CHComputedValueEntity;
@class CHPresentationConfigurationEntity;

@interface CHComputationEntryEntity : CHValueHolderEntity {
  BOOL isCreatingComputationConfiguration;
  BOOL isCreatingPresentationConfiguration;
}

+(NSString*) entityName;

@property(nonatomic)      NSInteger uniqueIdentifier;
@property(nonatomic,copy) NSString* inputRawString;
@property(nonatomic,copy) NSString* inputRawHTMLString;
@property(nonatomic,copy) NSString* inputInterpretedHTMLString;
@property(nonatomic,copy) NSString* inputInterpretedTeXString;
@property(nonatomic,copy) NSString* outputRawString;
@property(nonatomic,copy) NSString* outputHTMLString;
@property(nonatomic,copy) NSString* outputTeXString;
@property(nonatomic,copy) NSString* outputHtmlCumulativeFlags;
@property(nonatomic,copy) NSString* output2RawString;
@property(nonatomic,copy) NSString* output2HTMLString;
@property(nonatomic,copy) NSString* output2TeXString;
@property(nonatomic,copy) NSString* output2HtmlCumulativeFlags;
@property(nonatomic,copy) NSDate*   dateCreation;
@property(nonatomic,copy) NSDate*   dateModification;
@property(nonatomic,copy) NSString* customAnnotation;
@property(nonatomic)      BOOL      customAnnotationVisible;

@property(nonatomic,retain) CHComputationConfigurationEntity* computationConfiguration;
@property(nonatomic,retain) CHPresentationConfigurationEntity* presentationConfiguration;
@property(nonatomic,readonly,retain) NSMutableOrderedSet* computedValues;
@property(nonatomic,readonly,retain) CHComputedValueEntity* computedValue1;
@property(nonatomic,readonly,retain) CHComputedValueEntity* computedValue2;

@property(nonatomic,retain) CHChalkValue* chalkValue1;
@property(nonatomic,retain) CHChalkValue* chalkValue2;

@property(nonatomic,readonly) NSUInteger softFloatSignificandBits;

@end
