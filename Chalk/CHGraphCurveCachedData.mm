//
//  CHGraphCurveCachedData.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHGraphCurveCachedData.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierManagerWrapper.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHGraphAxis.h"
#import "CHGraphContext.h"
#import "CHGraphCurve.h"
#import "CHGraphScale.h"
#import "CHGraphView.h"
#import "CHParserNode.h"
#import "CHPool.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

#include <deque>
#include <vector>

struct bisect_exploration_t
{
  bisect_exploration_t(chalk_graph_data_element_t* parent = 0,
                       chalk_graph_data_element_t* primaryChild = 0, chalk_graph_data_element_t* secondaryChild = 0,
                       int explorationState = 0)
                      :parent(parent),primaryChild(primaryChild),secondaryChild(secondaryChild),
                       explorationState(explorationState) {}
  chalk_graph_data_element_t* parent;
  chalk_graph_data_element_t* primaryChild;
  chalk_graph_data_element_t* secondaryChild;
  int explorationState;
};
//end bisect_exploration_t

typedef __block void (^explore2d_eval_block_t)(chalk_graph_data_element2d_t*, NSUInteger elementPixelSize, CHParserNode*, CHChalkContext*, volatile BOOL* stop);

static int explore2d(chalk_graph_data_element2d_t* element, NSUInteger elementPixelSize, CHGraphDataPool* graphDataPool,
                     CHPool* parserNodePool, CHPool* chalkContextPool, BOOL concurrent, explore2d_eval_block_t evalBlock,
                     volatile BOOL* stop)
{
  int result = 0;
  BOOL shouldSplit  = element && !chalkBoolIsCertain(element->value);
  BOOL shouldSplitX = shouldSplit && !element->isXSplitIrrelevant && (element->x_px.length>MAX(1, elementPixelSize));
  BOOL shouldSplitY = shouldSplit && !element->isYSplitIrrelevant && (element->y_px.length>MAX(1, elementPixelSize));
  if (stop && *stop){
  }
  else if (shouldSplitX || shouldSplitY)
  {
    element->isValueRelevant = NO;
    NSUInteger x_px_separation = MAX(1, element->x_px.location+element->x_px.length/2);
    NSUInteger y_px_separation = MAX(1, element->y_px.location+element->y_px.length/2);
    NSRange x_px_l = !shouldSplitX ? element->x_px :
      NSMakeRange(element->x_px.location, x_px_separation-element->x_px.location);
    NSRange x_px_r = !shouldSplitX ? element->x_px :
      NSMakeRange(x_px_separation,element->x_px.location+element->x_px.length-x_px_separation);
    NSRange y_px_b = !shouldSplitY ? element->y_px :
      NSMakeRange(element->y_px.location, y_px_separation-element->y_px.location);
    NSRange y_px_t = !shouldSplitY ? element->y_px :
      NSMakeRange(y_px_separation,element->y_px.location+element->y_px.length-y_px_separation);
    chalk_graph_data_element2d_t* subElements[4] = {0};
    size_t subElementsCount = 0;
    element->tl = [graphDataPool depoolGraphDataElement2d];
    if (element->tl)
    {
      element->tl->x_px = x_px_l;
      element->tl->y_px = y_px_t;
      subElements[subElementsCount++] = element->tl;
    }//end if (element->tl)
    element->tr = !shouldSplitX ? 0 : [graphDataPool depoolGraphDataElement2d];
    if (element->tr)
    {
      element->tr->x_px = x_px_r;
      element->tr->y_px = y_px_t;
      subElements[subElementsCount++] = element->tr;
    }//end if (element->tr)
    element->bl = !shouldSplitY ? 0 : [graphDataPool depoolGraphDataElement2d];
    if (element->bl)
    {
      element->bl->x_px = x_px_l;
      element->bl->y_px = y_px_b;
      subElements[subElementsCount++] = element->bl;
    }//end if (element->bl)
    element->br = !shouldSplitX || !shouldSplitY ? 0 : [graphDataPool depoolGraphDataElement2d];
    if (element->br)
    {
      element->br->x_px = x_px_r;
      element->br->y_px = y_px_b;
      subElements[subElementsCount++] = element->br;
    }//end if (element->br)

    __block uint32_t error = 0;
    chalk_graph_data_element2d_t** subElementsStart = subElements;
    void (^subElement_block_t)(size_t) = ^(size_t index) {
      chalk_graph_data_element2d_t* currentElement = *(subElementsStart+index);
      if (stop && *stop){
      }
      else if (!error && currentElement && currentElement->x_px.length && currentElement->y_px.length)
      {
        currentElement->isXSplitIrrelevant = element->isXSplitIrrelevant;
        currentElement->isYSplitIrrelevant = element->isYSplitIrrelevant;
        CHParserNode* localParserNode = [parserNodePool depool];
        CHChalkContext* localContext = [chalkContextPool depool];
        [localContext.errorContext reset:nil];
        if (!localParserNode || !localContext)
          OSAtomicOr32(YES, &error);
        else//if (localParserNode || !localContext)
          evalBlock(currentElement, elementPixelSize, localParserNode, localContext, stop);
        [parserNodePool repool:localParserNode];
        [chalkContextPool repool:localContext];
        int subStatus = explore2d(currentElement, elementPixelSize, graphDataPool, parserNodePool, chalkContextPool, concurrent, evalBlock, stop);
        OSAtomicOr32(subStatus, &error);
      }//end if (currentElement && currentElement->x_px.length && currentElement->y_px.length)
    };
    if (stop && *stop){
    }
    else if (subElementsCount == 1)
      subElement_block_t(0);
    else if (subElementsCount > 1)
    {
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
      dispatch_options_t options = concurrent ? DISPATCH_OPTION_NONE : DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL;
      dispatch_applyWithOptions_gmp(4, queue, options, subElement_block_t);
    }//end if (subElementsCount > 1)
    if (stop && *stop){
    }
    else if (element->tl && element->tr && element->bl && element->br &&
        element->tl->isValueRelevant && element->tr->isValueRelevant &&
        element->bl->isValueRelevant && element->br->isValueRelevant &&
        (element->tl->value == element->tr->value) && (element->tr->value == element->bl->value) &&
        (element->bl->value == element->br->value))
    {
      element->value = element->tl->value;
      element->isValueRelevant = YES;
      repoolGraphElement2d(&element->tl, graphDataPool);
      repoolGraphElement2d(&element->tr, graphDataPool);
      repoolGraphElement2d(&element->bl, graphDataPool);
      repoolGraphElement2d(&element->br, graphDataPool);
    }//end if all subElement equals
    if (stop && *stop){
    }
    else if (element->tl && element->tr &&
             element->tl->isValueRelevant && element->tr->isValueRelevant &&
             (element->tl->value == element->tr->value) &&
             NSEqualRanges(element->tl->y_px, element->tr->y_px))
    {
      element->value = element->tl->value;
      element->tl->x_px = NSRangeUnion(element->tl->x_px, element->tr->x_px);
      CHChalkContext* localContext = [chalkContextPool depool];
      [localContext.errorContext reset:nil];
      mpfr_prec_t prec = localContext.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&element->tl->x, prec, graphDataPool.gmpPool);
      chalkGmpValueMakeRealApprox(&element->tr->x, prec, graphDataPool.gmpPool);
      [chalkContextPool repool:localContext];
      mpfir_union(element->tl->x.realApprox, element->tl->x.realApprox, element->tr->x.realApprox);
      repoolGraphElement2d(&element->tr, graphDataPool);
    }//end if top subElement equals
    if (stop && *stop){
    }
    else if (element->bl && element->br &&
             element->bl->isValueRelevant && element->br->isValueRelevant &&
             (element->bl->value == element->br->value) &&
             NSEqualRanges(element->bl->y_px, element->br->y_px))
    {
      element->value = element->bl->value;
      element->bl->x_px = NSRangeUnion(element->bl->x_px, element->br->x_px);
      CHChalkContext* localContext = [chalkContextPool depool];
      [localContext.errorContext reset:nil];
      mpfr_prec_t prec = localContext.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&element->bl->x, prec, graphDataPool.gmpPool);
      chalkGmpValueMakeRealApprox(&element->br->x, prec, graphDataPool.gmpPool);
      [chalkContextPool repool:localContext];
      mpfir_union(element->bl->x.realApprox, element->bl->x.realApprox, element->br->x.realApprox);
      repoolGraphElement2d(&element->br, graphDataPool);
    }//end if bottom subElement equals
    if (stop && *stop){
    }
    else if (element->tl && element->bl &&
             element->tl->isValueRelevant && element->bl->isValueRelevant &&
             (element->tl->value == element->bl->value) &&
             NSEqualRanges(element->tl->x_px, element->bl->x_px))
    {
      element->value = element->tl->value;
      element->tl->y_px = NSRangeUnion(element->tl->y_px, element->bl->y_px);
      CHChalkContext* localContext = [chalkContextPool depool];
      [localContext.errorContext reset:nil];
      mpfr_prec_t prec = localContext.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&element->tl->y, prec, graphDataPool.gmpPool);
      chalkGmpValueMakeRealApprox(&element->bl->y, prec, graphDataPool.gmpPool);
      [chalkContextPool repool:localContext];
      mpfir_union(element->tl->y.realApprox, element->tl->y.realApprox, element->bl->y.realApprox);
      repoolGraphElement2d(&element->bl, graphDataPool);
    }//end if left subElement equals
    if (stop && *stop){
    }
    else if (element->tr && element->br &&
             element->tr->isValueRelevant && element->br->isValueRelevant &&
             (element->tr->value == element->br->value) &&
             NSEqualRanges(element->tr->x_px, element->br->x_px))
    {
      element->value = element->tr->value;
      element->tr->y_px = NSRangeUnion(element->tr->y_px, element->br->y_px);
      CHChalkContext* localContext = [chalkContextPool depool];
      [localContext.errorContext reset:nil];
      mpfr_prec_t prec = localContext.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealApprox(&element->tr->y, prec, graphDataPool.gmpPool);
      chalkGmpValueMakeRealApprox(&element->br->y, prec, graphDataPool.gmpPool);
      [chalkContextPool repool:localContext];
      mpfir_union(element->tr->y.realApprox, element->tr->y.realApprox, element->br->y.realApprox);
      repoolGraphElement2d(&element->br, graphDataPool);
    }//end if right subElement equals
    result = error ? -1 : 0;
  }//end if (shouldSplitX || shouldSplitY)
  return result;
}
//end explore2d()

