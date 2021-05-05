//
//  CHGraphScale.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHGraphScale.h"

#import "CHGmpPool.h"
#import "CHChalkUtils.h"

@implementation CHGraphScale

@synthesize prec;
@synthesize dataType;
@synthesize scaleType;
@dynamic    computeRange;
@dynamic    visualRange;
@dynamic    currentBase;
@synthesize logarithmicBase;
@dynamic    logarithmicBase_fr;
@dynamic    logarithmicBaseLog;
@dynamic    computeDiameter;
@dynamic    visualDiameter;

-(instancetype) init
{
  return [self initWithPrec:mpfr_get_default_prec() gmpPool:nil];
}
//end init

-(instancetype) initWithPrec:(mpfr_prec_t)aPrec gmpPool:(CHGmpPool*)aGmpPool
{
  if (!((self = [super init])))
    return nil;
  self->prec = aPrec;
  self->gmpPool = [aGmpPool retain];
  self->dataType = CHGRAPH_DATA_TYPE_VALUE;
  self->scaleType = CHGRAPH_SCALE_LINEAR;
  self->logarithmicBase = 10;
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfrDepool(self->logarithmicBase_fr, self->prec, self->gmpPool);
  mpfr_set_si(self->logarithmicBase_fr, self->logarithmicBase, MPFR_RNDN);
  mpfiDepool(self->logarithmicBase_fi, self->prec, self->gmpPool);
  mpfi_set_si(self->logarithmicBase_fi, self->logarithmicBase);
  mpfirDepool(self->logarithmicBase_fir, self->prec, self->gmpPool);
  mpfir_set_si(self->logarithmicBase_fir, self->logarithmicBase);
  mpfirDepool(self->logarithmicBaseLog, self->prec, self->gmpPool);
  mpfir_set_fr(self->logarithmicBaseLog, self->logarithmicBase_fr);
  mpfir_log(self->logarithmicBaseLog, self->logarithmicBaseLog);
  mpfrDepool(self->computeDiameter, self->prec, self->gmpPool);
  mpfr_set_si(self->computeDiameter, 0, MPFR_RNDN);
  mpfrDepool(self->visualDiameter, self->prec, self->gmpPool);
  mpfr_set_si(self->visualDiameter, 0, MPFR_RNDN);
  mpfiDepool(self->linearComputeRange, self->prec, self->gmpPool);
  mpfr_set_d(&self->linearComputeRange->left, -10, MPFR_RNDD);
  mpfr_set_d(&self->linearComputeRange->right, 10, MPFR_RNDU);
  mpfiDepool(self->logarithmicComputeRange, self->prec, self->gmpPool);
  mpfr_set_d(&self->logarithmicComputeRange->left, -10, MPFR_RNDD);
  mpfr_set_d(&self->logarithmicComputeRange->right, 10, MPFR_RNDU);
  mpfiDepool(self->logarithmicVisualRange, self->prec, self->gmpPool);
  chalkGmpFlagsRestore(oldFlags);
  [self updateData];
  return self;
}
//end initWithPool:

-(void) dealloc
{
  mpfiRepool(self->linearComputeRange, self->gmpPool);
  mpfiRepool(self->logarithmicComputeRange, self->gmpPool);
  mpfiRepool(self->logarithmicVisualRange, self->gmpPool);
  mpfrRepool(self->logarithmicBase_fr, self->gmpPool);
  mpfiRepool(self->logarithmicBase_fi, self->gmpPool);
  mpfirRepool(self->logarithmicBase_fir, self->gmpPool);
  mpfirRepool(self->logarithmicBaseLog, self->gmpPool);
  mpfrRepool(self->computeDiameter, self->gmpPool);
  mpfrRepool(self->visualDiameter, self->gmpPool);
  [self->gmpPool release];
  [super dealloc];
}
//end dealloc

-(mpfi_ptr) computeRange
{
  mpfi_ptr result =
    (self->scaleType == CHGRAPH_SCALE_LINEAR) ? self->linearComputeRange :
    (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC) ? self->logarithmicComputeRange :
    0;
  return result;
}
//end computeRange

-(mpfi_srcptr) visualRange
{
  mpfi_srcptr result =
    (self->scaleType == CHGRAPH_SCALE_LINEAR) ? self->linearComputeRange :
    (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC) ? self->logarithmicVisualRange :
    0;
  return result;
}
//end visualRange

-(void) updateData
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfr_set_si(self->logarithmicBase_fr, self->logarithmicBase, MPFR_RNDN);
  mpfi_set_si(self->logarithmicBase_fi, self->logarithmicBase);
  mpfir_set_si(self->logarithmicBase_fir, self->logarithmicBase);
  mpfir_set_fr(self->logarithmicBaseLog, self->logarithmicBase_fr);
  mpfir_log(self->logarithmicBaseLog, self->logarithmicBaseLog);
  mpfr_pow(&self->logarithmicVisualRange->left, self->logarithmicBase_fr, &self->logarithmicComputeRange->left, MPFR_RNDN);
  mpfr_pow(&self->logarithmicVisualRange->right, self->logarithmicBase_fr, &self->logarithmicComputeRange->right, MPFR_RNDN);
  mpfi_revert_if_needed(self->logarithmicVisualRange);
  mpfi_diam_abs(self->computeDiameter, self.computeRange);
  mpfi_diam_abs(self->visualDiameter, self.visualRange);
  chalkGmpFlagsRestore(oldFlags);
}
//end updateData

