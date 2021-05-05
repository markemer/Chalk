//
//  CHGraphScale.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHGraphUtils.h"

@class CHGmpPool;

@interface CHGraphScale : NSObject {
  chgraph_data_type_t dataType;
  chgraph_scale_t     scaleType;
  mpfi_t              linearComputeRange;
  mpfi_t              logarithmicComputeRange;
  mpfi_t              logarithmicVisualRange;
  int                 logarithmicBase;
  mpfr_t              logarithmicBase_fr;
  mpfi_t              logarithmicBase_fi;
  mpfir_t             logarithmicBase_fir;
  mpfir_t             logarithmicBaseLog;
  mpfr_t              computeDiameter;
  mpfr_t              visualDiameter;
  mpfr_prec_t         prec;
  CHGmpPool*          gmpPool;
}

@property(nonatomic)          mpfr_prec_t         prec;
@property(nonatomic)          chgraph_data_type_t dataType;
@property(nonatomic)          chgraph_scale_t     scaleType;
@property(nonatomic,readonly) mpfi_ptr            computeRange;
@property(nonatomic,readonly) mpfi_srcptr         visualRange;
@property(nonatomic,readonly) int                 currentBase;
@property(nonatomic)          int                 logarithmicBase;
@property(nonatomic,readonly) mpfr_srcptr         logarithmicBase_fr;
@property(nonatomic,readonly) mpfir_srcptr        logarithmicBaseLog;
@property(nonatomic,readonly) mpfr_srcptr         computeDiameter;
@property(nonatomic,readonly) mpfr_srcptr         visualDiameter;

-(instancetype) initWithPrec:(mpfr_prec_t)prec gmpPool:(CHGmpPool*)gmpPool;
-(void) convertMpfrComputeValue:(mpfr_srcptr)computeValue toVisualValue:(mpfr_ptr)visualValue;
-(void) convertMpfiComputeValue:(mpfi_srcptr)computeValue toVisualValue:(mpfi_ptr)visualValue;
-(void) convertMpfirComputeValue:(mpfir_srcptr)computeValue toVisualValue:(mpfir_ptr)visualValue;
-(void) convertMpfrVisualValue:(mpfr_srcptr)visualValue toComputeValue:(mpfr_ptr)computeValue;
-(void) convertMpfiVisualValue:(mpfi_srcptr)visualValue toComputeValue:(mpfi_ptr)computeValue;
-(void) convertMpfirVisualValue:(mpfir_srcptr)visualValue toComputeValue:(mpfir_ptr)computeValue;
-(void) updateData;

@end
