//
//  CHGraphAxis.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <mpfr.h>

@class CHGraphScale;
@class CHGmpPool;

@interface CHGraphAxis : NSObject {
  CHGraphScale* scale;
  CHGmpPool*    gmpPool;
  BOOL          majorStepAuto;
  mpfr_t        majorStep;
  NSUInteger    minorDivisions;
  mpfr_prec_t   prec;
}

@property(nonatomic,retain)   CHGraphScale* scale;
@property(nonatomic)          BOOL          majorStepAuto;
@property(nonatomic,readonly) mpfr_ptr      majorStep;
@property(nonatomic)          NSUInteger    minorDivisions;
@property(nonatomic)          mpfr_prec_t   prec;

-(instancetype) initWithPrec:(mpfr_prec_t)prec gmpPool:(CHGmpPool*)gmpPool;

@end
