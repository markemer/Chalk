//
//  CHGraphCurveItem.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifier.h"

@class CHGraphCurve;

extern NSString* CHGraphCurveItemNameKey;
extern NSString* CHGraphCurveItemCurveKey;
extern NSString* CHGraphCurveItemIsDynamicKey;
extern NSString* CHGraphCurveItemCurveThicknessKey;
extern NSString* CHGraphCurveItemCurveColorKey;
extern NSString* CHGraphCurveItemCurveInteriorColorKey;
extern NSString* CHGraphCurveItemCurveUncertaintyVisibleKey;
extern NSString* CHGraphCurveItemCurveUncertaintyColorKey;
extern NSString* CHGraphCurveItemCurveUncertaintyNaNVisibleKey;
extern NSString* CHGraphCurveItemCurveUncertaintyNaNColorKey;
extern NSString* CHGraphCurveItemPredicateColorFalseKey;
extern NSString* CHGraphCurveItemPredicateColorTrueKey;

extern NSString* CHGraphCurveItemDidInvalidateNotification;

@protocol CHGraphCurveItemDelegate
@optional
-(void) graphCurveItemDidInvalidate:(NSNotification*)notification;
@end

@interface CHGraphCurveItem : NSObject <NSCopying, CHChalkIdentifierDependent>

@property(copy)           NSString*     name;
@property(retain)         CHGraphCurve* curve;
@property(nonatomic)      NSUInteger    curveThickness;
@property(nonatomic,copy) NSColor*      curveColor;
@property(nonatomic,copy) NSColor*      curveInteriorColor;
@property(nonatomic)      BOOL          curveUncertaintyVisible;
@property(nonatomic,copy) NSColor*      curveUncertaintyColor;
@property(nonatomic)      BOOL          curveUncertaintyNaNVisible;
@property(nonatomic,copy) NSColor*      curveUncertaintyNaNColor;
@property(nonatomic,copy) NSColor*      predicateColorFalse;
@property(nonatomic,copy) NSColor*      predicateColorTrue;

@property(assign)         id   delegate;
@property(nonatomic)      BOOL enabled;
@property                 BOOL isUpdating;
@property(readonly)       BOOL isPredicate;

+(NSColor*) defaultCurveColor;
+(NSColor*) defaultCurveInteriorColor;
+(NSColor*) defaultCurveUncertaintyColor;
+(NSColor*) defaultCurveUncertaintyNaNColor;
+(NSColor*) defaultPredicateFalseColor;
+(NSColor*) defaultPredicateTrueColor;

-(instancetype) init;
-(instancetype) initWithCurve:(CHGraphCurve*)aCurve;

#pragma mark CHChalkIdentifierDependent
@property                     BOOL               hasCircularDependency;
@property(readonly,retain)    CHChalkIdentifier* identifier;
@property(nonatomic,readonly) BOOL               isDynamic;
@property(readonly,retain)    NSSet*             dependingIdentifiers;

-(void) refreshIdentifierDependencies;

@end