static void adjust2dValues(chalk_graph_data_element2d_t* element, volatile BOOL* stop)
{
  std::deque<chalk_graph_data_element2d_t*> elements;
  elements.push_back(element);
  BOOL stopQueue = elements.empty() || (stop && *stop);
  while(!stopQueue)
  {
    chalk_graph_data_element2d_t* currentElement = elements.back();
    if (!currentElement)
      elements.pop_back();
    else if (currentElement->isValueRelevant)
      elements.pop_back();
    else//if (currentElement && !currentElement->isValueRelevant)
    {
      BOOL hasIrrelevantSubValue = NO;
      if (currentElement->tl && !currentElement->tl->isValueRelevant)
      {
        hasIrrelevantSubValue = YES;
        elements.push_back(currentElement->tl);
      }//end if (currentElement->tl && !currentElement->tl->isValueRelevant)
      if (currentElement->tr && !currentElement->tr->isValueRelevant)
      {
        hasIrrelevantSubValue = YES;
        elements.push_back(currentElement->tr);
      }//end if (currentElement->tr && !currentElement->tr->isValueRelevant)
      if (currentElement->bl && !currentElement->bl->isValueRelevant)
      {
        hasIrrelevantSubValue = YES;
        elements.push_back(currentElement->bl);
      }//end if (currentElement->bl && !currentElement->bl->isValueRelevant)
      if (currentElement->br && !currentElement->br->isValueRelevant)
      {
        hasIrrelevantSubValue = YES;
        elements.push_back(currentElement->br);
      }//end if (currentElement->br && !currentElement->br->isValueRelevant)
      if (!hasIrrelevantSubValue)
      {
        if (currentElement->tl && currentElement->tl->isValueRelevant)
        {
          currentElement->value = !currentElement->isValueRelevant ? currentElement->tl->value :
            chalkBoolCombine(currentElement->tl->value, currentElement->value);
          currentElement->isValueRelevant = YES;
        }//end if (currentElement->tl && currentElement->tl->isValueRelevant)
        if (currentElement->tr && currentElement->tr->isValueRelevant)
        {
          currentElement->value = !currentElement->isValueRelevant ? currentElement->tr->value :
            chalkBoolCombine(currentElement->tr->value, currentElement->value);
          currentElement->isValueRelevant = YES;
        }//end if (currentElement->tr && currentElement->tr->isValueRelevant)
        if (currentElement->bl && currentElement->bl->isValueRelevant)
        {
          currentElement->value = !currentElement->isValueRelevant ? currentElement->bl->value :
            chalkBoolCombine(currentElement->bl->value, currentElement->value);
          currentElement->isValueRelevant = YES;
        }//end if (currentElement->bl && currentElement->bl->isValueRelevant)
        if (currentElement->br && currentElement->br->isValueRelevant)
        {
          currentElement->value = !currentElement->isValueRelevant ? currentElement->br->value :
            chalkBoolCombine(currentElement->br->value, currentElement->value);
          currentElement->isValueRelevant = YES;
        }//end if (currentElement->br && currentElement->br->isValueRelevant)
        if (!currentElement->isValueRelevant)
        {
          currentElement->value = CHALK_BOOL_MAYBE;
          currentElement->isValueRelevant = YES;
        }//end if (!currentElement->isValueRelevant)
        elements.pop_back();
      }//end if (!hasIrrelevantSubValue)
    }//end if (currentElement && !currentElement->isValueRelevant)
    stopQueue |= elements.empty();
    stopQueue |= stop && *stop;
  }//end while(!stopQueue)
}
//end adjust2dValues()

