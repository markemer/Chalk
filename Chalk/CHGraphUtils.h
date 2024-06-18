//
//  CHGraphUtils.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#ifndef Chalk_CHGraphUtils_h
#define Chalk_CHGraphUtils_h

#import "CHChalkUtils.h"

typedef NS_ENUM(NSUInteger, chgraph_data_type_t) {
  CHGRAPH_DATA_TYPE_UNDEFINED,
  CHGRAPH_DATA_TYPE_VALUE,
  CHGRAPH_DATA_TYPE_TIME
};

typedef NS_ENUM(NSUInteger, chgraph_scale_t) {
  CHGRAPH_SCALE_UNDEFINED,
  CHGRAPH_SCALE_LINEAR=1,
  CHGRAPH_SCALE_LOGARITHMIC=2
};

typedef NS_ENUM(NSUInteger, chgraph_mode_t) {
  CHGRAPH_MODE_UNDEFINED,
  CHGRAPH_MODE_Y_FROM_X,
  CHGRAPH_MODE_XY_PREDICATE
};

typedef NS_OPTIONS(NSUInteger, chgraph_axis_orientation_flags_t) {
  CHGRAPH_AXIS_ORIENTATION_NONE=0,
  CHGRAPH_AXIS_ORIENTATION_HORIZONTAL=1<<0,
  CHGRAPH_AXIS_ORIENTATION_VERTICAL=1<<2
};

typedef NS_ENUM(NSUInteger, chgraph_grid_step_t) {
  CHGRAPH_GRID_STEP_UNDEFINED,
  CHGRAPH_GRID_STEP_MAJOR,
  CHGRAPH_GRID_STEP_MINOR
};

typedef NS_ENUM(NSUInteger, chgraph_action_t) {
  CHGRAPH_ACTION_UNDEFINED,
  CHGRAPH_ACTION_CURSOR,
  CHGRAPH_ACTION_DRAG,
  CHGRAPH_ACTION_ZOOM_IN,
  CHGRAPH_ACTION_ZOOM_OUT,
};

typedef NS_OPTIONS(NSUInteger, chgraph_pixel_flag_t) {
  CHGRAPH_PIXEL_FLAG_NONE=0,
  CHGRAPH_PIXEL_FLAG_NAN=1<<0,
  CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE=1<<1,
  CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE=1<<2,
  CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE=1<<3,
  CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE=1<<4,
};

typedef struct chalk_graph_pixel_t {
  NSUInteger px;
  chgraph_pixel_flag_t flags;
} chalk_graph_pixel_t;

typedef struct chalk_graph_data_element_t {
  NSRange x_px;
  NSUInteger subPixelLevel;
  chalk_gmp_value_t x;
  chalk_gmp_value_t y;
  chalk_gmp_value_t yEstimation;
  NSRange y_px;
  chalk_graph_pixel_t yEstimation_px;
  struct chalk_graph_data_element_t* left;
  struct chalk_graph_data_element_t* right;
} chalk_graph_data_element_t;

typedef struct chalk_graph_data_element2d_t {
  NSRange x_px;
  chalk_gmp_value_t x;
  NSRange y_px;
  chalk_gmp_value_t y;
  chalk_bool_t value;
  BOOL isValueRelevant;
  BOOL isXSplitIrrelevant;
  BOOL isYSplitIrrelevant;
  struct chalk_graph_data_element2d_t* tl;
  struct chalk_graph_data_element2d_t* tr;
  struct chalk_graph_data_element2d_t* bl;
  struct chalk_graph_data_element2d_t* br;
} chalk_graph_data_element2d_t;

#ifdef __cplusplus
extern "C" {
#endif
void printElement(const char* prefix, const chalk_graph_data_element_t* element);
#ifdef __cplusplus
}
#endif

@interface CHGraphDataPool : NSObject {
  NSUInteger capacity;
  void* graphDataElementVector;
  OSSpinLock graphDataElementSpinlock;
  int64_t graphDataElementCounter;
  void* graphDataElement2dVector;
  OSSpinLock graphDataElement2dSpinlock;
  int64_t graphDataElement2dCounter;
  CHGmpPool* gmpPool;
}

@property(readonly,assign) CHGmpPool* gmpPool;

-(instancetype) initWithCapacity:(NSUInteger)aCapacity gmpPool:(CHGmpPool*)aGmpPool;

-(chalk_graph_data_element_t*) depoolGraphDataElement;
-(void) repoolGraphDataElement:(chalk_graph_data_element_t*)value;
-(chalk_graph_data_element2d_t*) depoolGraphDataElement2d;
-(void) repoolGraphDataElement2d:(chalk_graph_data_element2d_t*)value;

@end

#ifdef __cplusplus
extern "C" {
#endif
void depoolGraphElement(chalk_graph_data_element_t** pElement, CHGraphDataPool* graphDataPool);
void repoolGraphElement(chalk_graph_data_element_t** pElement, CHGraphDataPool* graphDataPool);
void depoolGraphElement2d(chalk_graph_data_element2d_t** pElement, CHGraphDataPool* graphDataPool);
void repoolGraphElement2d(chalk_graph_data_element2d_t** pElement, CHGraphDataPool* graphDataPool);
#ifdef __cplusplus
}
#endif

#endif
