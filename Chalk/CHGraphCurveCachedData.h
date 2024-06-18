//
//  CHGraphCurveCachedData.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHGraphUtils.h"

#include <gmp.h>

@class CHChalkContext;
@class CHGmpPool;
@class CHGraphContext;
@class CHGraphCurve;
@class CHGraphView;

typedef void (^callback_end_t)(BOOL);

@interface CHGraphCurveCachedData : NSObject {
  CHGraphCurve*   curve;
  CHGraphContext* graphContext;
  CHGmpPool*      graphGmpPool;
  CHGraphDataPool* graphDataPool;
  CHChalkContext*  chalkContext;
  chalk_graph_data_element_t** cachedData;
  chalk_graph_data_element2d_t* rootElement2d;
  size_t cachedDataSize;
  mpz_t cachedDataSizeZ;
  dispatch_semaphore_t fillingSemaphore;
  volatile BOOL shouldStopFilling;
}

-(instancetype) initWithCurve:(CHGraphCurve*)curve graphContext:(CHGraphContext*)aGraphContext graphGmpPool:(CHGmpPool*)aGraphGmpPool graphDataPool:(CHGraphDataPool*)aGraphDataPool;

@property(nonatomic,readonly,retain) CHGraphCurve* curve;
@property(nonatomic,readonly) BOOL isDirty;
@property(nonatomic,readonly) BOOL isPreparing;
@property(nonatomic)          BOOL isPreparingDirty;
@property(nonatomic,readonly) NSRect contextBounds;
@property(nonatomic,readonly) chalk_graph_data_element_t** cachedData;
@property(nonatomic)          size_t cachedDataSize;
@property(nonatomic,readonly) mpz_srcptr cachedDataSizeZ;
@property(nonatomic,readonly) chalk_graph_data_element2d_t*  rootElement2d;

-(void) invalidate;
-(void) startFilling:(CHGraphView*)graphView rect:(CGRect)rect callBackEnd:(callback_end_t)callBackEnd;
-(void) cancelFilling;
-(void) waitFillingEnd;

@end
