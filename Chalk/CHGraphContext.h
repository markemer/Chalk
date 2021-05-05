//
//  CHGraphContext.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <mpfr.h>

@class CHChalkContext;
@class CHGraphAxis;
@class CHGmpPool;

@interface CHGraphContext : NSObject {
  CHGraphAxis* axisHorizontal1;
  CHGraphAxis* axisHorizontal2;
  CHGraphAxis* axisVertical1;
  CHGraphAxis* axisVertical2;
  CHChalkContext* chalkContext;
  CHGmpPool* gmpPool;
  mpfr_prec_t axisPrec;
}

@property(nonatomic,retain) CHGraphAxis* axisHorizontal1;
@property(nonatomic,retain) CHGraphAxis* axisHorizontal2;
@property(nonatomic,retain) CHGraphAxis* axisVertical1;
@property(nonatomic,retain) CHGraphAxis* axisVertical2;
@property(nonatomic,retain) CHChalkContext* chalkContext;
@property(nonatomic)        mpfr_prec_t axisPrec;

-(instancetype) initWithAxisPrec:(mpfr_prec_t)prec gmpPool:(CHGmpPool*)gmpPool;

@end