@interface CHGraphCurveCachedData ()
+(BOOL) performEvaluation:(chalk_graph_data_element_t*)element
       dynamicIdentifiers:(NSSet*)dynamicIdentifiers xIdentifier:(CHChalkIdentifier*)xIdentifier
               parserNode:(CHParserNode*)parserNode context:(CHChalkContext*)context;
+(chalk_bool_t) performEvaluation2d:(chalk_graph_data_element2d_t*)element
                 dynamicIdentifiers:(NSSet*)dynamicIdentifiers
                        xIdentifier:(CHChalkIdentifier*)xIdentifier
                        yIdentifier:(CHChalkIdentifier*)yIdentifier
                         parserNode:(CHParserNode*)parserNode context:(CHChalkContext*)context;
@end

@implementation CHGraphCurveCachedData

@synthesize curve;
@synthesize isDirty;
@synthesize isPreparing;
@synthesize isPreparingDirty;
@synthesize contextBounds;
@synthesize cachedData;
@synthesize cachedDataSize;
@dynamic    cachedDataSizeZ;
@synthesize rootElement2d;

+(void) initialize
{
  [self exposeBinding:@"isPreparing"];
}
//end initialize

-(instancetype) initWithCurve:(CHGraphCurve*)aCurve graphContext:(CHGraphContext*)aGraphContext graphGmpPool:(CHGmpPool*)aGraphGmpPool graphDataPool:(CHGraphDataPool*)aGraphDataPool
{
  if (!((self = [super init])))
    return nil;
  self->curve = [aCurve retain];
  self->fillingSemaphore = dispatch_semaphore_create(1);
  self->graphContext = [aGraphContext retain];
  self->graphGmpPool = [aGraphGmpPool retain];
  self->graphDataPool = [aGraphDataPool retain];
  self->chalkContext = [self->curve.chalkContext retain];
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpzDepool(self->cachedDataSizeZ, self->graphDataPool.gmpPool);
  mpz_set_nsui(self->cachedDataSizeZ, self->cachedDataSize);
  chalkGmpFlagsRestore(oldFlags);
  self->isDirty = YES;
  return self;
}
//end initWithGraphDataPool:context:

-(void) dealloc
{
  [self cancelFilling];
  [self waitFillingEnd];
  if (self->cachedData)
  {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply_gmp(self->cachedDataSize, queue, ^(size_t index) {
      repoolGraphElement(&self->cachedData[index], self->graphDataPool);
    });//end for each data
    free(self->cachedData);
    self->cachedData = 0;
    self->cachedDataSize = 0;
  }//end if (self->cachedData)
  mpzRepool(self->cachedDataSizeZ, self->graphDataPool.gmpPool);
  repoolGraphElement2d(&self->rootElement2d, self->graphDataPool);
  self->rootElement2d = 0;
  if (self->fillingSemaphore)
    dispatch_release(self->fillingSemaphore);
  [self->graphDataPool release];
  [self->graphGmpPool release];
  [self->graphContext release];
  [self->chalkContext release];
  [self->curve release];
  [super dealloc];
}
//end dealloc

-(mpz_srcptr) cachedDataSizeZ
{
  return self->cachedDataSizeZ;
}
//end cachedDataSizeZ

-(void) setCachedDataSize:(size_t)value
{
  if (self->cachedDataSize != value)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
    size_t oldCachedDataSize = self->cachedDataSize;
    size_t newCachedDataSize = value;
    BOOL exceedingDataCleared = NO;
    if (newCachedDataSize<oldCachedDataSize)
    {
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      dispatch_apply_gmp(oldCachedDataSize-newCachedDataSize, queue, ^(size_t index) {
        repoolGraphElement(&self->cachedData[newCachedDataSize+index], self->graphDataPool);
      });//end for each data
      exceedingDataCleared = YES;
    }//end if (newCachedDataSize<oldCachedDataSize)

    chalk_graph_data_element_t** newCachedData =
      (newCachedDataSize == oldCachedDataSize) ? self->cachedData :
      (chalk_graph_data_element_t**)realloc(self->cachedData, newCachedDataSize*sizeof(chalk_graph_data_element_t*));
    if (!newCachedData)
    {
      newCachedDataSize = 0;
      if (self->cachedData)
      {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply_gmp(exceedingDataCleared ? newCachedDataSize : oldCachedDataSize, queue, ^(size_t index) {
          repoolGraphElement(&self->cachedData[index], self->graphDataPool);
        });//end for each data
        free(self->cachedData);
        self->cachedData = 0;
      }//end if (self->cachedData)
    }//end if (!newCachedData)
    else//if (newCachedData)
    {
      if (newCachedDataSize > oldCachedDataSize)
      {
        memset(&newCachedData[oldCachedDataSize], 0, (newCachedDataSize-oldCachedDataSize)*sizeof(chalk_graph_data_element_t*));
        mpfr_prec_t prec = self->chalkContext.computationConfiguration.softFloatSignificandBits;
        __block BOOL error = NO;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply_gmp(newCachedDataSize-oldCachedDataSize, queue, ^(size_t index) {
          chalk_graph_data_element_t* element = [self->graphDataPool depoolGraphDataElement];
          if (!element)
            error = YES;
          else//if (element)
          {
            newCachedData[oldCachedDataSize+index] = element;
            chalkGmpValueMakeRealApprox(&element->x, prec, self->graphDataPool.gmpPool);
          }//end if (element)
        });//end for each data
        if (error)
        {
          if (self->cachedData)
          {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_apply_gmp(newCachedDataSize, queue, ^(size_t index) {
              repoolGraphElement(&self->cachedData[index], self->graphDataPool);
            });//end for each data
            free(self->cachedData);
            self->cachedData = 0;
          }//end if (self->cachedData)
          newCachedDataSize = 0;
        }//end if (error)
      }//end if (newCachedDataSize > oldCachedDataSize)
    }//end if (self->cachedData)
    self->cachedDataSize = newCachedDataSize;
    mpz_set_nsui(self->cachedDataSizeZ, self->cachedDataSize);
    self->cachedData = newCachedData;
    self->isDirty = YES;
    chalkGmpFlagsRestore(oldFlags);
  }//end if (self->cachedDataSize != value)
}
//end setCachedDataSize:

+(BOOL) performEvaluation:(chalk_graph_data_element_t*)element
       dynamicIdentifiers:(NSSet*)dynamicIdentifiers xIdentifier:(CHChalkIdentifier*)xIdentifier
               parserNode:(CHParserNode*)parserNode context:(CHChalkContext*)context
{
  BOOL result = NO;
  chalk_gmp_value_t* xValue = &(element->x);
  chalk_gmp_value_t* yValue = &(element->y);
  chalk_gmp_value_t* yEstimationValue = &(element->yEstimation);
  CHChalkIdentifierManagerWrapper* localIdentifierManager =
    [context.identifierManager dynamicCastToClass:[CHChalkIdentifierManagerWrapper class]];
  if (localIdentifierManager)
    [localIdentifierManager resetDynamicIdentifierValues];
  else//if (!localIdentifierManager)
  {
    localIdentifierManager =
      [[[CHChalkIdentifierManagerWrapper alloc] initSharing:context.identifierManager] autorelease];
    context.identifierManager = localIdentifierManager;
  }//end if (!localIdentifierManager)
  CHChalkValueNumberGmp* xValueWrapper = [[localIdentifierManager valueForIdentifier:xIdentifier] dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (!xValueWrapper)
  {
    xValueWrapper = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:0 naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
  }//end if (!xValueWrapper)
  [localIdentifierManager setValue:xValueWrapper forIdentifier:xIdentifier];
  [xValueWrapper setValueReference:xValue clearPrevious:NO isValueWapperOnly:YES];
  element->y_px = NSRangeNotFound;
  element->yEstimation_px = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
  CHChalkValueNumberGmp* yValueWrapper = nil;
  [parserNode resetEvaluationMatchingIdentifiers:dynamicIdentifiers identifierManager:localIdentifierManager];
  [parserNode performEvaluationWithContext:context lazy:YES];
  yValueWrapper = [parserNode.evaluatedValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (!yValueWrapper)
  {
    chalkGmpValueSetNan(yValue, NO, context.gmpPool);
    chalkGmpValueSetNan(yEstimationValue, NO, context.gmpPool);
    element->yEstimation_px.flags |= CHGRAPH_PIXEL_FLAG_NAN;
    [context.errorContext reset:nil];
    result = (parserNode != nil);
  }//end if (yValueWrapper)
  else//if (!yValueWrapper)
  {
    chalkGmpValueSet(yValue, yValueWrapper.valueConstReference, context.gmpPool);
    if (yValue->type == CHALK_VALUE_TYPE_INTEGER)
      chalkGmpValueSet(yEstimationValue, yValue, context.gmpPool);
    else if (yValue->type == CHALK_VALUE_TYPE_FRACTION)
    {
      chalkGmpValueSet(yEstimationValue, yValue, context.gmpPool);
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealExact(yEstimationValue, prec, context.gmpPool);
    }//end if (yValue->type == CHALK_VALUE_TYPE_FRACTION)
    else if (yValue->type == CHALK_VALUE_TYPE_REAL_EXACT)
      chalkGmpValueSet(yEstimationValue, yValue, context.gmpPool);
    else if (yValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
    {
      chalkGmpValueSet(yEstimationValue, yValue, context.gmpPool);
      mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
      chalkGmpValueMakeRealExact(yEstimationValue, prec, context.gmpPool);
      mpfr_srcptr left = &yEstimationValue->realApprox->interval.left;
      mpfr_srcptr right = &yEstimationValue->realApprox->interval.right;
      if (mpfr_inf_p(left))
        element->yEstimation_px.flags |=
          (mpfr_sgn(left)<0) ? CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE :
          (mpfr_sgn(left)>0) ? CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE :
          CHGRAPH_PIXEL_FLAG_NONE;
      if (mpfr_inf_p(right))
        element->yEstimation_px.flags |=
          (mpfr_sgn(right)<0) ? CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE :
          (mpfr_sgn(right)>0) ? CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE :
          CHGRAPH_PIXEL_FLAG_NONE;
    }//end if (yValue->type == CHALK_VALUE_TYPE_REAL_APPROX)
    result = YES;
  }//end if (yValueWrapper)
  return result;
}
//end performEvaluation:dynamicIdentifiers:xIdentifier:parserNode:context:

+(chalk_bool_t) performEvaluation2d:(chalk_graph_data_element2d_t*)element
                 dynamicIdentifiers:(NSSet*)dynamicIdentifiers
                        xIdentifier:(CHChalkIdentifier*)xIdentifier
                        yIdentifier:(CHChalkIdentifier*)yIdentifier
                         parserNode:(CHParserNode*)parserNode context:(CHChalkContext*)context
{
  chalk_bool_t result = CHALK_BOOL_MAYBE;
  chalk_gmp_value_t* xValue = &(element->x);
  chalk_gmp_value_t* yValue = &(element->y);
  CHChalkIdentifierManagerWrapper* localIdentifierManager =
    [context.identifierManager dynamicCastToClass:[CHChalkIdentifierManagerWrapper class]];
  if (localIdentifierManager)
    [localIdentifierManager resetDynamicIdentifierValues];
  else//if (!localIdentifierManager)
  {
    localIdentifierManager =
      [[[CHChalkIdentifierManagerWrapper alloc] initSharing:context.identifierManager] autorelease];
    context.identifierManager = localIdentifierManager;
  }//end if (!localIdentifierManager)
  CHChalkValueNumberGmp* xValueWrapper = [[localIdentifierManager valueForIdentifier:xIdentifier] dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (!xValueWrapper)
  {
    xValueWrapper = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:0 naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
  }//end if (!xValueWrapper)
  CHChalkValueNumberGmp* yValueWrapper = [[localIdentifierManager valueForIdentifier:yIdentifier] dynamicCastToClass:[CHChalkValueNumberGmp class]];
  if (!yValueWrapper)
  {
    yValueWrapper = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:0 naturalBase:context.computationConfiguration.baseDefault context:context] autorelease];
  }//end if (!xValueWrapper)
  [localIdentifierManager setValue:xValueWrapper forIdentifier:xIdentifier];
  [localIdentifierManager setValue:yValueWrapper forIdentifier:yIdentifier];
  [xValueWrapper setValueReference:xValue clearPrevious:NO isValueWapperOnly:YES];
  [yValueWrapper setValueReference:yValue clearPrevious:NO isValueWapperOnly:YES];

  [parserNode resetEvaluationMatchingIdentifiers:dynamicIdentifiers identifierManager:localIdentifierManager];
  [parserNode performEvaluationWithContext:context lazy:YES];
  CHChalkValueBoolean* value = [parserNode.evaluatedValue dynamicCastToClass:[CHChalkValueBoolean class]];
  if (context.errorContext.hasError)
    result = CHALK_BOOL_MAYBE;
  else//if (!context.errorContext.hasError)
  {
    result = !value ? CHALK_BOOL_NO :
      chalkGmpFlagsTest(value.evaluationComputeFlags, CHALK_COMPUTE_FLAG_ERANGE) ? CHALK_BOOL_MAYBE :
      value.chalkBoolValue;
  }//end if (!context.errorContext.hasError)
  return result;
}
//end performEvaluation2d:dynamicIdentifiers:xIdentifier:parserNode:context:

-(void) invalidate
{
  BOOL shouldWait = NO;
  @synchronized(self)
  {
    if (self.isPreparing)
    {
      self->shouldStopFilling = YES;
      self->isPreparingDirty = YES;
      shouldWait = YES;
    }//end if (self.isPreparing)
  }//end @synchronized(self)
  if (shouldWait)
    [self waitFillingEnd];
  @synchronized(self)
  {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply_gmp(self->cachedDataSize, queue, ^(size_t index) {
      if (self->cachedData[index])
      {
        repoolGraphElement(&self->cachedData[index]->left, self->graphDataPool);
        repoolGraphElement(&self->cachedData[index]->right, self->graphDataPool);
      }//end if (self->cachedData[index])
    });//end for each data
    self->isDirty = YES;
  }//end @synchronized(self)
}
//end invalidate

-(void) startFilling:(CHGraphView*)graphView rect:(CGRect)rect callBackEnd:(callback_end_t)callBackEnd
{
  [self cancelFilling];
  [self waitFillingEnd];
  @synchronized(self)
  {
    if (!self.isPreparing)
    {
      dispatch_semaphore_wait(self->fillingSemaphore, DISPATCH_TIME_FOREVER);
      [self willChangeValueForKey:@"isPreparing"];
      self->isPreparing = YES;
      [self didChangeValueForKey:@"isPreparing"];
    }//end if (!self.isPreparing)
    self->shouldStopFilling = NO;
  }//end @synchronized(self)
  dispatch_async_gmp(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if (graphView && curve)
    {
      mpz_t _cachedBoundsWidthPixelZ;
      mpz_t _cachedBoundsHeightPixelZ;
      mpzDepool(_cachedBoundsWidthPixelZ, self->graphGmpPool);
      mpzDepool(_cachedBoundsHeightPixelZ, self->graphGmpPool);
      mpz_set_nsui(_cachedBoundsWidthPixelZ, rect.size.width);
      mpz_set_nsui(_cachedBoundsHeightPixelZ, rect.size.height);
      mpz_srcptr cachedBoundsWidthPixelZ = _cachedBoundsWidthPixelZ;
      mpz_srcptr cachedBoundsHeightPixelZ = _cachedBoundsHeightPixelZ;

      CHPool* parserNodePool =
        [[CHPool alloc] initWithMaxCapacity:NSUIntegerMax
                        defaultConstruction:^id{
                          id result = [curve.chalkParserNode copyWithZone:nil];
                          return result;
                        }];
      CHPool* chalkContextPool =
        [[CHPool alloc] initWithMaxCapacity:NSUIntegerMax
                        defaultConstruction:^id{
                          id result = [curve.chalkContext copyWithZone:nil];
                          return result;
                        }];
      CHChalkIdentifier* xIdentifier = [curve.chalkContext.identifierManager identifierForToken:@"x" createClass:[CHChalkIdentifier class]];
      CHChalkIdentifier* yIdentifier = [curve.chalkContext.identifierManager identifierForToken:@"y" createClass:[CHChalkIdentifier class]];

      chgraph_mode_t graphMode = curve.graphMode;
      if (graphMode == CHGRAPH_MODE_Y_FROM_X)
      {
        size_t newCachedDataSize = (size_t)ceil(rect.size.width);
        self->contextBounds = rect;
        self.cachedDataSize = newCachedDataSize;

        NSSet* dynamicIdentifiers = [NSSet setWithObjects:xIdentifier, nil];
        if (self->cachedDataSize == newCachedDataSize)
        {
          NSUInteger elementPixelSize = MAX(1, curve.elementPixelSize);
          size_t elementsCount = (self->cachedDataSize+elementPixelSize-1)/elementPixelSize;
          chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
          if (!curve.chalkParserNode)
          {
            BOOL allowConcurrentEvaluations = YES;
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            dispatch_applyWithOptions_gmp(elementsCount, queue,
                allowConcurrentEvaluations && curve.chalkContext.concurrentEvaluations ?
                (dispatch_options_t)DISPATCH_OPTION_NONE :
                (dispatch_options_t)(DISPATCH_OPTION_SYNCHRONOUS|DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL),
               ^(size_t index) {
              [CHGmpPool push:self->graphGmpPool];
              @autoreleasepool {
                chalk_graph_data_element_t* element = self->cachedData[index];
                element->x_px = NSMakeRange(index, elementPixelSize);
                element->subPixelLevel = 0;
                chalkGmpValueSetNan(&element->y, NO, self->graphGmpPool);
                chalkGmpValueSetNan(&element->yEstimation, NO, self->graphGmpPool);
                element->y_px = NSRangeNotFound;
                element->yEstimation_px = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
              }//end @autoreleasepool
              [CHGmpPool pop];
            });
          }//end if (!curve.chalkParserNode)
          else//if (curve.chalkParserNode)
          {
            mpz_srcptr pDataSizeZ = self->cachedDataSizeZ;
            CHGraphScale* xScale = graphContext.axisHorizontal1.scale;
            mpfi_srcptr xScaleComputeRange = xScale.computeRange;
            mpfr_srcptr pxScaleRangeComputeDiameter = xScale.computeDiameter;
            CHGraphScale* yScale = graphContext.axisVertical1.scale;

            [CHGmpPool push:self->graphGmpPool];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
           // NSUInteger elementPixelSize = MAX(1, curve.elementPixelSize);
            dispatch_applyWithOptions_gmp(elementsCount, queue,
                curve.chalkContext.concurrentEvaluations ?
                (dispatch_options_t)DISPATCH_OPTION_NONE :
                (dispatch_options_t)(DISPATCH_OPTION_SYNCHRONOUS|DISPATCH_OPTION_SYNCHRONOUS_AUTORELEASEPOOL),
               ^(size_t index) {
              [CHGmpPool push:self->graphGmpPool];
              @autoreleasepool {
                CHParserNode* localParserNode = [parserNodePool depool];
                CHChalkContext* localContext = [chalkContextPool depool];
                [localContext.errorContext reset:nil];

                chalk_graph_data_element_t* element = self->cachedData[index];
                element->x_px = NSMakeRange(index*elementPixelSize, elementPixelSize);
                chalk_gmp_value_t* xValue = &(element->x);
                chalk_gmp_value_t* yValue = &(element->y);
                chalk_gmp_value_t* yEstimationValue = &(element->yEstimation);
                chalkGmpValueMakeInteger(xValue, localContext.gmpPool);
                mpz_set_nsui(xValue->integer, element->x_px.location+element->x_px.length/2);
                mpfr_prec_t prec = localContext.computationConfiguration.softFloatSignificandBits;
                chalkGmpValueMakeRealApprox(xValue, prec, localContext.gmpPool);
                //mpfir_increase(xValue->realApprox, self->halfOne);
                mpfr_set_nsui(&xValue->realApprox->interval.left, element->x_px.location, MPFR_RNDN);
                mpfr_set_nsui(&xValue->realApprox->interval.right, NSMaxRange(element->x_px), MPFR_RNDN);
                mpfr_nextbelow(&xValue->realApprox->interval.right);
                mpfir_estimation_update(xValue->realApprox);
                chalkGmpValueMakeRealApprox(yValue, prec, localContext.gmpPool);
                mpfir_t tmpir;
                mpfirDepool(tmpir, prec, localContext.gmpPool);
                mpfir_div_z(tmpir, xValue->realApprox, pDataSizeZ);
                mpfir_mul_fr(xValue->realApprox, tmpir, pxScaleRangeComputeDiameter);
                mpfir_add_fr(tmpir, xValue->realApprox, &xScaleComputeRange->left);
                [xScale convertMpfirComputeValue:tmpir toVisualValue:xValue->realApprox];
                mpfirRepool(tmpir, localContext.gmpPool);
                BOOL evaluated = [[self class] performEvaluation:element dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier parserNode:localParserNode context:localContext];
                if (evaluated)
                {
                  element->y_px = [graphView convertGraphValueToPixelRange:yValue
                    pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                        context:localContext];
                  chgraph_pixel_flag_t oldFlags = element->yEstimation_px.flags;
                  element->yEstimation_px = [graphView convertGraphValueToPixel:yEstimationValue
                    pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                        context:localContext];
                  element->yEstimation_px.flags |= oldFlags;

                  BOOL useBisection = YES;
                  if (useBisection)
                  {
                    std::vector<bisect_exploration_t> stack;
                    chalk_graph_data_element_t* currentElement = element;
                    chalk_graph_data_element_t* primaryChild = 0;
                    chalk_graph_data_element_t* secondaryChild = 0;
                    int currentExplorationState = 0;
                    BOOL stop = !currentElement;
                    while(!stop)
                    {
                      BOOL stopDescend = YES;
                      if (currentExplorationState == 0)
                      {
                        BOOL canSplit = currentElement &&
                          (currentElement->x.type == CHALK_VALUE_TYPE_REAL_APPROX) &&
                          (currentElement->x_px.location != NSNotFound) &&
                          (currentElement->x_px.length > elementPixelSize);
                        if (!canSplit)
                        {
                          repoolGraphElement(&currentElement->left, self->graphDataPool);
                          repoolGraphElement(&currentElement->right, self->graphDataPool);
                        }//end if (!canSplit)
                        else//if (canSplit)
                        {
                          if (!currentElement->left)
                            currentElement->left = [self->graphDataPool depoolGraphDataElement];
                          if (!currentElement->right)
                             currentElement->right = [self->graphDataPool depoolGraphDataElement];
                          if (!currentElement->left || !currentElement->right)
                          {
                            repoolGraphElement(&currentElement->left, self->graphDataPool);
                            repoolGraphElement(&currentElement->right, self->graphDataPool);
                          }//end if (!currentElement->left || !currentElement->right)
                          else//if (currentElement->left && currentElement->right)
                          {
                            currentElement->left->x_px = currentElement->x_px;
                            currentElement->right->x_px = currentElement->x_px;
                            currentElement->left->subPixelLevel = currentElement->subPixelLevel+1;
                            currentElement->right->subPixelLevel = currentElement->subPixelLevel+1;
                            chalkGmpValueMakeRealApprox(&currentElement->left->x, mpfir_get_prec(currentElement->x.realApprox), localContext.gmpPool);
                            chalkGmpValueMakeRealApprox(&currentElement->right->x, mpfir_get_prec(currentElement->x.realApprox), localContext.gmpPool);
                            chalk_compute_flags_t flags = chalkGmpFlagsSave(NO);
                            mpfir_bisect(currentElement->left->x.realApprox,
                                         currentElement->right->x.realApprox,
                                         currentElement->x.realApprox);
                            BOOL underflow = mpfr_underflow_p();
                            chalkGmpFlagsRestore(flags);
                            if (underflow)
                            {
                              repoolGraphElement(&currentElement->left, self->graphDataPool);
                              repoolGraphElement(&currentElement->right, self->graphDataPool);
                            }//end if (underflow)
                            else//if (!underflow)
                            {
                              [localContext.errorContext reset:nil];
                              BOOL leftEvaluated = [[self class] performEvaluation:currentElement->left dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier parserNode:localParserNode context:localContext];
                              [localContext.errorContext reset:nil];
                              BOOL rightEvaluated = [[self class] performEvaluation:currentElement->right dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier parserNode:localParserNode context:localContext];
                              if (leftEvaluated)
                              {
                                currentElement->left->y_px = [graphView convertGraphValueToPixelRange:&currentElement->left->y
                                  pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                                      context:localContext];
                                chgraph_pixel_flag_t oldFlags = element->yEstimation_px.flags;
                                currentElement->left->yEstimation_px = [graphView convertGraphValueToPixel:&currentElement->left->yEstimation
                                  pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                                      context:localContext];
                                currentElement->left->yEstimation_px.flags |= oldFlags;
                              }//end if (leftEvaluated)
                              if (rightEvaluated)
                              {
                                currentElement->right->y_px = [graphView convertGraphValueToPixelRange:&currentElement->right->y
                                  pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                                       context:localContext];
                                chgraph_pixel_flag_t oldFlags = element->yEstimation_px.flags;
                                currentElement->right->yEstimation_px = [graphView convertGraphValueToPixel:&currentElement->right->yEstimation
                                  pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                                      context:localContext];
                                currentElement->right->yEstimation_px.flags |= oldFlags;
                              }//end if (rightEvaluated)
                              if (leftEvaluated && rightEvaluated)
                              {
                                NSRange newRange = NSRangeUnion(currentElement->left->y_px, currentElement->right->y_px);
                                BOOL shouldBisectAgain =
                                  (newRange.length < currentElement->y_px.length) &&
                                  NSRangeContains(currentElement->y_px, newRange.location);
                                currentElement->y_px = newRange;
                                if (shouldBisectAgain)
                                {
                                  primaryChild = (currentElement->left->y_px.length >= currentElement->right->y_px.length) ?
                                    currentElement->left : currentElement->right;
                                  secondaryChild = (primaryChild == currentElement->left) ?
                                    currentElement->right : currentElement->left;
                                  stack.push_back(bisect_exploration_t(currentElement, primaryChild, secondaryChild, 1));
                                  currentElement = primaryChild;
                                  currentExplorationState = 0;
                                  stopDescend = NO;
                                }//end if (shouldBisectAgain)
                              }//end if (leftEvaluated && rightEvaluated)
                            }//end if (!underflow)
                          }//end if (currentElement->left && currentElement->right)
                        }//end if (canSplit)
                      }//end if (currentExplorationState == 0)
                      else if (currentExplorationState == 1)
                      {
                        NSRange primaryChildRange = !primaryChild ? NSRangeNotFound : primaryChild->y_px;
                        NSRange secondaryChildRange = !secondaryChild ? NSRangeNotFound : secondaryChild->y_px;
                        BOOL secondaryExplorationCantImproveRange =
                          ((primaryChildRange.location == NSNotFound) ||
                           (secondaryChildRange.location == NSNotFound)
                          ) ||
                          (NSRangeContains(primaryChildRange, secondaryChildRange.location) &&
                            ((secondaryChildRange.location+secondaryChildRange.length) <=
                             (primaryChildRange.location+primaryChildRange.length))
                          );
                        if (!secondaryExplorationCantImproveRange)
                        {
                          stack.push_back(bisect_exploration_t(currentElement, primaryChild, secondaryChild, 2));
                          currentElement = secondaryChild;
                          currentExplorationState = 0;
                          stopDescend = NO;
                        }//end if (!secondaryExplorationCantImproveRange)
                      }//end if (currentExplorationState == 1)
                      else if (currentExplorationState == 2)
                      {
                        NSRange primaryChildRange = !primaryChild ? NSRangeNotFound : primaryChild->y_px;
                        NSRange secondaryChildRange = !secondaryChild ? NSRangeNotFound : secondaryChild->y_px;
                        currentElement->y_px = NSRangeUnion(primaryChildRange, secondaryChildRange);
                        repoolGraphElement(&currentElement->left, self->graphDataPool);
                        repoolGraphElement(&currentElement->right, self->graphDataPool);
                      }//end if (currentExplorationState == 2)
                      if (stopDescend)
                      {
                        if (stack.empty())
                          stop = YES;
                        else//if (!stack.empty())
                        {
                          bisect_exploration_t previousState = stack.back();
                          stack.pop_back();
                          currentElement = previousState.parent;
                          primaryChild = previousState.primaryChild;
                          secondaryChild = previousState.secondaryChild;
                          currentExplorationState = previousState.explorationState;
                        }//end if (!stack.empty())
                      }//end if (stopDescend)
                      stop |= !currentElement;
                    }//end while(!stop)
                  }//end if (useBisection)
                }//end if (evaluated)
                [chalkContextPool repool:localContext];
                [parserNodePool repool:localParserNode];
              }//end @autoreleasepool
              [CHGmpPool pop];
            });//end for each x
            [CHGmpPool pop];
          }//end if (curve.chalkParserNode)
          
          //add refinement step when a NAN element touches a non NAN element
          static const int refinementDirections[] = {1, -1};
          for(int refinementDirection : refinementDirections)
          {
            CHParserNode* localParserNode = [parserNodePool depool];
            CHChalkContext* localContext = [chalkContextPool depool];
            [localContext.errorContext reset:nil];
            for(size_t index = 0 ; index+1<elementsCount ; ++index)
            {
              CHGraphScale* yScale = graphContext.axisVertical1.scale;
              chalk_graph_data_element_t* left = self->cachedData[index+0];
              chalk_graph_data_element_t* right = self->cachedData[index+1];
              chalk_graph_data_element_t* rootElementToRefine =
                (refinementDirection == 1) ? left :
                (refinementDirection == -1) ? right :
                0;
              const chalk_gmp_value_t* leftY = !left ? 0 : &left->y;
              const chalk_gmp_value_t* rightY = !right ? 0 : &right->y;
              mpfir_srcptr currentX = !rootElementToRefine || (rootElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : rootElementToRefine->x.realApprox;
              mpfr_prec_t prec = !currentX ? 0 : mpfir_get_prec(currentX);
              BOOL shouldRefine =
                localParserNode && localContext &&
                currentX && rootElementToRefine && leftY && rightY &&
                (chalkGmpValueIsNan(leftY) ^ chalkGmpValueIsNan(rightY));
              if (shouldRefine)
              {
                chalk_graph_data_element_t* currentElementToRefine = rootElementToRefine;
                static const NSUInteger maxSubPixelLevel = 16;
                BOOL stopRefine = !currentX || !currentElementToRefine || (currentElementToRefine->subPixelLevel >= maxSubPixelLevel);
                while(!stopRefine)
                {
                  if (!currentElementToRefine->left)
                    currentElementToRefine->left = [self->graphDataPool depoolGraphDataElement];
                  if (!currentElementToRefine->right)
                     currentElementToRefine->right = [self->graphDataPool depoolGraphDataElement];
                  if (!currentElementToRefine->left || !currentElementToRefine->right)
                  {
                    repoolGraphElement(&currentElementToRefine->left, self->graphDataPool);
                    repoolGraphElement(&currentElementToRefine->right, self->graphDataPool);
                    stopRefine = YES;
                  }//end if (!currentElementToRefine->left || !currentElementToRefine->right)
                  else//if (currentElementToRefine->left && currentElementToRefine->right)
                  {
                    currentElementToRefine->left->x_px = currentElementToRefine->x_px;
                    currentElementToRefine->right->x_px = currentElementToRefine->x_px;
                    currentElementToRefine->left->subPixelLevel = currentElementToRefine->subPixelLevel+1;
                    currentElementToRefine->right->subPixelLevel = currentElementToRefine->subPixelLevel+1;
                    chalkGmpValueMakeRealApprox(&currentElementToRefine->left->x, prec, self->graphGmpPool);
                    chalkGmpValueMakeRealApprox(&currentElementToRefine->right->x, prec, self->graphGmpPool);
                    mpfir_bisect(currentElementToRefine->left->x.realApprox, currentElementToRefine->right->x.realApprox, currentX);

                    [localContext.errorContext reset:nil];
                    BOOL leftEvaluated = [[self class] performEvaluation:currentElementToRefine->left dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier parserNode:localParserNode context:localContext];
                    [localContext.errorContext reset:nil];
                    BOOL rightEvaluated = [[self class] performEvaluation:currentElementToRefine->right dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier parserNode:localParserNode context:localContext];

                    if (leftEvaluated)
                    {
                      currentElementToRefine->left->y_px = [graphView convertGraphValueToPixelRange:&currentElementToRefine->left->y
                        pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                            context:localContext];
                      chgraph_pixel_flag_t oldFlags = currentElementToRefine->yEstimation_px.flags;
                      currentElementToRefine->left->yEstimation_px = [graphView convertGraphValueToPixel:&currentElementToRefine->left->yEstimation
                        pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                            context:localContext];
                      currentElementToRefine->left->yEstimation_px.flags |= oldFlags;
                    }//end if (leftEvaluated)
                    if (rightEvaluated)
                    {
                      currentElementToRefine->right->y_px = [graphView convertGraphValueToPixelRange:&currentElementToRefine->right->y
                        pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                             context:localContext];
                      chgraph_pixel_flag_t oldFlags = currentElementToRefine->yEstimation_px.flags;
                      currentElementToRefine->right->yEstimation_px = [graphView convertGraphValueToPixel:&currentElementToRefine->right->yEstimation
                        pixelsCount:cachedBoundsHeightPixelZ scale:yScale
                            context:localContext];
                      currentElementToRefine->right->yEstimation_px.flags |= oldFlags;
                    }//end if (rightEvaluated)
                    
                    if (leftEvaluated && rightEvaluated)
                    {
                      rootElementToRefine->y_px = NSRangeUnion(rootElementToRefine->y_px, currentElementToRefine->left->y_px);
                      rootElementToRefine->y_px = NSRangeUnion(rootElementToRefine->y_px, currentElementToRefine->right->y_px);
                    }//end if (leftEvaluated && rightEvaluated)

                    if (currentElementToRefine->subPixelLevel >= maxSubPixelLevel)
                    {
                      stopRefine = YES;
                    }
                    else if ((refinementDirection == 1) && chalkGmpValueIsNan(&currentElementToRefine->right->y))
                    {
                      currentElementToRefine = currentElementToRefine->right;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end if ((refinementDirection == 1) && chalkGmpValueIsNan(&currentElementToRefine->right->y))
                    else if ((refinementDirection == 1) && chalkGmpValueIsNan(&currentElementToRefine->left->y))
                    {
                      currentElementToRefine = currentElementToRefine->left;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end if ((refinementDirection == 1) && chalkGmpValueIsNan(&currentElementToRefine->left->y))
                    else if (refinementDirection == 1)
                    {
                      currentElementToRefine = currentElementToRefine->left;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end (refinementDirection == 1)
                    else if ((refinementDirection == -1) && chalkGmpValueIsNan(&currentElementToRefine->left->y))
                    {
                      currentElementToRefine = currentElementToRefine->left;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end if ((refinementDirection == -1) && chalkGmpValueIsNan(&currentElementToRefine->left->y))
                    else if ((refinementDirection == -1) && chalkGmpValueIsNan(&currentElementToRefine->right->y))
                    {
                      currentElementToRefine = currentElementToRefine->right;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end if ((refinementDirection == -1) && chalkGmpValueIsNan(&currentElementToRefine->right->y))
                    else if (refinementDirection == -1)
                    {
                      currentElementToRefine = currentElementToRefine->right;
                      currentX = (currentElementToRefine->x.type != CHALK_VALUE_TYPE_REAL_APPROX) ? 0 : currentElementToRefine->x.realApprox;
                    }//end (refinementDirection == -1)
                    else
                      stopRefine = YES;
                    stopRefine |= !currentElementToRefine || !currentX;
                  }//end if (currentElementToRefine->left && currentElementToRefine->right)
                }//end while(!stopRefine)
              }//end if (shouldRefine)
            }//end for each element
            [parserNodePool repool:localParserNode];
            [chalkContextPool repool:localContext];
          }//end for each refinementDirection
          chalkGmpFlagsRestore(oldFlags);
        }//end if (self->cachedDataSize == newCachedDataSize)
      }//end if (graphMode == CHGRAPH_MODE_Y_FROM_X)
      else if (graphMode == CHGRAPH_MODE_XY_PREDICATE)
      {
        chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
        self->contextBounds = rect;
        repoolGraphElement2d(&self->rootElement2d, self->graphDataPool);
        depoolGraphElement2d(&self->rootElement2d, self->graphDataPool);

        NSSet* dynamicIdentifiers = [NSSet setWithObjects:xIdentifier, yIdentifier, nil];
        explore2d_eval_block_t evalBlock =
          ^(chalk_graph_data_element2d_t* element2d, NSUInteger pixelLmit, CHParserNode* parserNode, CHChalkContext* context, volatile BOOL* stop){
            CHGraphScale* xScale = self->graphContext.axisHorizontal1.scale;
            CHGraphScale* yScale = self->graphContext.axisVertical1.scale;
            [graphView convertPixelRange:element2d->x_px toGraphValue:&element2d->x pixelsCount:cachedBoundsWidthPixelZ scale:xScale context:context];
            [graphView convertPixelRange:element2d->y_px toGraphValue:&element2d->y pixelsCount:cachedBoundsHeightPixelZ scale:yScale context:context];
            element2d->value = [[self class] performEvaluation2d:element2d dynamicIdentifiers:dynamicIdentifiers xIdentifier:xIdentifier yIdentifier:yIdentifier parserNode:parserNode context:context];
            CHParserNode* lastErrorContextObject = [context.errorContext.error.contextGenerator dynamicCastToClass:[CHParserNode class]];
            element2d->isValueRelevant = YES;
            element2d->isXSplitIrrelevant |=
              //!isUsingXIdentifier ||
              (lastErrorContextObject && ![lastErrorContextObject isUsingIdentifier:xIdentifier identifierManager:context.identifierManager]);
            element2d->isYSplitIrrelevant |=
              //!isUsingYIdentifier ||
              (lastErrorContextObject && ![lastErrorContextObject isUsingIdentifier:yIdentifier identifierManager:context.identifierManager]);
            [context.errorContext reset:nil];
          };
        chalk_graph_data_element2d_t* currentElement2d = self->rootElement2d;
        if (currentElement2d)
        {
          currentElement2d->x_px = NSMakeRange(0, (size_t)ceil(rect.size.width));
          currentElement2d->y_px = NSMakeRange(0, (size_t)ceil(rect.size.height));
          CHParserNode* localParserNode = [parserNodePool depool];
          CHChalkContext* localContext = [chalkContextPool depool];
          [localContext.errorContext reset:nil];
          BOOL isUsingXIdentifier = [curve.chalkParserNode isUsingIdentifier:xIdentifier identifierManager:localContext.identifierManager];
          BOOL isUsingYIdentifier = [curve.chalkParserNode isUsingIdentifier:yIdentifier identifierManager:localContext.identifierManager];
          currentElement2d->isXSplitIrrelevant |= !isUsingXIdentifier;
          currentElement2d->isYSplitIrrelevant |= !isUsingYIdentifier;
          NSUInteger elementPixelSize = curve.elementPixelSize;
          evalBlock(currentElement2d, elementPixelSize, localParserNode, localContext, &shouldStopFilling);
          explore2d(currentElement2d, elementPixelSize, self->graphDataPool, parserNodePool, chalkContextPool, localContext.concurrentEvaluations, evalBlock, &shouldStopFilling);
          adjust2dValues(currentElement2d, &shouldStopFilling);
          [parserNodePool repool:localParserNode];
          [chalkContextPool repool:localContext];
        }//end if (currentElement2d)
        chalkGmpFlagsRestore(oldFlags);
      }//end if (graphMode == CHGRAPH_MODE_XY_PREDICATE)
      [CHGmpPool push:self->graphGmpPool];
      [chalkContextPool release];
      [parserNodePool release];
      [CHGmpPool pop];
      
      mpzRepool(_cachedBoundsWidthPixelZ, self->graphGmpPool);
      mpzRepool(_cachedBoundsHeightPixelZ, self->graphGmpPool);
      self->isDirty = NO;
    }//end if (graphView && curve)
    BOOL success = NO;
    BOOL didChangeIsPreparing = NO;
    @synchronized(self)
    {
      if (self.isPreparing)
      {
        dispatch_semaphore_signal(self->fillingSemaphore);
        didChangeIsPreparing = YES;
        self->isPreparing = NO;
      }//end if (self.isPreparing)
      self->isDirty = self->isPreparingDirty;
      self->isPreparingDirty = NO;
      success = !self->isDirty && !self->shouldStopFilling;
    }//end @synchronized(self)
    callBackEnd(success);
    if (didChangeIsPreparing)
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"isPreparing"];
        [self didChangeValueForKey:@"isPreparing"];
      });
    }//end if (didChangeIsPreparing)
  });
}
//end startFilling:curve:rect:endCallback

-(void) cancelFilling
{
  @synchronized(self)
  {
    if (self.isPreparing)
    {
      self->shouldStopFilling = YES;
    }//end if (self.isPreparing)
  }//end @synchronized(self)
}
//end cancelFilling

-(void) waitFillingEnd
{
  if (self->fillingSemaphore)
  {
    dispatch_semaphore_wait(self->fillingSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(self->fillingSemaphore);
  }//end if (self->fillingSemaphore)
}
//end waitFillingEnd

-(void) setIsPreparingDirty:(BOOL)value
{
  if (value != self->isPreparingDirty)
  {
    @synchronized(self)
    {
      self->isPreparingDirty = value;
    }//end @synchronized(self)
  }//end if (value != self->isPreparingDirty)
}
//end setIsPreparingDirty:

@end
