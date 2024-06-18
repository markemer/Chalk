//
//  CHGmpPool.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/06/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphUtils.h"

#import "CHUtils.h"

#include <vector>

extern "C" void depoolGraphElement(chalk_graph_data_element_t** pElement, CHGraphDataPool* graphDataPool)
{
  if (pElement)
    *pElement = [graphDataPool depoolGraphDataElement];
}
//end depoolGraphElement()

extern "C" void repoolGraphElement(chalk_graph_data_element_t** pElement, CHGraphDataPool* graphDataPool)
{
  if (pElement && *pElement)
  {
    chalk_graph_data_element_t* element = *pElement;
    repoolGraphElement(&element->left, graphDataPool);
    repoolGraphElement(&element->right, graphDataPool);
    chalkGmpValueClear(&element->x, YES, graphDataPool.gmpPool);
    chalkGmpValueClear(&element->y, YES, graphDataPool.gmpPool);
    chalkGmpValueClear(&element->yEstimation, YES, graphDataPool.gmpPool);
    if (!graphDataPool)
      free(element);
    else//if (graphDataPool)
      [graphDataPool repoolGraphDataElement:element];
    *pElement = 0;
  }//end if (pElement && *pElement)
}
//end repoolGraphElement()

extern "C" void repoolGraphElement2d(chalk_graph_data_element2d_t** pElement, CHGraphDataPool* graphDataPool)
{
  if (pElement && *pElement)
  {
    chalk_graph_data_element2d_t* element = *pElement;
    repoolGraphElement2d(&element->tl, graphDataPool);
    repoolGraphElement2d(&element->tr, graphDataPool);
    repoolGraphElement2d(&element->bl, graphDataPool);
    repoolGraphElement2d(&element->br, graphDataPool);
    chalkGmpValueClear(&element->x, YES, graphDataPool.gmpPool);
    chalkGmpValueClear(&element->y, YES, graphDataPool.gmpPool);
    if (!graphDataPool)
      free(element);
    else//if (graphDataPool)
      [graphDataPool repoolGraphDataElement2d:element];
    *pElement = 0;
  }//end if (element)
}
//end repoolGraphElement2d()

extern "C" void depoolGraphElement2d(chalk_graph_data_element2d_t** pElement, CHGraphDataPool* graphDataPool)
{
  if (pElement)
    *pElement = [graphDataPool depoolGraphDataElement2d];
}
//end depoolGraphElement2d()

extern "C" void printElement(const char* prefix, const chalk_graph_data_element_t* element)
{
  if (!element)
    DebugLogStatic(0, @"<null>\n");
  else//if (element)
    DebugLogStatic(0, @"%s X[%@,%@](%@)%@, Y[%@,%@](%@)%@\n",
      !prefix ? "" : prefix,
      (element->x.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_left_get_d(element->x.realApprox, MPFR_RNDN)) :
      (element->x.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->x.realExact, MPFR_RNDN)) :
        @"#",
      (element->x.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_right_get_d(element->x.realApprox, MPFR_RNDN)) :
      (element->x.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->x.realExact, MPFR_RNDN)) :
        @"#",
      (element->x.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_estimation_get_d(element->x.realApprox, MPFR_RNDN)) :
      (element->x.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->x.realExact, MPFR_RNDN)) :
        @"#",
      NSStringFromRange(element->x_px),
      (element->y.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_left_get_d(element->y.realApprox, MPFR_RNDN)) :
      (element->y.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->y.realExact, MPFR_RNDN)) :
        @"#",
      (element->y.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_right_get_d(element->y.realApprox, MPFR_RNDN)) :
      (element->y.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->y.realExact, MPFR_RNDN)) :
        @"#",
      (element->y.type == CHALK_VALUE_TYPE_REAL_APPROX) ?
        @(mpfir_estimation_get_d(element->y.realApprox, MPFR_RNDN)) :
      (element->y.type == CHALK_VALUE_TYPE_REAL_EXACT) ?
        @(mpfr_get_d(element->y.realExact, MPFR_RNDN)) :
        @"#",
      NSStringFromRange(element->y_px));
}
//end printElement()

@implementation CHGraphDataPool

@synthesize gmpPool;

-(instancetype) initWithCapacity:(NSUInteger)aCapacity gmpPool:(CHGmpPool*)aGmpPool
{
  if (!((self = [super init])))
    return nil;
  self->capacity = aCapacity;
  std::vector<chalk_graph_data_element_t*>* _graphDataElementVector = new(std::nothrow) std::vector<chalk_graph_data_element_t*>;
  if (_graphDataElementVector)
    _graphDataElementVector->reserve(MIN(1024U, self->capacity));
  self->graphDataElementVector = _graphDataElementVector;
  self->graphDataElementSpinlock = OS_SPINLOCK_INIT;
  std::vector<chalk_graph_data_element2d_t*>* _graphDataElement2dVector = new(std::nothrow) std::vector<chalk_graph_data_element2d_t*>;
  if (_graphDataElement2dVector)
    _graphDataElement2dVector->reserve(MIN(1024U, self->capacity));
  self->graphDataElement2dVector = _graphDataElement2dVector;
  self->graphDataElement2dSpinlock = OS_SPINLOCK_INIT;
  self->gmpPool = [aGmpPool retain];
  return self;
}
//end init