-(int) currentBase
{
  int result = (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC) ? self->logarithmicBase : 10;
  return result;
}
//end currentBase

-(void) setLogarithmicBase:(int)value
{
  if (value != self->logarithmicBase)
  {
    self->logarithmicBase = value;
    [self updateData];
  }//end if (value != self->logarithmicBase)
}
//end setLogarithmicBase:

-(mpfr_srcptr) logarithmicBase_fr
{
  mpfr_srcptr result = self->logarithmicBase_fr;
  return result;
}
//end logarithmicBase_fr

-(mpfir_srcptr) logarithmicBaseLog
{
  mpfir_srcptr result = self->logarithmicBaseLog;
  return result;
}
//end logarithmicBaseLog

-(mpfr_srcptr) computeDiameter
{
  mpfr_srcptr result = self->computeDiameter;
  return result;
}
//end computeDiameter

-(mpfr_srcptr) visualDiameter
{
  mpfr_srcptr result = self->visualDiameter;
  return result;
}
//end visualDiameter

-(void) setPrec:(mpfr_prec_t)value
{
  if (value != self->prec)
  {
    self->prec = value;
    mpfi_set_prec(self->linearComputeRange, self->prec);
    mpfi_set_prec(self->logarithmicComputeRange, self->prec);
    mpfi_set_prec(self->logarithmicVisualRange, self->prec);
    mpfr_set_prec(self->logarithmicBase_fr, self->prec);
    mpfi_set_prec(self->logarithmicBase_fi, self->prec);
    mpfir_set_prec(self->logarithmicBase_fir, self->prec);
    mpfir_set_prec(self->logarithmicBaseLog, self->prec);
    mpfr_set_prec(self->computeDiameter, self->prec);
    mpfr_set_prec(self->visualDiameter, self->prec);
    [self updateData];
  }//end if (value != self->prec)
}
//end setPrec:

-(void) convertMpfrComputeValue:(mpfr_srcptr)computeValue toVisualValue:(mpfr_ptr)visualValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (computeValue != visualValue)
      mpfr_set(visualValue, computeValue, MPFR_RNDN);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
    mpfr_pow(visualValue, self->logarithmicBase_fr, computeValue, MPFR_RNDN);
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfrComputeValue:toVisualValue:

-(void) convertMpfiComputeValue:(mpfi_srcptr)computeValue toVisualValue:(mpfi_ptr)visualValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (computeValue != visualValue)
      mpfi_set(visualValue, computeValue);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
    mpfi_pow(visualValue, self->logarithmicBase_fi, computeValue);
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfiComputeValue:toVisualValue:

-(void) convertMpfirComputeValue:(mpfir_srcptr)computeValue toVisualValue:(mpfir_ptr)visualValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (computeValue != visualValue)
      mpfir_set(visualValue, computeValue);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
    mpfir_pow(visualValue, self->logarithmicBase_fir, computeValue);
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfirComputeValue:toVisualValue:

-(void) convertMpfrVisualValue:(mpfr_srcptr)visualValue toComputeValue:(mpfr_ptr)computeValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (visualValue != computeValue)
      mpfr_set(computeValue, visualValue, MPFR_RNDN);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  {
    mpfr_t tmp;
    mpfrDepool(tmp, self->prec, self->gmpPool);
    mpfr_log(tmp, visualValue, MPFR_RNDN);
    mpfr_div(computeValue, tmp, &self->logarithmicBaseLog->estimation, MPFR_RNDN);
    mpfrRepool(tmp, self->gmpPool);
  }//end if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfrComputeValue:toVisualValue:

-(void) convertMpfiVisualValue:(mpfi_srcptr)visualValue toComputeValue:(mpfi_ptr)computeValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (visualValue != computeValue)
      mpfi_set(computeValue, visualValue);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  {
    mpfi_t tmp;
    mpfiDepool(tmp, self->prec, self->gmpPool);
    mpfi_log(tmp, visualValue);
    mpfi_div(computeValue, tmp, &self->logarithmicBaseLog->interval);
    mpfiRepool(tmp, self->gmpPool);
  }//end if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfiComputeValue:toVisualValue:

-(void) convertMpfirVisualValue:(mpfir_srcptr)visualValue toComputeValue:(mpfir_ptr)computeValue
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  {
    if (visualValue != computeValue)
      mpfir_set(computeValue, visualValue);
  }//end if (self->scaleType == CHGRAPH_SCALE_LINEAR)
  else if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  {
    mpfir_t tmp;
    mpfirDepool(tmp, self->prec, self->gmpPool);
    mpfir_log(tmp, visualValue);
    mpfir_div(computeValue, tmp, self->logarithmicBaseLog);
    mpfirRepool(tmp, self->gmpPool);
  }//end if (self->scaleType == CHGRAPH_SCALE_LOGARITHMIC)
  chalkGmpFlagsRestore(oldFlags);
}
//end convertMpfirComputeValue:toVisualValue:

@end