-(void) dealloc
{
  std::vector<chalk_graph_data_element_t*>* _graphDataElementVector = reinterpret_cast<std::vector<chalk_graph_data_element_t*>*>(self->graphDataElementVector);
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_apply_gmp(!_graphDataElementVector ? 0 : _graphDataElementVector->size(), queue, ^(size_t i) {
    free((*_graphDataElementVector)[i]);
  });
  delete _graphDataElementVector;
  std::vector<chalk_graph_data_element2d_t*>* _graphDataElement2dVector = reinterpret_cast<std::vector<chalk_graph_data_element2d_t*>*>(self->graphDataElement2dVector);
  dispatch_queue_t queue2d = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_apply_gmp(!_graphDataElement2dVector ? 0 : _graphDataElement2dVector->size(), queue2d, ^(size_t i) {
    free((*_graphDataElement2dVector)[i]);
  });
  delete _graphDataElement2dVector;
  [self->gmpPool release];
  [super dealloc];
}
//end dealloc

-(chalk_graph_data_element_t*) depoolGraphDataElement
{
  chalk_graph_data_element_t* result;
  BOOL takenInPool = NO;
  std::vector<chalk_graph_data_element_t*>* pool = reinterpret_cast<std::vector<chalk_graph_data_element_t*>*>(self->graphDataElementVector);
  if (pool)
  {
    OSSpinLockLock(&self->graphDataElementSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      pool->pop_back();
      memset(result, 0, sizeof(chalk_graph_data_element_t));
      takenInPool = YES;
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->graphDataElementSpinlock);
  }//end if (pool)
  if (!takenInPool)
    result = (chalk_graph_data_element_t*)calloc(1, sizeof(chalk_graph_data_element_t));
  OSAtomicAdd64(-1, &self->graphDataElementCounter);
  return result;
}
//end depoolGraphDataElement

-(void) repoolGraphDataElement:(chalk_graph_data_element_t*)value
{
  if (value)
  {
    [self repoolGraphDataElement:value->left];
    value->left = 0;
    [self repoolGraphDataElement:value->right];
    value->right = 0;
    BOOL repooled = NO;
    std::vector<chalk_graph_data_element_t*>* pool = reinterpret_cast<std::vector<chalk_graph_data_element_t*>*>(self->graphDataElementVector);
    if (pool)
    {
      OSSpinLockLock(&self->graphDataElementSpinlock);
      if (pool->size() < self->capacity)
      {
        pool->push_back(value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->graphDataElementSpinlock);
    }//end if (pool)
    if (!repooled)
      free(value);
    OSAtomicAdd64(1, &self->graphDataElementCounter);
  }//end if (value)
}
//end repoolGraphDataElement:

-(chalk_graph_data_element2d_t*) depoolGraphDataElement2d
{
  chalk_graph_data_element2d_t* result;
  BOOL takenInPool = NO;
  std::vector<chalk_graph_data_element2d_t*>* pool = reinterpret_cast<std::vector<chalk_graph_data_element2d_t*>*>(self->graphDataElementVector);
  if (pool)
  {
    OSSpinLockLock(&self->graphDataElement2dSpinlock);
    if (!pool->empty())
    {
      result = pool->back();
      pool->pop_back();
      memset(result, 0, sizeof(chalk_graph_data_element2d_t));
      takenInPool = YES;
    }//end if (!pool->empty())
    OSSpinLockUnlock(&self->graphDataElement2dSpinlock);
  }//end if (pool)
  if (!takenInPool)
    result = (chalk_graph_data_element2d_t*)calloc(1, sizeof(chalk_graph_data_element2d_t));
  OSAtomicAdd64(-1, &self->graphDataElement2dCounter);
  return result;
}
//end depoolGraphDataElement2d

-(void) repoolGraphDataElement2d:(chalk_graph_data_element2d_t*)value
{
  if (value)
  {
    [self repoolGraphDataElement2d:value->tl];
    value->tl = 0;
    [self repoolGraphDataElement2d:value->tr];
    value->tr = 0;
    [self repoolGraphDataElement2d:value->bl];
    value->bl = 0;
    [self repoolGraphDataElement2d:value->br];
    value->br = 0;
    BOOL repooled = NO;
    std::vector<chalk_graph_data_element2d_t*>* pool = reinterpret_cast<std::vector<chalk_graph_data_element2d_t*>*>(self->graphDataElement2dVector);
    if (pool)
    {
      OSSpinLockLock(&self->graphDataElement2dSpinlock);
      if (pool->size() < self->capacity)
      {
        pool->push_back(value);
        repooled = YES;
      }//end if (pool->size() < self->capacity)
      OSSpinLockUnlock(&self->graphDataElement2dSpinlock);
    }//end if (pool)
    if (!repooled)
      free(value);
    OSAtomicAdd64(1, &self->graphDataElement2dCounter);
  }//end if (value)
}
//end repoolGraphDataElement2d:

@end
