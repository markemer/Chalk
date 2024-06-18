//
//  CHGraphView.m
//  Chalk
//
//  Created by Pierre Chatelier on 08/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphView.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierManagerWrapper.h"
#import "CHChalkOperatorManager.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueBoolean.h"
#import "CHChalkValueNumberGmp.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHGraphContext.h"
#import "CHGraphAxis.h"
#import "CHGraphCurve.h"
#import "CHGraphCurveCachedData.h"
#import "CHGraphScale.h"
#import "CHParser.h"
#import "CHParserNode.h"
#import "CHPool.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"

#include <algorithm>
#include <deque>
#include <stack>
#include <vector>

static void RGBtoHSV(CGFloat r, CGFloat g, CGFloat b, CGFloat* h, CGFloat* s, CGFloat* v)
{
	float min, max, delta;
	min = MIN(MIN(r, g), b );
	max = MAX(MAX(r, g), b );
	*v = max;				// v
	delta = max - min;
	if( max != 0 )
		*s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		*s = 0;
		*h = -1;
		return;
	}
	if( r == max )
		*h = ( g - b ) / delta;		// between yellow & magenta
	else if( g == max )
		*h = 2 + ( b - r ) / delta;	// between cyan & yellow
	else
		*h = 4 + ( r - g ) / delta;	// between magenta & cyan
	*h *= 60;				// degrees
	if( *h < 0 )
		*h += 360;
}
//end RGBtoHSV()

static void HSVtoRGB(CGFloat h, CGFloat s, CGFloat v, CGFloat* r, CGFloat* g, CGFloat* b)
{
	int i;
	float f, p, q, t;
	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}
	h /= 60;			// sector 0 to 5
	i = floor( h );
	f = h - i;			// factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );
	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:		// case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}
//end HSVtoRGB()

static void interpolate(CGFloat r1, CGFloat g1, CGFloat b1, CGFloat r2, CGFloat g2, CGFloat b2, CGFloat factor, CGFloat* r, CGFloat* g, CGFloat* b)
{
  CGFloat h1, s1, v1, h2, s2, v2, h, s, v;
  RGBtoHSV(r1, g1, b1, &h1, &s1, &v1);
  RGBtoHSV(r2, g2, b2, &h2, &s2, &v2);
  if (h2<h1)
    std::swap(h1, h2);
  if (s2<s1)
    std::swap(s1, s2);
  if (v2<v1)
    std::swap(v1, v2);
  h = fmod(h1+factor*(h2-h1)+360, 360);
  s = s1+factor*(s2-s1);
  v = v1+factor*(v2-v1);
  HSVtoRGB(h, s, v, r, g, b);
}
//end interpolate()

static CGFloat interpolate(CGFloat x, CGFloat y, CGFloat factor)
{
  CGFloat result = 0;
  if (y<x)
    std::swap(x, y);
  result = x+factor*(y-x);
  return result;
}
//end interpolate()

void drawElement2d(CGContextRef cgContext, const chalk_graph_data_element2d_t* element,
                   NSUInteger pixelLimit, CGColorRef colors[5], BOOL drawEdges)
{
  std::vector<const chalk_graph_data_element2d_t*> elements;
  elements.push_back(element);
  BOOL stop = elements.empty();
  while(!stop)
  {
    const chalk_graph_data_element2d_t* currentElement = elements.back();
    elements.pop_back();
    BOOL canExploreElement = currentElement &&
      (currentElement->x_px.length>=MAX(1,pixelLimit)) &&
      (currentElement->y_px.length >= MAX(1, pixelLimit));
    if (canExploreElement)
    {
      CGRect rect = CGRectMake(currentElement->x_px.location, currentElement->y_px.location,
                               currentElement->x_px.length, currentElement->y_px.length);
      chalk_bool_t value = currentElement->isValueRelevant ? currentElement->value : CHALK_BOOL_MAYBE;
      switch(value)
      {
        case CHALK_BOOL_NO:
          CGContextSetFillColorWithColor(cgContext, colors[0]);
          CGContextSetStrokeColorWithColor(cgContext, colors[0]);
          break;
        case CHALK_BOOL_UNLIKELY:
          CGContextSetFillColorWithColor(cgContext, colors[1]);
          CGContextSetStrokeColorWithColor(cgContext, colors[1]);
          break;
        case CHALK_BOOL_MAYBE:
          CGContextSetFillColorWithColor(cgContext, colors[2]);
          CGContextSetStrokeColorWithColor(cgContext, colors[2]);
          break;
        case CHALK_BOOL_CERTAINLY:
          CGContextSetFillColorWithColor(cgContext, colors[3]);
          CGContextSetStrokeColorWithColor(cgContext, colors[3]);
          break;
        case CHALK_BOOL_YES:
          CGContextSetFillColorWithColor(cgContext, colors[4]);
          CGContextSetStrokeColorWithColor(cgContext, colors[4]);
          break;
      }//end switch(value)
      CGContextFillRect(cgContext, rect);
      if (drawEdges)
      {
        CGContextSetRGBStrokeColor(cgContext, 1, 0, 1, .5);
        CGContextStrokeRect(cgContext, rect);
      }//end if (drawEdges)
      elements.push_back(currentElement->tl);
      elements.push_back(currentElement->tr);
      elements.push_back(currentElement->bl);
      elements.push_back(currentElement->br);
    }//if (canExploreElement)
    stop |= elements.empty();
  }//end while(!stop)
}
//end drawElement2d()

@interface CHGraphView ()
@property(readonly) BOOL isGraphDragging;
@property(readonly) BOOL isGraphZoomingIn;
@property(readonly) BOOL isGraphZoomingOut;
@property(readonly) BOOL isGraphZooming;

-(void) clearDataCursorValuesCache;
-(void) performZoomX:(CGFloat)zoomFactorX zoomY:(CGFloat)zoomFactorY;
@end


@implementation CHGraphView

@synthesize graphContext;
@dynamic xString;
@dynamic yString;
@synthesize delegate;
@dynamic curvesData;
@synthesize currentAction;
@synthesize isWindowResizing;
@dynamic isGraphDragging;
@dynamic isGraphZoomingIn;
@dynamic isGraphZoomingOut;
@dynamic isGraphZooming;

-(instancetype) initWithCoder:(NSCoder*)aCoder
{
  if (!((self = [super initWithCoder:aCoder])))
    return nil;
  self->xString = [[NSMutableString alloc] init];
  self->yString = [[NSMutableString alloc] init];
  self->curvesData = [[NSMutableArray alloc] init];
  self->trackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect(self.bounds)
    options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|
            NSTrackingActiveAlways|NSTrackingEnabledDuringMouseDrag
      owner:self userInfo:nil];
  [self addTrackingArea:self->trackingArea];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self];

  self->graphGmpPool = [[CHGmpPool alloc] initWithCapacity:1024];
  self->graphContext = [[CHGraphContext alloc] initWithAxisPrec:mpfr_get_default_prec() gmpPool:self->graphGmpPool];
  self->graphContext.chalkContext.concurrentEvaluations = YES;
  self->graphContext.chalkContext.presentationConfiguration.softFloatDisplayBits =
    MAX(MPFR_PREC_MIN, self->graphContext.chalkContext.computationConfiguration.softFloatSignificandBits/2);

  self->graphDataPool = [[CHGraphDataPool alloc] initWithCapacity:1024 gmpPool:self->graphGmpPool];
  
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfr_init2(self->halfOne, mpfr_get_default_prec());
  mpfr_set_d(self->halfOne, .5, MPFR_RNDN);
  
  mpzDepool(self->cachedPixelXZ, self->graphGmpPool);
  mpz_set_ui(self->cachedPixelXZ, 0);
  mpzDepool(self->cachedPixelYZ, self->graphGmpPool);
  mpz_set_ui(self->cachedPixelYZ, 0);
  mpzDepool(self->cachedBoundsWidthPixelZ, self->graphGmpPool);
  mpz_set_ui(self->cachedBoundsWidthPixelZ, 0);
  mpzDepool(self->cachedBoundsHeightPixelZ, self->graphGmpPool);
  mpz_set_ui(self->cachedBoundsHeightPixelZ, 0);
  mpfiDepool(self->draggingStartXRange, self->graphContext.axisPrec, self->graphGmpPool);
  mpfi_set_d(self->draggingStartXRange, 0);
  mpfiDepool(self->draggingStartYRange, self->graphContext.axisPrec, self->graphGmpPool);
  mpfi_set_d(self->draggingStartYRange, 0);
  chalkGmpFlagsRestore(oldFlags);
  
  self.acceptsTouchEvents = YES;
  [self invalidateData:nil];
  return self;
}
//end initWithCoder:

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeTrackingArea:self->trackingArea];
  [self->trackingArea release];
  [self->xString release];
  [self->yString release];
  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* graphCurveCachedData = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    [graphCurveCachedData removeObserver:self forKeyPath:@"isPreparing"];
  }];//end for each curve
  [self->curvesData release];
  mpzRepool(self->cachedPixelXZ, self->graphGmpPool);
  mpzRepool(self->cachedPixelYZ, self->graphGmpPool);
  mpzRepool(self->cachedBoundsWidthPixelZ, self->graphGmpPool);
  mpzRepool(self->cachedBoundsHeightPixelZ, self->graphGmpPool);
  mpfr_clear(self->halfOne);
  mpfiRepool(self->draggingStartXRange, self->graphGmpPool);
  mpfiRepool(self->draggingStartYRange, self->graphGmpPool);
  [self clearDataCursorValuesCache];

  [self->graphDataPool release];
  [self->graphContext release];
  [self->graphGmpPool release];
  [super dealloc];
}
//end dealloc

-(NSString*) xString
{
  NSString* result = [[self->xString copy] autorelease];
  return result;
}
//end xString

-(NSString*) yString
{
  NSString* result = [[self->yString copy] autorelease];
  return result;
}
//end yString

-(BOOL) isGraphDragging
{
  BOOL result = ((self.currentAction == CHGRAPH_ACTION_DRAG) || (([NSEvent modifierFlags] & NSCommandKeyMask) != 0));
  return result;
}
//end isGraphDragging

-(BOOL) isGraphZoomingIn
{
  BOOL result = NO;
  BOOL isAlt = (([NSEvent modifierFlags] & NSAlternateKeyMask) != 0);
  if (!self.isGraphDragging)
    result = ((self.currentAction == CHGRAPH_ACTION_ZOOM_IN) && !isAlt) ||
             ((self.currentAction == CHGRAPH_ACTION_ZOOM_OUT) && isAlt) ||
             ((([NSEvent modifierFlags] & NSControlKeyMask) != 0) &&
               (((self.currentAction == CHGRAPH_ACTION_ZOOM_IN) && !isAlt) ||
                ((self.currentAction == CHGRAPH_ACTION_ZOOM_OUT) && isAlt) ||
                ((self.currentAction != CHGRAPH_ACTION_ZOOM_OUT) && !isAlt)));
  return result;
}
//end isGraphZoomingIn

-(BOOL) isGraphZoomingOut
{
  BOOL result = NO;
  BOOL isAlt = (([NSEvent modifierFlags] & NSAlternateKeyMask) != 0);
  if (!self.isGraphDragging)
    result = ((self.currentAction == CHGRAPH_ACTION_ZOOM_OUT) && !isAlt) ||
             ((self.currentAction == CHGRAPH_ACTION_ZOOM_IN) && isAlt) ||
             ((([NSEvent modifierFlags] & NSControlKeyMask) != 0) &&
               (((self.currentAction == CHGRAPH_ACTION_ZOOM_OUT) && !isAlt) ||
                ((self.currentAction == CHGRAPH_ACTION_ZOOM_IN) && isAlt) ||
                ((self.currentAction != CHGRAPH_ACTION_ZOOM_IN) && isAlt)));
  return result;
}
//end isGraphZoomingOut

-(BOOL) isGraphZooming
{
  BOOL result = self.isGraphZoomingIn || self.isGraphZoomingOut;
  return result;
}
//end isGraphZooming

-(void) addCurve:(CHGraphCurve*)curve
{
  __block CHGraphCurveCachedData* found = nil;
  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* graphCurveCachedData = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    if (graphCurveCachedData.curve == curve)
      found = graphCurveCachedData;
    if (found)
      *stop = YES;
  }];//end for each curve
  CHGraphCurveCachedData* graphCurveCachedData = !curve || (found != nil) ? nil :
    [[[CHGraphCurveCachedData alloc] initWithCurve:curve graphContext:self->graphContext graphGmpPool:self->graphGmpPool graphDataPool:self->graphDataPool] autorelease];
  if (graphCurveCachedData)
  {
    [self->curvesData addObject:graphCurveCachedData];
    [graphCurveCachedData addObserver:self forKeyPath:@"isPreparing" options:0 context:nil];
  }//end if (curve && graphCurveCachedData)
  [self setNeedsDisplay:YES];
}
//end addCurve:

-(void) removeCurve:(CHGraphCurve*)curve
{
  __block CHGraphCurveCachedData* found = nil;
  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* graphCurveCachedData = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    if (graphCurveCachedData.curve == curve)
      found = graphCurveCachedData;
    if (found)
      *stop = YES;
  }];//end for each curve
  if (found)
  {
    [found removeObserver:self forKeyPath:@"isPreparing"];
    [self->curvesData removeObject:found];
    [self setNeedsDisplay:YES];
  }//end if (found)
}
//end removeCurve:

-(void) setCurrentAction:(chgraph_action_t)value
{
  if (value != self->currentAction)
  {
    self->currentAction = value;
    [self setNeedsDisplay:YES];
  }//end if (value != self->currentAction)
}
//end setCurrentAction:

-(void) convertPixelRange:(NSRange)pixelRange toGraphValue:(chalk_gmp_value_t*)value
              pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                   context:(CHChalkContext*)context
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfi_srcptr scaleComputeRange = scale.computeRange;
  if (scaleComputeRange)
  {
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    chalkGmpValueMakeRealApprox(value, prec, self->graphGmpPool);
    mpfi_t tmpfi;
    mpfiDepool(tmpfi, prec, self->graphGmpPool);
    mpfr_set_nsui(&tmpfi->left, pixelRange.location, MPFR_RNDD);
    mpfr_set_nsui(&tmpfi->right, pixelRange.location+pixelRange.length, MPFR_RNDU);
    mpfr_t tmpfr;
    mpfrDepool(tmpfr, prec, self->graphGmpPool);
    mpfr_div_z(tmpfr, &tmpfi->left, pixelsCount, MPFR_RNDD);
    mpfr_mul(&tmpfi->left, tmpfr, scale.computeDiameter, MPFR_RNDD);
    mpfr_add(&value->realApprox->interval.left, &tmpfi->left, &scaleComputeRange->left, MPFR_RNDD);
    mpfr_div_z(tmpfr, &tmpfi->right, pixelsCount, MPFR_RNDU);
    mpfr_mul(&tmpfi->right, tmpfr, scale.computeDiameter, MPFR_RNDU);
    mpfr_add(&value->realApprox->interval.right, &tmpfi->right, &scaleComputeRange->left, MPFR_RNDU);
    [scale convertMpfiComputeValue:&value->realApprox->interval toVisualValue:&value->realApprox->interval];
    mpfir_estimation_update(value->realApprox);
    mpfrRepool(tmpfr, self->graphGmpPool);
    mpfiRepool(tmpfi, self->graphGmpPool);
  }//end if (scaleComputeRange)
  chalkGmpFlagsRestore(oldFlags);
}
//end convertPixelRange:toGraphValue:pixelsCount:scale:context:

-(NSRange) convertGraphValueToPixelRange:(const chalk_gmp_value_t*)value
                             pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                                 context:(CHChalkContext*)context
{
  NSRange result = NSRangeNotFound;
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfi_srcptr scaleComputeRange = scale.computeRange;
  if (scaleComputeRange)
  {
    mpfi_t tmp1;
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    mpfiDepool(tmp1, prec, self->graphGmpPool);
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      mpfi_set_z(tmp1, value->integer);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      mpfi_set_q(tmp1, value->fraction);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      mpfi_set_fr(tmp1, value->realExact);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      mpfi_set(tmp1, &value->realApprox->interval);
    mpfi_t tmp2;
    mpfiDepool(tmp2, prec, self->graphGmpPool);
    [scale convertMpfiVisualValue:tmp1 toComputeValue:tmp2];
    mpfi_intersect(tmp1, tmp2, scaleComputeRange);
    if (!mpfi_is_empty(tmp1))
    {
      mpfi_sub_fr(tmp2, tmp1, &scaleComputeRange->left);
      mpfi_div_fr(tmp1, tmp2, scale.computeDiameter);
      mpfi_mul_z(tmp2, tmp1, pixelsCount);
      mpfi_t clip;
      mpfiDepool(clip, self->graphContext.axisPrec, self->graphGmpPool);
      mpfr_set_ui(&clip->left, 0, MPFR_RNDD);
      mpfr_set_z(&clip->right, pixelsCount, MPFR_RNDU);
      mpfi_intersect(tmp1, tmp2, clip);
      mpfiRepool(clip, self->graphGmpPool);
      if (!mpfi_is_empty(tmp1))
      {
        mpz_t tmpZ;
        mpzDepool(tmpZ, self->graphGmpPool);
        mpfr_get_z(tmpZ, &tmp1->left, MPFR_RNDD);
        result.location = !mpz_fits_nsui_p(tmpZ) ? NSNotFound : mpz_get_nsui(tmpZ);
        if (result.location != NSNotFound)
        {
          mpfr_get_z(tmpZ, &tmp1->right, MPFR_RNDU);
          result.length = !mpz_fits_nsui_p(tmpZ) ? 0 : (mpz_get_nsui(tmpZ)-result.location+1);
        }//end if (result.location != NSNotFound)
        mpzRepool(tmpZ, self->graphGmpPool);
      }//end if (!mpfi_is_empty(tmp1))
      mpfiRepool(tmp2, self->graphGmpPool);
    }//end if (!mpfi_is_empty(tmp1))
    mpfiRepool(tmp1, self->graphGmpPool);
  }//end if (scaleComputeRange)
  chalkGmpFlagsRestore(oldFlags);
  return result;
}
//end convertGraphValueToPixelRange:pixelsCount:scaleType:scaleRange:context:

-(chalk_graph_pixel_t) convertGraphValueToPixel:(const chalk_gmp_value_t*)value
                                    pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                                        context:(CHChalkContext*)context
{
  chalk_graph_pixel_t result = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfi_srcptr scaleComputeRange = scale.computeRange;
  if (scaleComputeRange)
  {
    mpfr_t tmp1;
    mpfr_prec_t prec = context.computationConfiguration.softFloatSignificandBits;
    mpfrDepool(tmp1, prec, self->graphGmpPool);
    if (value->type == CHALK_VALUE_TYPE_INTEGER)
      mpfr_set_z(tmp1, value->integer, MPFR_RNDN);
    else if (value->type == CHALK_VALUE_TYPE_FRACTION)
      mpfr_set_q(tmp1, value->fraction, MPFR_RNDN);
    else if (value->type == CHALK_VALUE_TYPE_REAL_EXACT)
      mpfr_set(tmp1, value->realExact, MPFR_RNDN);
    else if (value->type == CHALK_VALUE_TYPE_REAL_APPROX)
      mpfir_estimation_get_fr(tmp1, value->realApprox);
    [scale convertMpfrVisualValue:tmp1 toComputeValue:tmp1];
    if (chalkGmpValueIsNan(value))
      result = {NSNotFound, CHGRAPH_PIXEL_FLAG_NAN};
    else if (mpfr_cmp(&scaleComputeRange->left,  tmp1) > 0)
      result = {NSNotFound, CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE};
    else if (mpfr_cmp(&scaleComputeRange->right, tmp1) < 0)
      result = {NSNotFound, CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE};
    else//in range
    {
      mpfr_t tmp2;
      mpfrDepool(tmp2, prec, self->graphGmpPool);
      mpfr_max(tmp1, tmp1, &scaleComputeRange->left, MPFR_RNDN);
      mpfr_min(tmp1, tmp1, &scaleComputeRange->right, MPFR_RNDN);
      mpfr_sub(tmp2, tmp1, &scaleComputeRange->left, MPFR_RNDN);
      mpfr_div(tmp1, tmp2, scale.computeDiameter, MPFR_RNDN);
      mpfr_mul_z(tmp2, tmp1, pixelsCount, MPFR_RNDN);
      mpfi_t clip;
      mpfiDepool(clip, self->graphContext.axisPrec, self->graphGmpPool);
      mpfr_set_ui(&clip->left, 0, MPFR_RNDD);
      mpfr_set_z(&clip->right, pixelsCount, MPFR_RNDU);
      mpfr_max(tmp1, tmp2, &clip->left, MPFR_RNDN);
      mpfr_min(tmp2, tmp1, &clip->right, MPFR_RNDN);
      mpfiRepool(clip, self->graphGmpPool);
      if (!mpfr_number_p(tmp2))
        result = {NSNotFound, CHGRAPH_PIXEL_FLAG_NAN};
      else//if (mpfr_number_p(tmp2))
      {
        mpz_t tmpZ;
        mpzDepool(tmpZ, self->graphGmpPool);
        mpfr_get_z(tmpZ, tmp2, MPFR_RNDN);
        result.px = !mpz_fits_nsui_p(tmpZ) ? NSNotFound : mpz_get_nsui(tmpZ);
        mpzRepool(tmpZ, self->graphGmpPool);
      }//end if (mpfr_number_p(tmp2->left))
      mpfrRepool(tmp2, self->graphGmpPool);
    }//end if (!resultOutsideRange)
    mpfrRepool(tmp1, self->graphGmpPool);
  }//end if in range
  chalkGmpFlagsRestore(oldFlags);
  return result;
}
//end convertGraphValueToPixel:pixelsCount:scaleType:scaleRange:context:

-(CHChalkValue*) identifierManager:(CHChalkIdentifierManager *)identifierManager valueForIdentifier:(CHChalkIdentifier *)identifier
{
  CHChalkValue* result = nil;
  return result;
}
//end identifierManager:valueForIdentifier:

-(void) invalidateData:(NSNotification*)notification
{
  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* cache = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    [cache invalidate];
  }];//end for each curve
  NSRect bounds = self.bounds;
  NSRect boundsBackingRect = [self convertRectToBacking:bounds];
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpz_set_nsui(self->cachedPixelXZ, (NSUInteger)round(boundsBackingRect.origin.x));
  mpz_set_nsui(self->cachedPixelYZ, (NSUInteger)round(boundsBackingRect.origin.y));
  mpz_set_nsui(self->cachedBoundsWidthPixelZ, (NSUInteger)round(boundsBackingRect.size.width));
  mpz_set_nsui(self->cachedBoundsHeightPixelZ, (NSUInteger)round(boundsBackingRect.size.height));
  chalkGmpFlagsRestore(oldFlags);
  [self setNeedsDisplay:YES];
}
//end invalidateData:

-(void) clearDataCursorValuesCache
{
  chalkGmpValueClear(&self->dataCursorCachedX, YES, self->graphGmpPool);
  for(size_t i = 0 ; i<self->dataCursorCachedYsCount ; ++i)
    chalkGmpValueClear(&self->dataCursorCachedYs[i], YES, self->graphGmpPool);
  free(self->dataCursorCachedYs);
  self->dataCursorCachedYs = 0;
  self->dataCursorCachedYsCount = 0;
}
//end clearDataCursorValuesCache

-(void) updateDataCursorValues
{
  [self clearDataCursorValuesCache];
  
  CHChalkContext* chalkContext = self->graphContext.chalkContext;
  NSPoint screenLocation = [NSEvent mouseLocation];
  NSPoint windowLocation = [[self window] convertRectFromScreen:NSMakeRect(screenLocation.x, screenLocation.y, 0, 0)].origin;
  NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
  BOOL isInside = NSPointInRect(viewLocation, self.bounds);
  __block BOOL hasVisibleCurve = NO;
  __block std::vector<chalk_gmp_value_t*> tmpValues;
  if (isInside)
  {
    NSPoint backingLocation = [self convertPointToBacking:viewLocation];
    NSUInteger x_px = (NSUInteger)round(backingLocation.x);
    NSUInteger y_px = (NSUInteger)round(backingLocation.y);
    chalkGmpValueMakeRealApprox(&self->dataCursorCachedX, self->graphContext.axisPrec, self->graphGmpPool);
    if (!self->curvesData.count)
    {
      [self convertPixelRange:NSMakeRange(x_px, 1) toGraphValue:&self->dataCursorCachedX pixelsCount:self->cachedBoundsWidthPixelZ scale:self->graphContext.axisHorizontal1.scale context:self->graphContext.chalkContext];
      self->dataCursorCachedYs = (chalk_gmp_value_t*)reallocf(self->dataCursorCachedYs, sizeof(chalk_gmp_value_t)*(self->dataCursorCachedYsCount+1));
      self->dataCursorCachedYsCount = self->dataCursorCachedYs ? (self->dataCursorCachedYsCount+1) : 0;
      if (self->dataCursorCachedYsCount)
      {
        chalk_gmp_value_t* dataCursorCachedY = &self->dataCursorCachedYs[self->dataCursorCachedYsCount-1];
        memset(dataCursorCachedY, 0, sizeof(chalk_gmp_value_t));
        [self convertPixelRange:NSMakeRange(y_px, 1) toGraphValue:dataCursorCachedY pixelsCount:self->cachedBoundsHeightPixelZ scale:self->graphContext.axisVertical1.scale context:self->graphContext.chalkContext];
      }//end if (self->dataCursorCachedYsCount)
    }//end if (!self->curvesData.count)
    else//if (self->curvesData.count)
    {
      [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHGraphCurveCachedData* cache = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
        CHGraphCurve* curve = cache.curve;
        if (!curve.visible){
        }
        else if ((curve.graphMode == CHGRAPH_MODE_Y_FROM_X) && (x_px<cache.cachedDataSize))
        {
          hasVisibleCurve |= YES;
          chalkGmpValueSet(&self->dataCursorCachedX, &cache.cachedData[x_px]->x, self->graphGmpPool);
          self->dataCursorCachedYs = (chalk_gmp_value_t*)reallocf(self->dataCursorCachedYs, sizeof(chalk_gmp_value_t)*(self->dataCursorCachedYsCount+1));
          self->dataCursorCachedYsCount = self->dataCursorCachedYs ? (self->dataCursorCachedYsCount+1) : 0;
          if (self->dataCursorCachedYsCount)
          {
            chalk_gmp_value_t* dataCursorCachedY = &self->dataCursorCachedYs[self->dataCursorCachedYsCount-1];
            memset(dataCursorCachedY, 0, sizeof(chalk_gmp_value_t));
            chalkGmpValueSet(&self->dataCursorCachedYs[self->dataCursorCachedYsCount-1], &cache.cachedData[x_px]->y, self->graphGmpPool);
          }//end if (self->dataCursorCachedYsCount)
        }//end if ((curve.graphMode == CHGRAPH_MODE_Y_FROM_X) && (x_px<cache.cachedDataSize))
        else if (curve.graphMode == CHGRAPH_MODE_XY_PREDICATE)
        {
          hasVisibleCurve |= YES;
          self->dataCursorCachedYs = (chalk_gmp_value_t*)reallocf(self->dataCursorCachedYs, sizeof(chalk_gmp_value_t)*(self->dataCursorCachedYsCount+1));
          self->dataCursorCachedYsCount = self->dataCursorCachedYs ? (self->dataCursorCachedYsCount+1) : 0;
          if (self->dataCursorCachedYsCount)
          {
            chalk_gmp_value_t* dataCursorCachedY = &self->dataCursorCachedYs[self->dataCursorCachedYsCount-1];
            memset(dataCursorCachedY, 0, sizeof(chalk_gmp_value_t));
            [self convertPixelRange:NSMakeRange(x_px, 1) toGraphValue:&self->dataCursorCachedX
                  pixelsCount:self->cachedBoundsWidthPixelZ scale:self->graphContext.axisHorizontal1.scale
                       context:chalkContext];
            [self convertPixelRange:NSMakeRange(y_px, 1) toGraphValue:dataCursorCachedY
                  pixelsCount:self->cachedBoundsHeightPixelZ scale:self->graphContext.axisVertical1.scale
                       context:chalkContext];
          }//end if (self->dataCursorCachedYsCount)
        }//end if (curve.graphMode == CHGRAPH_MODE_XY_PREDICATE)
      }];//end for each curve
    }//end if (self->curvesData.count)
  }//end if (isInside)
  if (!hasVisibleCurve)
    [self->xString setString:@""];
  else if (self->dataCursorCachedX.type == CHALK_VALUE_TYPE_UNDEFINED)
    [self->xString setString:@""];
  else//if (x)
  {
    CHStreamWrapper* streamWrapper = [[CHStreamWrapper alloc] init];
    streamWrapper.stringStream = [NSMutableString string];
    [CHChalkValueNumberGmp writeMpfirToStream:streamWrapper context:chalkContext value:self->dataCursorCachedX.realApprox token:nil presentationConfiguration:nil];
    [self->xString setString:streamWrapper.stringStream];
    [streamWrapper release];
  }//if (x)
  if (!self->dataCursorCachedYsCount)
    [self->yString setString:@""];
  else//if (!ys.empty())
  {
    std::vector<const chalk_gmp_value_t*> ysSorted;
    for(auto it = self->dataCursorCachedYs ; it != self->dataCursorCachedYs+self->dataCursorCachedYsCount ; ++it)
      ysSorted.push_back(it);
    std::sort(ysSorted.begin(), ysSorted.end(),
      [self](const chalk_gmp_value_t* op1, const chalk_gmp_value_t* op2){
      return (chalkGmpValueCmp(op1, op2, self->graphGmpPool)<0);
    });
    CHStreamWrapper* streamWrapper = [[CHStreamWrapper alloc] init];
    streamWrapper.stringStream = [NSMutableString string];
    for(const chalk_gmp_value_t* y : ysSorted)
    {
      if (streamWrapper.stringStream.length)
        [streamWrapper writeString:@"\t"];
      if (y->type == CHALK_VALUE_TYPE_INTEGER)
        [CHChalkValueNumberGmp writeMpzToStream:streamWrapper context:chalkContext value:y->integer token:nil presentationConfiguration:nil];
      else if (y->type == CHALK_VALUE_TYPE_FRACTION)
        [CHChalkValueNumberGmp writeMpqToStream:streamWrapper context:chalkContext value:y->fraction token:nil presentationConfiguration:nil];
      else if (y->type == CHALK_VALUE_TYPE_REAL_EXACT)
        [CHChalkValueNumberGmp writeMpfrToStream:streamWrapper context:chalkContext value:y->realExact token:nil presentationConfiguration:nil];
      else if (y->type == CHALK_VALUE_TYPE_REAL_APPROX)
        [CHChalkValueNumberGmp writeMpfirToStream:streamWrapper context:chalkContext value:y->realApprox token:nil presentationConfiguration:nil];
      [self->yString setString:streamWrapper.stringStream];
    }//end for eaxy y
    [streamWrapper release];
  }//if (!ys.empty())
  if ([(id)self->delegate respondsToSelector:@selector(graphView:didUpdateCursorValue:)])
    [self->delegate graphView:self didUpdateCursorValue:nil];
  [self setNeedsDisplay:YES];
}
//end updateDataCursorValues

-(void) drawRect:(NSRect)dirtyRect
{
  NSRect bounds = self.bounds;
  NSRect boundsBackingRect = [self convertRectToBacking:bounds];

  NSPoint mouseScreenLocation = [NSEvent mouseLocation];
  NSPoint mouseWindowLocation =
    [[self window] convertRectFromScreen:NSMakeRect(mouseScreenLocation.x, mouseScreenLocation.y, 0, 0)].origin;
  NSPoint mouseViewLocation = [self convertPoint:mouseWindowLocation fromView:nil];

  CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(cgContext);
  CGContextScaleCTM(cgContext,
    !boundsBackingRect.size.width ? 1 : bounds.size.width/boundsBackingRect.size.width,
    !boundsBackingRect.size.height ? 1 : bounds.size.height/boundsBackingRect.size.height);
  
  [self renderInContext:cgContext bounds:boundsBackingRect drawAxes:YES drawMajorGrid:YES drawMinorGrid:YES drawMajorValues:YES
    drawDataCursors:((self->currentAction == CHGRAPH_ACTION_UNDEFINED) ||
                     (self->currentAction == CHGRAPH_ACTION_CURSOR) ||
                     (self->currentAction == CHGRAPH_ACTION_DRAG) ||
                     (self->currentAction == CHGRAPH_ACTION_ZOOM_IN) ||
                     (self->currentAction == CHGRAPH_ACTION_ZOOM_OUT))
   mouseLocation:NSPointToCGPoint(mouseViewLocation)];
  CGContextRestoreGState(cgContext);
  
  if (self->isDragging)
  {
    if (self.isGraphZooming)
    {
      CGContextSaveGState(cgContext);
      CGContextSetLineDash(cgContext, 0, (const CGFloat[]){3, 3}, 2);
      CGContextSetRGBStrokeColor(cgContext, 0, 0, 0, 1);
      CGContextStrokeRect(cgContext,
        CGRectMake(self->draggingStartLocation.x, self->draggingStartLocation.y,
          mouseViewLocation.x-self->draggingStartLocation.x,
          mouseViewLocation.y-self->draggingStartLocation.y));
      CGContextRestoreGState(cgContext);
    }//end if (isGraphZooming)
  }//end if (self->isDragging)
}
//end drawRect:

-(void) renderInContext:(CGContextRef)cgContext bounds:(CGRect)bounds drawAxes:(BOOL)drawAxes drawMajorGrid:(BOOL)drawMajorGrid drawMinorGrid:(BOOL)drawMinorGrid drawMajorValues:(BOOL)drawMajorValues drawDataCursors:(BOOL)drawDataCursors mouseLocation:(CGPoint)mouseLocation
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);

  NSFont* graphFont = nil;
  if ([(id)self->delegate respondsToSelector:@selector(graphViewFont:)])
    graphFont = [self->delegate graphViewFont:self];
  graphFont = !graphFont ? [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] : graphFont;

  NSColor* backgroundColor = nil;
  if ([(id)self->delegate respondsToSelector:@selector(graphViewBackgroundColor:)])
    backgroundColor = [self->delegate graphViewBackgroundColor:self];
  backgroundColor = !backgroundColor ? [NSColor clearColor] : backgroundColor;
  if (backgroundColor)
  {
    backgroundColor = [backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat backgroundColorRgba[4] = {0, 0, 0, 0};
    [backgroundColor getRed:&backgroundColorRgba[0] green:&backgroundColorRgba[1] blue:&backgroundColorRgba[2] alpha:&backgroundColorRgba[3]];
    CGContextSetRGBFillColor(cgContext, backgroundColorRgba[0], backgroundColorRgba[1], backgroundColorRgba[2], backgroundColorRgba[3]);
    CGContextFillRect(cgContext, bounds);
  }//end if (backgroundColor)

  CGContextSetRGBStrokeColor(cgContext, 0, 0, 0, 1);
  CGFloat axisColorDefaultRgba[4] = {0, 0, 0, 1};
  CGFloat majorGridColorDefaultRgba[4] = {0, 0, 0, 1};
  CGFloat minorGridColorDefaultRgba[4] = {0, 0, 0, 1};

  NSColor* axisColorX = nil;
  if ([(id)self->delegate respondsToSelector:@selector(graphView:axisColorForOrientation:)])
    axisColorX = [self->delegate graphView:self axisColorForOrientation:CHGRAPH_AXIS_ORIENTATION_HORIZONTAL];
  axisColorX = [axisColorX colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  CGFloat axisColorXRgba[4] = {0, 0, 0, 1};
  [axisColorX getRed:&axisColorXRgba[0] green:&axisColorXRgba[1] blue:&axisColorXRgba[2] alpha:&axisColorXRgba[3]];

  NSColor* axisColorY = nil;
  if ([(id)self->delegate respondsToSelector:@selector(graphView:axisColorForOrientation:)])
    axisColorY = [self->delegate graphView:self axisColorForOrientation:CHGRAPH_AXIS_ORIENTATION_VERTICAL];
  axisColorY = [axisColorY colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  CGFloat axisColorYRgba[4] = {0, 0, 0, 1};
  [axisColorY getRed:&axisColorYRgba[0] green:&axisColorYRgba[1] blue:&axisColorYRgba[2] alpha:&axisColorYRgba[3]];

  chalk_gmp_value_t tmp1 = {(chalk_value_gmp_type_t)0};
  chalk_gmp_value_t tmp2 = {(chalk_value_gmp_type_t)0};
  chalk_gmp_value_t tmp3 = {(chalk_value_gmp_type_t)0};
  chalk_gmp_value_t tmp4 = {(chalk_value_gmp_type_t)0};
  chalk_gmp_value_t tmp5 = {(chalk_value_gmp_type_t)0};
  chalk_gmp_value_t tmp6 = {(chalk_value_gmp_type_t)0};
  chalkGmpValueMakeRealExact(&tmp1, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&tmp2, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&tmp3, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&tmp4, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&tmp5, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&tmp6, self->graphContext.axisPrec, self->graphGmpPool);
  CHGraphAxis* xAxis = self->graphContext.axisHorizontal1;
  CHGraphAxis* yAxis = self->graphContext.axisVertical1;
  CHGraphScale* xScale = xAxis.scale;
  CHGraphScale* yScale = yAxis.scale;
  chalk_graph_pixel_t xAxis_px = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
  chalk_graph_pixel_t yAxis_px = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
  mpfr_set_zero(tmp1.realExact, 0);
  if (chalkGmpValueMakeRealExact(&tmp1, self->graphContext.axisPrec, self->graphGmpPool))
    [yScale convertMpfrComputeValue:tmp1.realExact toVisualValue:tmp2.realExact];
  xAxis_px =
    [self convertGraphValueToPixel:&tmp2 pixelsCount:self->cachedBoundsHeightPixelZ scale:yScale
                           context:self->graphContext.chalkContext];
    [xScale convertMpfrComputeValue:tmp1.realExact toVisualValue:tmp2.realExact];
  yAxis_px =
    [self convertGraphValueToPixel:&tmp2 pixelsCount:self->cachedBoundsWidthPixelZ scale:xScale
                           context:self->graphContext.chalkContext];

  std::vector<std::tuple<chgraph_axis_orientation_flags_t, NSUInteger, BOOL> > ticksToDraw;
  std::vector<std::tuple<NSAttributedString*, CTLineRef, chgraph_axis_orientation_flags_t, CGRect, BOOL> > majorValuesToDraw;

  if (drawAxes || drawMajorGrid || drawMinorGrid)
  {
    mpfi_srcptr xComputeRange = xScale.computeRange;
    mpfi_srcptr yComputeRange = yScale.computeRange;
    mpfi_srcptr xVisualRange = xScale.visualRange;
    mpfi_srcptr yVisualRange = yScale.visualRange;
    BOOL ok = ((tmp1.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               (tmp2.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               (tmp3.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               (tmp4.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               (tmp5.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               (tmp6.type == CHALK_VALUE_TYPE_REAL_EXACT) &&
               xComputeRange && yComputeRange && xVisualRange && yVisualRange);
    if (ok)
    {
      if (drawMajorGrid || drawMinorGrid)
      {
        NSMutableAttributedString* majorValueAttributedString = !drawMajorValues ? nil :
          [[[NSMutableAttributedString alloc] init] autorelease];
        CHStreamWrapper* majorValuesStream = !majorValueAttributedString ? nil :
          [[[CHStreamWrapper alloc] init] autorelease];
        majorValuesStream.attributedStringStream = majorValueAttributedString;
        std::vector<std::tuple<CHGraphAxis*, chgraph_axis_orientation_flags_t> > steps =
          {{xAxis, CHGRAPH_AXIS_ORIENTATION_HORIZONTAL}, {yAxis, CHGRAPH_AXIS_ORIENTATION_VERTICAL}};
        for(auto itStep = steps.begin() ; itStep != steps.end() ; ++itStep)
        {
          CHGraphAxis* axis = std::get<0>(*itStep);
          chgraph_axis_orientation_flags_t orientation = std::get<1>(*itStep);
          CHGraphScale* scale = axis.scale;
          mpfi_srcptr computeRange = scale.computeRange;
          mpfr_srcptr majorStep = axis.majorStep;
          NSUInteger minorDivisions = axis.minorDivisions;
          mpz_srcptr pixelSize = (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) ? self->cachedBoundsWidthPixelZ : self->cachedBoundsHeightPixelZ;
          mpfr_div(tmp1.realExact, &computeRange->left, majorStep, MPFR_RNDN);
          mpfr_floor(tmp2.realExact, tmp1.realExact);
          mpfr_mul(tmp1.realExact, tmp2.realExact, majorStep, MPFR_RNDN);
          //tmp1 is left, tmp2 is factor, tmp3 will be next

          BOOL canDrawMajorGrid = drawMajorGrid && mpfr_regular_p(majorStep) && (mpfr_sgn(majorStep) > 0);
          BOOL canDrawMinorGrid = drawMinorGrid && canDrawMajorGrid && (minorDivisions > 1) &&
            (minorDivisions <= std::numeric_limits<unsigned long>::max());

          CGRect lastHorizontalMajorValueRect = CGRectZero;
          CGRect lastVerticalMajorValueRect = CGRectZero;
          chalk_graph_pixel_t lastPosPixelMajorGrid = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
          NSUInteger majorGridIndex = 0;
          BOOL stopMajor = !canDrawMajorGrid;
          while(!stopMajor)
          {
            mpfr_add_ui(tmp2.realExact, tmp2.realExact, 1, MPFR_RNDN);
            mpfr_mul(tmp3.realExact, tmp2.realExact, majorStep, MPFR_RNDN);
            
            if (canDrawMinorGrid)
            {
              const CGFloat* color =
                (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) && axisColorX ? axisColorXRgba :
                (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)   && axisColorY ? axisColorYRgba :
                minorGridColorDefaultRgba;
              CGContextSetRGBFillColor(cgContext, color[0], color[1], color[2], color[3]*.1);

              [scale convertMpfrComputeValue:tmp1.realExact toVisualValue:tmp4.realExact];
              [scale convertMpfrComputeValue:tmp3.realExact toVisualValue:tmp6.realExact];
              mpfr_sub(tmp5.realExact, tmp6.realExact, tmp4.realExact, MPFR_RNDN);
              mpfr_div_ui(tmp6.realExact, tmp5.realExact, minorDivisions, MPFR_RNDN);
              chalk_graph_pixel_t lastPosPixel = {NSNotFound, CHGRAPH_PIXEL_FLAG_NONE};
              for(NSUInteger minorIndex = 1 ; minorIndex < minorDivisions ; ++minorIndex)
              {
                mpfr_mul_ui(tmp5.realExact, tmp6.realExact, minorIndex, MPFR_RNDN);
                mpfr_add(tmp5.realExact, tmp5.realExact, tmp4.realExact, MPFR_RNDN);
                chalk_graph_pixel_t posPixel =
                  [self convertGraphValueToPixel:&tmp5
                                          pixelsCount:pixelSize scale:scale
                                              context:self->graphContext.chalkContext];
                if ((posPixel.px != 0) && (posPixel.px != NSNotFound) && (posPixel.px != lastPosPixel.px))
                {
                  if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
                    CGContextFillRect(cgContext, CGRectMake(posPixel.px, 0, 1, bounds.size.height));
                  else if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
                    CGContextFillRect(cgContext, CGRectMake(0, posPixel.px, bounds.size.width, 1));
                  ticksToDraw.push_back({orientation, posPixel.px, NO});
                }//end if ((posPixel.px != 0) && (posPixel.px != NSNotFound) && (posPixel.px != lastPosPixel.px))
                lastPosPixel = posPixel;
              }//end if (!stopMinor)
            }//end if (canDrawMinorGrid)
            
            if (canDrawMajorGrid)
            {
              [scale convertMpfrComputeValue:tmp1.realExact toVisualValue:tmp4.realExact];
              chalk_graph_pixel_t posPixel =
                [self convertGraphValueToPixel:&tmp4 pixelsCount:pixelSize scale:scale
                                       context:self->graphContext.chalkContext];
              if (posPixel.px != NSNotFound)
              {
                const CGFloat* color =
                  (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) && axisColorX ? axisColorXRgba :
                  (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)   && axisColorY ? axisColorYRgba :
                  majorGridColorDefaultRgba;
                CGContextSetRGBFillColor(cgContext, color[0], color[1], color[2], color[3]*.25);

                if (posPixel.px == 0){
                }
                else if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
                  CGContextFillRect(cgContext, CGRectMake(posPixel.px, 0, 1, bounds.size.height));
                else if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
                  CGContextFillRect(cgContext, CGRectMake(0, posPixel.px, bounds.size.width, 1));
                
                if (drawMajorValues)
                {
                  [majorValueAttributedString deleteCharactersInRange:NSMakeRange(0, majorValueAttributedString.length)];
                  CHPresentationConfiguration* presentationConfiguration = [[CHPresentationConfiguration alloc] init];
                  presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_ATTRIBUTEDSTRING;
                  presentationConfiguration.printOptions = CHALK_VALUE_PRINT_OPTION_FORCE_EXACT;
                  [CHChalkValueNumberGmp writeMpfrToStream:majorValuesStream context:self->graphContext.chalkContext value:tmp4.realExact token:[CHChalkToken chalkTokenEmpty] presentationConfiguration:presentationConfiguration];
                  [presentationConfiguration release];
                  
                  [majorValueAttributedString addAttribute:NSFontAttributeName value:graphFont range:NSMakeRange(0, majorValueAttributedString.length)];
                  if ((orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) && axisColorX)
                    [majorValueAttributedString addAttribute:NSForegroundColorAttributeName value:axisColorX range:NSMakeRange(0, majorValueAttributedString.length)];
                  else if ((orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL) && axisColorY)
                    [majorValueAttributedString addAttribute:NSForegroundColorAttributeName value:axisColorY range:NSMakeRange(0, majorValueAttributedString.length)];

                  BOOL isZero = [majorValueAttributedString.string isEqualToString:@"0"];
                  CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)(majorValueAttributedString));
                  CGRect lineRect = CTLineGetImageBounds(line, cgContext);
                  if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
                    lineRect.origin.x = posPixel.px-lineRect.size.width/2;
                  else if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
                    lineRect.origin.y = posPixel.px-lineRect.size.height/2;
                  BOOL canDraw =
                   ((orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) &&
                    (CGRectIsEmpty(lastHorizontalMajorValueRect) || !CGRectIntersectsRect(lineRect, lastHorizontalMajorValueRect))) ||
                   ((orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL) &&
                    (CGRectIsEmpty(lastVerticalMajorValueRect) || !CGRectIntersectsRect(lineRect, lastVerticalMajorValueRect)));
                  if (canDraw)
                  {
                    if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
                      lastHorizontalMajorValueRect = lineRect;
                    else if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
                      lastVerticalMajorValueRect = lineRect;
                    majorValuesToDraw.push_back({[majorValueAttributedString copy], (CTLineRef)CFRetain(line), orientation, lineRect, isZero});
                    if (posPixel.px != 0)
                      ticksToDraw.push_back({orientation, posPixel.px, YES});
                  }//end if (canDraw)
                  if (line)
                    CFRelease(line);
                }//end if (drawMajorValues)
                stopMajor |= (posPixel.px == lastPosPixelMajorGrid.px);
                lastPosPixelMajorGrid = posPixel;
              }//end if (posPixel.px != NSNotFound)
              stopMajor |= (posPixel.px == NSNotFound) && (majorGridIndex > 1);
              ++majorGridIndex;
            }//end if (canDrawMajorGrid)
            stopMajor |= !canDrawMajorGrid;
            
            mpfr_swap(tmp1.realExact, tmp3.realExact);
            stopMajor |= (mpfr_cmp(tmp1.realExact, &computeRange->right) > 0);
          }//end while(!stopMajor)
        }//end for each step
      }//end if (drawMajorGrid || drawMinorGrid)
    }//end if (ok)
  }//end if (drawAxes || drawMajorGrid || drawMinorGrid)
  chalkGmpValueClear(&tmp1, YES, nil);
  chalkGmpValueClear(&tmp2, YES, nil);
  chalkGmpValueClear(&tmp3, YES, nil);
  chalkGmpValueClear(&tmp4, YES, nil);
  chalkGmpValueClear(&tmp5, YES, nil);
  chalkGmpValueClear(&tmp6, YES, nil);


  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* cache = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    CHGraphCurve* curve = cache.curve;
    if (curve.visible && cache.isDirty && !self.isWindowResizing && !self->isDragging)
    {
      [cache startFilling:self rect:bounds callBackEnd:^(BOOL) {
        dispatch_async(dispatch_get_main_queue(), ^{[self setNeedsDisplay:YES];});
        self->didUpdateCache = YES;
      }];
    }//end if (curve.visible && cache.isDirty && !self.isWindowResizing && !self->isDragging)

    chgraph_mode_t graphMode = curve.graphMode;
    BOOL cacheIsUsable = NO;
    @synchronized(cache)
    {
      cacheIsUsable = !cache.isDirty && !cache.isPreparing && !cache.isPreparingDirty;
    }//end @synchronized(cache)
    
    if (self->isDragging && self.isGraphDragging){
    }
    else if (!curve.visible){
    }
    else if (graphMode == CHGRAPH_MODE_Y_FROM_X)
    {
      @synchronized(cache)
      {
        if (cacheIsUsable)
        {
          size_t cachedDataSize = cache.cachedDataSize;
          chalk_graph_data_element_t** cachedData = cache.cachedData;
          if (cachedData && cachedDataSize)
          {
            NSUInteger elementPixelSize = MAX(1, curve.elementPixelSize);
            CGContextSetRGBFillColor(cgContext, .5, .5, .5, 1.);

            NSUInteger thickness = 0U;
            if ([(id)self->delegate respondsToSelector:@selector(graphView:curveThicknessForCurve:)])
              thickness = [self->delegate graphView:self curveThicknessForCurve:curve];

            NSColor* curveColor = nil;
            if ([(id)self->delegate respondsToSelector:@selector(graphView:curveColorForCurve:)])
              curveColor = [self->delegate graphView:self curveColorForCurve:curve];
            curveColor = [curveColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            CGFloat curveColorRgba[4] = {0};
            [curveColor getRed:&curveColorRgba[0] green:&curveColorRgba[1] blue:&curveColorRgba[2] alpha:&curveColorRgba[3]];

            NSColor* curveInteriorColor = nil;
            if ([(id)self->delegate respondsToSelector:@selector(graphView:curveInteriorColorForCurve:)])
              curveInteriorColor = [self->delegate graphView:self curveInteriorColorForCurve:curve];
            curveInteriorColor = [curveInteriorColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            CGFloat curveInteriorColorRgba[4] = {0};
            [curveInteriorColor getRed:&curveInteriorColorRgba[0] green:&curveInteriorColorRgba[1] blue:&curveInteriorColorRgba[2] alpha:&curveInteriorColorRgba[3]];
            
            BOOL uncertaintyVisible = YES;
            if ([(id)self->delegate respondsToSelector:@selector(graphView:curveUncertaintyVisibleForCurve:)])
              uncertaintyVisible = [self->delegate graphView:self curveUncertaintyVisibleForCurve:curve];

            BOOL uncertaintyNaNVisible = YES;
            if ([(id)self->delegate respondsToSelector:@selector(graphView:curveUncertaintyNaNVisibleForCurve:)])
              uncertaintyNaNVisible = [self->delegate graphView:self curveUncertaintyNaNVisibleForCurve:curve];
            
            if (!self.isWindowResizing)
            {
              if (uncertaintyVisible)
              {
                NSColor* uncertaintyColor = nil;
                if ([(id)self->delegate respondsToSelector:@selector(graphView:curveUncertaintyColorForCurve:)])
                  uncertaintyColor = [self->delegate graphView:self curveUncertaintyColorForCurve:curve];
                uncertaintyColor = [uncertaintyColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                CGFloat uncertaintyColorRgba[4] = {0};
                [uncertaintyColor getRed:&uncertaintyColorRgba[0] green:&uncertaintyColorRgba[1] blue:&uncertaintyColorRgba[2] alpha:&uncertaintyColorRgba[3]];

                NSColor* uncertaintyNaNColor = nil;
                if ([(id)self->delegate respondsToSelector:@selector(graphView:curveUncertaintyNaNColorForCurve:)])
                  uncertaintyNaNColor = [self->delegate graphView:self curveUncertaintyNaNColorForCurve:curve];
                uncertaintyColor = [uncertaintyNaNColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                CGFloat uncertaintyNaNColorRgba[4] = {0};
                [uncertaintyNaNColor getRed:&uncertaintyNaNColorRgba[0] green:&uncertaintyNaNColorRgba[1] blue:&uncertaintyNaNColorRgba[2] alpha:&uncertaintyNaNColorRgba[3]];

                CGContextSaveGState(cgContext);
                CGContextSetInterpolationQuality(cgContext, kCGInterpolationNone);
                CGContextSetShouldAntialias(cgContext, NO);
                CGContextSetAllowsAntialiasing(cgContext, NO);
                  for(size_t x = 0 ; x<(cachedDataSize+elementPixelSize-1)/elementPixelSize ; ++x)
                {
                  chalk_graph_data_element_t* element = cachedData[x];
                  NSRange x_px = element->x_px;
                  NSRange y_px = element->y_px;
                  BOOL isNanUncertainty = chalkGmpValueIsNan(&element->y);
                  if (!isNanUncertainty)
                  {
                    CGContextSetRGBFillColor(cgContext, uncertaintyColorRgba[0], uncertaintyColorRgba[1], uncertaintyColorRgba[2], uncertaintyColorRgba[3]);
                    CGContextFillRect(cgContext, CGRectMake(x_px.location, y_px.location, x_px.length, y_px.length));
                  }//end if (!isNanUncertainty)
                  else if (uncertaintyNaNVisible)
                  {
                    CGContextSetRGBFillColor(cgContext, uncertaintyNaNColorRgba[0], uncertaintyNaNColorRgba[1], uncertaintyNaNColorRgba[2], uncertaintyNaNColorRgba[3]);
                    CGContextFillRect(cgContext, CGRectMake(x_px.location, bounds.origin.x, x_px.length, bounds.size.height));
                  }//end if (!isNanUncertainty)
                }//end or each x
                CGContextRestoreGState(cgContext);
              }//end if (uncertaintyVisible)

              CGContextSaveGState(cgContext);
              CGContextSetShouldAntialias(cgContext, YES);
              CGContextSetAllowsAntialiasing(cgContext, YES);
              CGContextSetInterpolationQuality(cgContext, kCGInterpolationNone);

              CGMutablePathRef cgStrokePath = CGPathCreateMutable();
              CGMutablePathRef cgFillPath = CGPathCreateMutable();

              CGFloat overflowMargin = 1.*(thickness+1);
              NSRange x_px = cachedData[0]->x_px;
              chalk_graph_pixel_t yEstimation_px = cachedData[0]->yEstimation_px;
              CGFloat interiorReference =
                (xAxis_px.px != NSNotFound) ? xAxis_px.px :
                (xAxis_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE) ? CGRectGetMaxY(bounds)+overflowMargin :
                (xAxis_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE) ? CGRectGetMinY(bounds)-overflowMargin :
                xAxis_px.px;
              BOOL interruptStrokePath = YES;
              
              chalk_graph_pixel_t last_yEstimation_px = {NSNotFound, CHGRAPH_PIXEL_FLAG_NAN};
              std::vector<chalk_graph_data_element_t*> elements;
              std::stack<chalk_graph_data_element_t*> stack;
              for(size_t x = 0 ; x<(cachedDataSize+elementPixelSize-1)/elementPixelSize ; ++x)
              {
                stack.push(cachedData[x]);
                while(!stack.empty())
                {
                  chalk_graph_data_element_t* element = stack.top();
                  stack.pop();
                  if (!element){
                  }
                  else if (!element->left && !element->right)
                    elements.push_back(element);
                  else
                  {
                    if (element->right)
                      stack.push(element->right);
                    if (element->left)
                      stack.push(element->left);
                  }
                }//end while(!queue.empty())
              }//end for each element
              
              for(chalk_graph_data_element_t* element : elements)
              {
                x_px = element->x_px;
                yEstimation_px = element->yEstimation_px;

                BOOL previousWasNAN = ((last_yEstimation_px.px == NSNotFound) && (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_NAN)) ||
                (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE) ||
                (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE);

                BOOL isOutside = (yEstimation_px.px == NSNotFound);
                if (!isOutside)
                {
                  if (previousWasNAN || interruptStrokePath)
                  {
                    BOOL wasBelow = (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE) ||
                                    (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE);
                    BOOL wasAbove = (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE) ||
                                    (last_yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE);
                    if (wasBelow)
                    {
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMinY(bounds)-overflowMargin);
                      CGPathAddLineToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                    }//end if (wasBelow)
                    else if (wasAbove)
                    {
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMaxY(bounds)+overflowMargin);
                      CGPathAddLineToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                    }//end if (wasAbove)
                    else
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                  }//end if (previousWasNAN || interruptStrokePath)
                  else//if (!previousWasNAN && !interruptStrokePath)
                  {
                    if (CGPathIsEmpty(cgStrokePath))
                    {
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                      interruptStrokePath = NO;
                    }//end if (CGPathIsEmpty(cgStrokePath))
                    else//if(!CGPathIsEmpty(cgStrokePath))
                      CGPathAddLineToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                  }//end if (!previousWasNAN && !interruptStrokePath)
                  interruptStrokePath = NO;
                  if (CGPathIsEmpty(cgFillPath))
                    CGPathMoveToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                  CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., 1.*yEstimation_px.px);
                }//end if (!isOutside)
                else//if (isOutside)
                {
                  if (previousWasNAN)
                  {
                    interruptStrokePath = YES;
                    if (!CGPathIsEmpty(cgFillPath))
                    {
                      CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                      CGPathCloseSubpath(cgFillPath);
                    }//end if (!CGPathIsEmpty(cgFillPath))
                  }//end if (previousWasNAN)
                  else if ((yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_NAN) ||
                           (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE) ||
                           (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE))
                  {
                    interruptStrokePath = YES;
                    if (!CGPathIsEmpty(cgFillPath))
                    {
                      CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                      CGPathCloseSubpath(cgFillPath);
                    }//end if (!CGPathIsEmpty(cgFillPath))
                  }//end if (yEstimation_px.flag & CHGRAPH_PIXEL_FLAG_NAN, CHGRAPH_PIXEL_FLAG_INFINITY_NEGATIVE, CHGRAPH_PIXEL_FLAG_INFINITY_POSITIVE)
                  else if (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE)
                  {
                    if (CGPathIsEmpty(cgStrokePath) || interruptStrokePath)
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMinY(bounds)-overflowMargin);
                    else//if (!CGPathIsEmpty(cgStrokePath) && !interruptStrokePath)
                      CGPathAddLineToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMinY(bounds)-overflowMargin);
                    if (CGPathIsEmpty(cgFillPath))
                      CGPathMoveToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                    CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMinY(bounds)-overflowMargin);
                  }//end if (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_NEGATIVE)
                  else if (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE)
                  {
                    if (CGPathIsEmpty(cgStrokePath) || interruptStrokePath)
                      CGPathMoveToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMaxY(bounds)+overflowMargin);
                    else//if (!CGPathIsEmpty(cgStrokePath) && !interruptStrokePath)
                      CGPathAddLineToPoint(cgStrokePath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMaxY(bounds)+overflowMargin);
                    
                    if (CGPathIsEmpty(cgFillPath))
                      CGPathMoveToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                    CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., CGRectGetMaxY(bounds)+overflowMargin);
                  }//end if (yEstimation_px.flags & CHGRAPH_PIXEL_FLAG_OVERFLOW_POSITIVE)
                }//end if (isOutside)
                last_yEstimation_px = yEstimation_px;
              }//end for each x
              if (!CGPathIsEmpty(cgFillPath))
              {
                CGPathAddLineToPoint(cgFillPath, 0, 1.*x_px.location+x_px.length/2., interiorReference);
                CGPathCloseSubpath(cgFillPath);
              }//end if (!CGPathIsEmpty(cgFillPath))
              
              CGContextAddPath(cgContext, cgFillPath);
              CGContextSetRGBFillColor(cgContext, curveInteriorColorRgba[0], curveInteriorColorRgba[1], curveInteriorColorRgba[2], curveInteriorColorRgba[3]);
              CGContextFillPath(cgContext);

              if (thickness)
              {
                CGContextAddPath(cgContext, cgStrokePath);
                CGContextSetLineWidth(cgContext, 1.*thickness);
                CGContextSetRGBStrokeColor(cgContext, curveColorRgba[0], curveColorRgba[1], curveColorRgba[2], curveColorRgba[3]);
                CGContextStrokePath(cgContext);
              }//end if (thickness)
              
              CGPathRelease(cgFillPath);
              CGPathRelease(cgStrokePath);
              CGContextRestoreGState(cgContext);
            }//end if (!self.isWindowResizing)
            else//if (self.isWindowResizing)
            {
              NSRect cachedBounds = cache.contextBounds;
              CGFloat scaleX = !cachedBounds.size.width ? 0. : bounds.size.width/cachedBounds.size.width;
              CGFloat scaleY = !cachedBounds.size.height ? 0. : bounds.size.height/cachedBounds.size.height;
              for(size_t x = 0 ; x<(cachedDataSize+elementPixelSize-1)/elementPixelSize ; ++x)
              {
                NSRange x_px = cachedData[x]->x_px;
                NSRange y_px = cachedData[x]->y_px;
                CGContextFillRect(cgContext, CGRectMake(x_px.location*scaleX, y_px.location*scaleY, x_px.length*scaleX, y_px.length*scaleY));
              }//end or each x
            }//end if (self.isWindowResizing)
          }//end if (cachedData && cachedDataSize)
        }//end if (cacheIsUsable)
      }//end @synchronized(cache)
    }//end if (graphMode == CHGRAPH_MODE_Y_FROM_X)
    else if (graphMode == CHGRAPH_MODE_XY_PREDICATE)
    {
      @synchronized(cache)
      {
        if (cacheIsUsable)
        {
          CGContextSaveGState(cgContext);
          if (self.isWindowResizing)
          {
            NSRect cachedBounds = cache.contextBounds;
            CGFloat scaleX = !cachedBounds.size.width ? 0. : bounds.size.width/cachedBounds.size.width;
            CGFloat scaleY = !cachedBounds.size.height ? 0. : bounds.size.height/cachedBounds.size.height;
            CGContextScaleCTM(cgContext, !scaleX ? 1 : scaleX, !scaleY ? 1 : scaleY);
          }//end if (self.isWindowResizing)
          CGContextBeginTransparencyLayer(cgContext, 0);
          CGContextSetAllowsAntialiasing(cgContext, NO);
          CGContextSetShouldAntialias(cgContext, NO);
          CGContextSetBlendMode(cgContext, kCGBlendModeCopy);
          
          NSColor* colorPredicateFalse = nil;
          NSColor* colorPredicateTrue = nil;
          if ([(id)self->delegate respondsToSelector:@selector(graphView:predicateColorFalseForCurve:)])
            colorPredicateFalse = [self->delegate graphView:self predicateColorFalseForCurve:curve];
          if ([(id)self->delegate respondsToSelector:@selector(graphView:predicateColorTrueForCurve:)])
            colorPredicateTrue = [self->delegate graphView:self predicateColorTrueForCurve:curve];
          colorPredicateFalse = [colorPredicateFalse colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
          colorPredicateTrue = [colorPredicateTrue colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

          CGFloat color0[4] = {1, 0, 0, .5};
          CGFloat color1[4] = {0, 0, 0, .5};
          CGFloat color2[4] = {0, 0, 0, .5};
          CGFloat color3[4] = {0, 0, 0, .5};
          CGFloat color4[4] = {0, 1, 0, .5};
          [colorPredicateFalse getRed:&color0[0] green:&color0[1] blue:&color0[2] alpha:&color0[3]];
          [colorPredicateTrue getRed:&color4[0] green:&color4[1] blue:&color4[2] alpha:&color4[3]];
          interpolate(color0[0], color0[1], color0[2], color4[0], color4[1], color4[2], .25,
                      &color1[0], &color1[1], &color1[2]);
          color1[3] = interpolate(color0[3], color4[3], .25);
          interpolate(color0[0], color0[1], color0[2], color4[0], color4[1], color4[2], .50,
                      &color2[0], &color2[1], &color2[2]);
          color2[3] = interpolate(color0[3], color4[3], .5);
          interpolate(color0[0], color0[1], color0[2], color4[0], color4[1], color4[2], .75,
                      &color3[0], &color3[1], &color3[2]);
          color3[3] = interpolate(color0[3], color4[3], .75);
          CGColorSpaceRef cgColorSpace = CGColorSpaceCreateDeviceRGB();
          CGColorRef colors[5] = {0};
          colors[0] = CGColorCreate(cgColorSpace, color0);
          colors[1] = CGColorCreate(cgColorSpace, color1);
          colors[2] = CGColorCreate(cgColorSpace, color2);
          colors[3] = CGColorCreate(cgColorSpace, color3);
          colors[4] = CGColorCreate(cgColorSpace, color4);
          NSUInteger pixelLimit = 1;
          BOOL drawEdges = NO;
          drawElement2d(cgContext, cache.rootElement2d, pixelLimit, colors, drawEdges);
          CGColorRelease(colors[0]);
          CGColorRelease(colors[1]);
          CGColorRelease(colors[2]);
          CGColorRelease(colors[3]);
          CGColorRelease(colors[4]);
          CGColorSpaceRelease(cgColorSpace);
          CGContextSetAllowsAntialiasing(cgContext, YES);
          CGContextSetShouldAntialias(cgContext, YES);
          CGContextEndTransparencyLayer(cgContext);
          CGContextRestoreGState(cgContext);
        }//end if (cacheIsUsable)
      }//end @synchronized(cache)
    }//end if (graphMode == CHGRAPH_MODE_XY_PREDICATE)
  }];//end for each curve
  
  if (drawAxes)
  {
    CGContextSetRGBFillColor(cgContext, axisColorXRgba[0], axisColorXRgba[1], axisColorXRgba[2], axisColorXRgba[3]);
    CGContextFillRect(cgContext, CGRectMake(0, xAxis_px.px, bounds.size.width, 1));

    CGContextSetRGBFillColor(cgContext, axisColorYRgba[0], axisColorYRgba[1], axisColorYRgba[2], axisColorYRgba[3]);
    CGContextFillRect(cgContext, CGRectMake(yAxis_px.px, 0, 1, bounds.size.height));
    
    for(auto it : ticksToDraw)
    {
      chgraph_axis_orientation_flags_t orientation = std::get<0>(it);
      const CGFloat* color =
        (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) ? &axisColorXRgba[0] :
        (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)   ? &axisColorYRgba[0] :
        &axisColorDefaultRgba[0];
      CGContextSetRGBFillColor(cgContext, color[0], color[1], color[2], color[3]);
      
      NSUInteger pixelPos = std::get<1>(it);
      BOOL isMajorTick = std::get<2>(it);
      NSUInteger width = isMajorTick ? 9 : 3;
      NSUInteger offset =
        (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) ?
          (xAxis_px.px != NSNotFound) ? xAxis_px.px :
          (mpfr_sgn(&yAxis.scale.computeRange->right)<0) ? mpz_get_nsui(self->cachedBoundsHeightPixelZ) : 0 :
        (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL) ?
          (yAxis_px.px != NSNotFound) ? yAxis_px.px :
          (mpfr_sgn(&xAxis.scale.computeRange->right)<0) ? mpz_get_nsui(self->cachedBoundsWidthPixelZ) : 0 :
        0;
      CGRect rect =
        (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) ? CGRectMake(pixelPos, (NSInteger)offset-(NSInteger)(width/2), 1, width) :
        (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL) ? CGRectMake((NSInteger)offset-(NSInteger)(width/2), pixelPos, width, 1) :
        CGRectZero;
      CGContextFillRect(cgContext, rect);
    }//end for each tick to draw
  }//end if (drawAxes)

  if (drawMajorValues)
  {
    BOOL zeroAlreadyDrawn = NO;
    for(auto it : majorValuesToDraw)
    {
      NSAttributedString* attributedString = std::get<0>(it);
      CTLineRef line = std::get<1>(it);
      if (line)
      {
        chgraph_axis_orientation_flags_t orientation = std::get<2>(it);
        CGRect rect = std::get<3>(it);
        BOOL isZero = std::get<4>(it);
        if (!isZero || !zeroAlreadyDrawn)
        {
          CGContextSaveGState(cgContext);
          CGContextSetTextMatrix(cgContext, CGAffineTransformMakeScale(1, 1));
          if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
          {
            rect.origin.x = MAX(0, rect.origin.x-(!isZero ? 0 : (rect.size.width/2+2)));
            rect.origin.y =
              (xAxis_px.px == NSNotFound) ?
                (mpfr_sgn(&yAxis.scale.computeRange->right)<0) ? (bounds.size.height-rect.size.height) : 0 :
              MAX(0, MIN(xAxis_px.px-rect.size.height-2, bounds.size.height-rect.size.height));
          }//end if (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL)
          else if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
          {
            rect.origin.x = (yAxis_px.px == NSNotFound) ?
                (mpfr_sgn(&xAxis.scale.computeRange->right)<0) ? (bounds.size.width-rect.size.width) : 0 :
              MAX(0, MIN(yAxis_px.px-rect.size.width-2, bounds.size.width-rect.size.width));
            rect.origin.y = MAX(0, rect.origin.y-(!isZero ? 0 : rect.size.height/2));
          }//end if (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL)
          CGContextTranslateCTM(cgContext, rect.origin.x, rect.origin.y);
          NSArray* runs = (NSArray*)CTLineGetGlyphRuns(line);
          for(id runId in runs)
          {
            CTRunRef run = (CTRunRef)runId;
            CFRange range = CTRunGetStringRange(run);
            NSDictionary* attributes = [attributedString attributesAtIndex:range.location effectiveRange:0];
            BOOL hasSuperScript = ([[[attributes objectForKey:NSSuperscriptAttributeName] dynamicCastToClass:[NSNumber class]] integerValue] == 1);
            CGAffineTransform currentTextMatrix = CGContextGetTextMatrix(cgContext);
            CGAffineTransform newTextMatrix = currentTextMatrix;
            if (hasSuperScript)
              newTextMatrix = CGAffineTransformConcat(newTextMatrix, CGAffineTransformMakeTranslation(0, 10));
            newTextMatrix = CGAffineTransformConcat(newTextMatrix, CGAffineTransformMakeTranslation(0, 1));//IDK why seems required
            CGContextSetTextMatrix(cgContext, newTextMatrix);
            //first draw invisible to compute real draw range
            CGRect imageBounds = CTRunGetImageBounds(run, cgContext, CFRangeMake(0, 0));
            imageBounds.origin.x += rect.origin.x;
            imageBounds.origin.y += rect.origin.y;
            newTextMatrix = CGAffineTransformConcat(newTextMatrix,
              CGAffineTransformMakeTranslation(
                -MIN(0, CGRectGetMinX(imageBounds)-2)-MAX(0, CGRectGetMaxX(imageBounds)-bounds.size.width+2),
                -MIN(0, CGRectGetMinY(imageBounds)-2)-MAX(0, CGRectGetMaxY(imageBounds)-bounds.size.height+2)));
            CGContextSetTextMatrix(cgContext, newTextMatrix);
            CTRunDraw(run, cgContext, CFRangeMake(0, 0));
            if (hasSuperScript)
              newTextMatrix = currentTextMatrix;
            CGContextSetTextMatrix(cgContext, newTextMatrix);
          }//end for each run
          CFRelease(line);
          CGContextRestoreGState(cgContext);
          zeroAlreadyDrawn |= isZero;
        }//end if (!isZero || !zeroAlreadyDrawn)
      }//end for each line
      [attributedString release];
    }//end for each majorValuesToDraw
  }//end if (drawMajorValues)

  if (self->didUpdateCache)
  {
    [self updateDataCursorValues];
    self->didUpdateCache = NO;
  }//end if (self->didUpdateCache)
  
  if (self->isDragging && self.isGraphDragging){
  }
  else if (drawDataCursors && !self.isWindowResizing && NSPointInRect(mouseLocation, bounds) &&
      (self->dataCursorCachedX.type != CHALK_VALUE_TYPE_UNDEFINED) && self->dataCursorCachedYsCount)
  {
    chalk_graph_pixel_t x_px =
      [self convertGraphValueToPixel:&self->dataCursorCachedX pixelsCount:self->cachedBoundsWidthPixelZ scale:self->graphContext.axisHorizontal1.scale context:self->graphContext.chalkContext];
    if (x_px.px != NSNotFound)
    for(size_t i = 0 ; i<self->dataCursorCachedYsCount ; ++i)
    {
      chalk_graph_pixel_t yEstimation_px =
        [self convertGraphValueToPixel:self->dataCursorCachedYs+i pixelsCount:self->cachedBoundsHeightPixelZ
        scale:self->graphContext.axisVertical1.scale context:self->graphContext.chalkContext];
      NSRange y_px =
        [self convertGraphValueToPixelRange:self->dataCursorCachedYs+i pixelsCount:self->cachedBoundsHeightPixelZ scale:self->graphContext.axisVertical1.scale context:self->graphContext.chalkContext];
      if ((y_px.location != NSNotFound) && (yEstimation_px.px != NSNotFound))
      {
        CGContextSaveGState(cgContext);
        CGContextSetLineDash(cgContext, 0, (const CGFloat[]){3, 3}, 2);
        CGRect rect = CGRectMake(1.*x_px.px-1, 1.*y_px.location-1, 3, y_px.length+2);
        CGContextStrokeRect(cgContext, rect);
        CGPoint vertical[4] = {
          CGPointMake(x_px.px, 0),
          CGPointMake(x_px.px, CGRectGetMinY(rect)),
          CGPointMake(x_px.px, CGRectGetMaxY(rect)),
          CGPointMake(x_px.px, bounds.size.height)
        };
        CGContextStrokeLineSegments(cgContext, vertical, sizeof(vertical)/sizeof(CGPoint));
        CGPoint horizontal[4] = {
          CGPointMake(0, yEstimation_px.px),
          CGPointMake(CGRectGetMinX(rect), yEstimation_px.px),
          CGPointMake(CGRectGetMaxX(rect), yEstimation_px.px),
          CGPointMake(bounds.size.width, yEstimation_px.px),
        };
        CGContextStrokeLineSegments(cgContext, horizontal, sizeof(horizontal)/sizeof(CGPoint));
        CGContextRestoreGState(cgContext);
      }//end if ((y_px.location != NSNotFound) && (yEstimation_px != NSNotFound))
    }//end for each y
  }//end if (drawDataCursors && !self.isWindowResizing && NSPointInRect(mouseLocation, bounds) &&
   //        (self->dataCursorCachedX.type != CHALK_VALUE_TYPE_UNDEFINED && self->dataCursorCachedYsCount)

  chalkGmpFlagsRestore(oldFlags);
}
//end renderInContext:bounds:drawAxes:drawMajorGrid:drawMinorGrid:drawMajorValues:drawDataCursors:mouseLocation:

-(void) updateTrackingAreas
{
  NSTrackingArea* newTrackingArea = [[NSTrackingArea alloc] initWithRect:NSRectFromCGRect(self.bounds)
    options:self->trackingArea.options owner:self->trackingArea.owner userInfo:self->trackingArea.userInfo];
  [self removeTrackingArea:self->trackingArea];
  [self->trackingArea release];
  self->trackingArea = newTrackingArea;
  [self addTrackingArea:self->trackingArea];
}
//end updateTrackingAreas

-(void) cancelOperation:(NSEvent*)event
{
  if (self->isDragging)
  {
    self->isDragging = NO;
    if (([NSEvent pressedMouseButtons] & 1) != 0)
      [self mouseDown:event];
    [self setNeedsDisplay:YES];
  }//end if (self->isDragging)
}
//end keyDown:

-(void) mouseEntered:(NSEvent *)event
{
  [self updateDataCursorValues];
}
//end mouseEntered:

-(void) mouseExited:(NSEvent *)event
{
  [self updateDataCursorValues];
}
//end mouseExited:

-(void) mouseDown:(NSEvent*)event
{
  if (!self->isDragging)
  {
    chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
    NSPoint mouseWindowLocation = [event respondsToSelector:@selector(locationInWindow)] ?
      event.locationInWindow : self.window.mouseLocationOutsideOfEventStream;
    self->draggingStartLocation = [self convertPoint:mouseWindowLocation fromView:nil];
    mpfi_set_prec(self->draggingStartXRange, self->graphContext.axisPrec);
    mpfi_set_prec(self->draggingStartYRange, self->graphContext.axisPrec);
    mpfi_set(self->draggingStartXRange, self->graphContext.axisHorizontal1.scale.computeRange);
    mpfi_set(self->draggingStartYRange, self->graphContext.axisVertical1.scale.computeRange);
    chalkGmpFlagsRestore(oldFlags);
  }//end if (!self->isDragging)
}
//end mouseDown:

-(void) mouseDragged:(NSEvent*)event
{
  self->isDragging = YES;
  if (self->isDragging)
  {
    NSPoint draggingCurrentLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint dragVector = NSMakePoint(
      draggingCurrentLocation.x-self->draggingStartLocation.x,
      draggingCurrentLocation.y-self->draggingStartLocation.y);
    if (self.isGraphDragging)
      [self moveScales:dragVector];
    else if (self.isGraphZooming)
      [self setNeedsDisplay:YES];
    [self updateDataCursorValues];
  }//end if (!self->isDragging)
}
//end mouseDragged:

-(void) mouseUp:(NSEvent*)event
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (!self->isDragging)
  {
    if (event.clickCount != 1){
    }
    else if (self.isGraphZooming)
    {
      if (self.isGraphZoomingIn)
        [self performZoomX:1 zoomY:1];
      else if (self.isGraphZoomingOut)
        [self performZoomX:-1 zoomY:-1];
    }//end if (self.isGraphZooming)
  }//end if (!self->isDragging)
  else//if (self->isDragging)
  {
    if (self.isGraphDragging)
      [self setNeedsDisplay:YES];
    if (self.isGraphZooming)
    {
      NSPoint draggingCurrentLocation = [self convertPoint:[event locationInWindow] fromView:nil];
      NSPoint dragVector = NSMakePoint(
        draggingCurrentLocation.x-self->draggingStartLocation.x,
        draggingCurrentLocation.y-self->draggingStartLocation.y);
      CGFloat norm2 = sqrt(dragVector.x*dragVector.x+dragVector.y*dragVector.y);
      BOOL almostClick = (norm2 <= 5);
      if (almostClick)
      {
        if (self.isGraphZoomingIn)
          [self performZoomX:1 zoomY:1];
        else if (self.isGraphZoomingOut)
          [self performZoomX:-1 zoomY:-1];
      }//end if (almostClick)
      else//if (!almostClick)
      {
        CHGraphScale* xScale = graphContext.axisHorizontal1.scale;
        CHGraphScale* yScale = graphContext.axisVertical1.scale;
        
        NSPoint windowLocation = event.locationInWindow;
        NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
        CGRect zoomRect = CGRectStandardize(CGRectMake(self->draggingStartLocation.x, self->draggingStartLocation.y,
            viewLocation.x-self->draggingStartLocation.x,
            viewLocation.y-self->draggingStartLocation.y));
        CGRect zoomRectClipped = CGRectIntersection(self.bounds, zoomRect);
        CGRect zoomRectBacking = NSRectToCGRect([self convertRectToBacking:NSRectFromCGRect(zoomRectClipped)]);
        
        NSRange x_px = NSMakeRange((NSUInteger)CGRectGetMinX(zoomRectBacking), (NSUInteger)zoomRectBacking.size.width);
        NSRange y_px = NSMakeRange((NSUInteger)CGRectGetMinY(zoomRectBacking), (NSUInteger)zoomRectBacking.size.height);

        chalk_gmp_value_t xVisualValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
        chalk_gmp_value_t yVisualValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
        chalkGmpValueMakeRealApprox(&xVisualValue, self->graphContext.axisPrec, self->graphGmpPool);
        chalkGmpValueMakeRealApprox(&yVisualValue, self->graphContext.axisPrec, self->graphGmpPool);
        [self convertPixelRange:x_px toGraphValue:&xVisualValue pixelsCount:self->cachedBoundsWidthPixelZ scale:xScale context:self->graphContext.chalkContext];
        [self convertPixelRange:y_px toGraphValue:&yVisualValue pixelsCount:self->cachedBoundsHeightPixelZ scale:yScale context:self->graphContext.chalkContext];

        chalk_gmp_value_t xComputeValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
        chalk_gmp_value_t yComputeValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
        chalkGmpValueMakeRealApprox(&xComputeValue, self->graphContext.axisPrec, self->graphGmpPool);
        chalkGmpValueMakeRealApprox(&yComputeValue, self->graphContext.axisPrec, self->graphGmpPool);
        [xScale convertMpfirVisualValue:xVisualValue.realApprox toComputeValue:xComputeValue.realApprox];
        [yScale convertMpfirVisualValue:yVisualValue.realApprox toComputeValue:yComputeValue.realApprox];
        
        if (self.isGraphZoomingIn)
        {
          mpfi_set(xScale.computeRange, &xComputeValue.realApprox->interval);
          mpfi_set(yScale.computeRange, &yComputeValue.realApprox->interval);
        }//end if (self.isGraphZoomingIn)
        else if (self.isGraphZoomingOut)
        {
          mpfr_t tmp1;
          mpfr_t tmp2;
          mpfr_t tmp3;
          mpfr_t tmp4;
          mpfr_t tmp5;
          mpfr_t tmp6;
          mpfrDepool(tmp1, self->graphContext.axisPrec, self->graphGmpPool);
          mpfrDepool(tmp2, self->graphContext.axisPrec, self->graphGmpPool);
          mpfrDepool(tmp3, self->graphContext.axisPrec, self->graphGmpPool);
          mpfrDepool(tmp4, self->graphContext.axisPrec, self->graphGmpPool);
          mpfrDepool(tmp5, self->graphContext.axisPrec, self->graphGmpPool);
          mpfrDepool(tmp6, self->graphContext.axisPrec, self->graphGmpPool);
          mpfr_sub(tmp1, &xComputeValue.realApprox->interval.left, &xScale.computeRange->left, MPFR_RNDN);
          mpfr_sub(tmp2, &xScale.computeRange->right, &xComputeValue.realApprox->interval.right, MPFR_RNDN);
          mpfi_diam(tmp3, &xComputeValue.realApprox->interval);
          mpfi_diam(tmp4, xScale.computeRange);
          mpfr_div(tmp5, tmp1, tmp3, MPFR_RNDN);
          mpfr_mul(tmp6, tmp4, tmp5, MPFR_RNDN);
          mpfr_sub(&xScale.computeRange->left, &xScale.computeRange->left, tmp6, MPFR_RNDN);
          mpfr_div(tmp5, tmp2, tmp3, MPFR_RNDN);
          mpfr_mul(tmp6, tmp4, tmp5, MPFR_RNDN);
          mpfr_add(&xScale.computeRange->right, &xScale.computeRange->right, tmp6, MPFR_RNDN);

          mpfr_sub(tmp1, &yComputeValue.realApprox->interval.left, &yScale.computeRange->left, MPFR_RNDN);
          mpfr_sub(tmp2, &yScale.computeRange->right, &yComputeValue.realApprox->interval.right, MPFR_RNDN);
          mpfi_diam(tmp3, &yComputeValue.realApprox->interval);
          mpfi_diam(tmp4, yScale.computeRange);
          mpfr_div(tmp5, tmp1, tmp3, MPFR_RNDN);
          mpfr_mul(tmp6, tmp4, tmp5, MPFR_RNDN);
          mpfr_sub(&yScale.computeRange->left, &yScale.computeRange->left, tmp6, MPFR_RNDN);
          mpfr_div(tmp5, tmp2, tmp3, MPFR_RNDN);
          mpfr_mul(tmp6, tmp4, tmp5, MPFR_RNDN);
          mpfr_add(&yScale.computeRange->right, &yScale.computeRange->right, tmp6, MPFR_RNDN);
          mpfrRepool(tmp1, self->graphGmpPool);
          mpfrRepool(tmp2, self->graphGmpPool);
          mpfrRepool(tmp3, self->graphGmpPool);
          mpfrRepool(tmp4, self->graphGmpPool);
          mpfrRepool(tmp5, self->graphGmpPool);
          mpfrRepool(tmp6, self->graphGmpPool);
        }//end if (self.isGraphZoomingOut)
        
        chalkGmpValueClear(&xVisualValue, YES, self->graphGmpPool);
        chalkGmpValueClear(&yVisualValue, YES, self->graphGmpPool);
        chalkGmpValueClear(&xComputeValue, YES, self->graphGmpPool);
        chalkGmpValueClear(&yComputeValue, YES, self->graphGmpPool);

        [xScale updateData];
        [yScale updateData];
        [self invalidateData:nil];
        if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangeAxis:didZoom:)])
          [self->delegate graphView:self didChangeAxis:CHGRAPH_AXIS_ORIENTATION_HORIZONTAL|CHGRAPH_AXIS_ORIENTATION_VERTICAL didZoom:YES];
      }//end if (!almostClick)
    }//end if (self.isGraphZooming)
    self->isDragging = NO;
  }//end if (self->isDragging)
  chalkGmpFlagsRestore(oldFlags);
}
//end mouseUp:

-(void) mouseMoved:(NSEvent*)theEvent
{
  [self updateDataCursorValues];
}
//end mouseMoved:

-(void) scrollWheel:(NSEvent*)event
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  mpfi_set_prec(self->draggingStartXRange, self->graphContext.axisPrec);
  mpfi_set_prec(self->draggingStartYRange, self->graphContext.axisPrec);
  mpfi_set(self->draggingStartXRange, self->graphContext.axisHorizontal1.scale.computeRange);
  mpfi_set(self->draggingStartYRange, self->graphContext.axisVertical1.scale.computeRange);
  //[self scaleScales:NSMakePoint(event.scrollingDeltaX, event.scrollingDeltaY)];
  CGFloat zoomY = event.scrollingDeltaY/100;
  [self performZoomX:zoomY zoomY:zoomY];
  chalkGmpFlagsRestore(oldFlags);
}
//end scrollWheel:

-(void) performZoomX:(CGFloat)zoomFactorX zoomY:(CGFloat)zoomFactorY
{
  CHGraphScale* xScale = graphContext.axisHorizontal1.scale;
  CHGraphScale* yScale = graphContext.axisVertical1.scale;

  NSPoint screenLocation = [NSEvent mouseLocation];
  NSPoint windowLocation = [[self window] convertRectFromScreen:NSMakeRect(screenLocation.x, screenLocation.y, 0, 0)].origin;
  NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
  NSPoint backingLocation = [self convertPointToBacking:viewLocation];
  NSUInteger x_px = (NSUInteger)round(backingLocation.x);
  NSUInteger y_px = (NSUInteger)round(backingLocation.y);
  chalk_gmp_value_t xVisualValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
  chalk_gmp_value_t yVisualValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
  chalkGmpValueMakeRealApprox(&xVisualValue, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealApprox(&yVisualValue, self->graphContext.axisPrec, self->graphGmpPool);
  [self convertPixelRange:NSMakeRange(x_px, 1) toGraphValue:&xVisualValue pixelsCount:self->cachedBoundsWidthPixelZ scale:xScale context:self->graphContext.chalkContext];
  [self convertPixelRange:NSMakeRange(y_px, 1) toGraphValue:&yVisualValue pixelsCount:self->cachedBoundsHeightPixelZ scale:yScale context:self->graphContext.chalkContext];

  chalk_gmp_value_t xComputeValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
  chalk_gmp_value_t yComputeValue = {CHALK_VALUE_TYPE_UNDEFINED, 0};
  chalkGmpValueMakeRealApprox(&xComputeValue, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealApprox(&yComputeValue, self->graphContext.axisPrec, self->graphGmpPool);
  [xScale convertMpfirVisualValue:xVisualValue.realApprox toComputeValue:xComputeValue.realApprox];
  [yScale convertMpfirVisualValue:yVisualValue.realApprox toComputeValue:yComputeValue.realApprox];
  chalkGmpValueMakeRealExact(&xComputeValue, self->graphContext.axisPrec, self->graphGmpPool);
  chalkGmpValueMakeRealExact(&yComputeValue, self->graphContext.axisPrec, self->graphGmpPool);

  mpfi_ptr xScaleComputeRange = xScale.computeRange;
  mpfi_ptr yScaleComputeRange = yScale.computeRange;
  mpfr_t tmp1;
  mpfr_t tmp2;
  mpfr_t factorPowerX;
  mpfr_t factorPowerY;
  mpfrDepool(tmp1, self->graphContext.axisPrec, self->graphGmpPool);
  mpfrDepool(tmp2, self->graphContext.axisPrec, self->graphGmpPool);
  mpfrDepool(factorPowerX, self->graphContext.axisPrec, self->graphGmpPool);
  mpfrDepool(factorPowerY, self->graphContext.axisPrec, self->graphGmpPool);

  mpfr_set_d(tmp1, 2, MPFR_RNDN);
  mpfr_set_d(tmp2, zoomFactorX, MPFR_RNDN);
  mpfr_pow(factorPowerX, tmp1, tmp2, MPFR_RNDN);
  mpfr_set_d(tmp2, zoomFactorY, MPFR_RNDN);
  mpfr_pow(factorPowerY, tmp1, tmp2, MPFR_RNDN);

  mpfr_sub(tmp1, xComputeValue.realExact, &xScaleComputeRange->left, MPFR_RNDN);
  mpfr_sub(tmp2, &xScaleComputeRange->right, xComputeValue.realExact, MPFR_RNDN);
  mpfr_div(tmp1, tmp1, factorPowerX, MPFR_RNDN);
  mpfr_div(tmp2, tmp2, factorPowerX, MPFR_RNDN);
  mpfr_sub(&xScaleComputeRange->left, xComputeValue.realExact, tmp1, MPFR_RNDN);
  mpfr_add(&xScaleComputeRange->right, xComputeValue.realExact, tmp2, MPFR_RNDN);
  mpfr_sub(tmp1, yComputeValue.realExact, &yScaleComputeRange->left, MPFR_RNDN);
  mpfr_sub(tmp2, &yScaleComputeRange->right, yComputeValue.realExact, MPFR_RNDN);
  mpfr_div(tmp1, tmp1, factorPowerY, MPFR_RNDN);
  mpfr_div(tmp2, tmp2, factorPowerY, MPFR_RNDN);
  mpfr_sub(&yScaleComputeRange->left, yComputeValue.realExact, tmp1, MPFR_RNDN);
  mpfr_add(&yScaleComputeRange->right, yComputeValue.realExact, tmp2, MPFR_RNDN);
  mpfrRepool(tmp1, self->graphGmpPool);
  mpfrRepool(tmp2, self->graphGmpPool);
  mpfrRepool(factorPowerX, self->graphGmpPool);
  mpfrRepool(factorPowerY, self->graphGmpPool);
  
  chalkGmpValueClear(&xVisualValue, YES, self->graphGmpPool);
  chalkGmpValueClear(&yVisualValue, YES, self->graphGmpPool);
  chalkGmpValueClear(&xComputeValue, YES, self->graphGmpPool);
  chalkGmpValueClear(&yComputeValue, YES, self->graphGmpPool);
  
  [xScale updateData];
  [yScale updateData];
  [self invalidateData:nil];
  if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangeAxis:didZoom:)])
    [self->delegate graphView:self didChangeAxis:CHGRAPH_AXIS_ORIENTATION_HORIZONTAL|CHGRAPH_AXIS_ORIENTATION_VERTICAL didZoom:YES];
}
//end performZoom:

/*
-(void) cancelTracking{[self releaseTouches];}
-(void) releaseTouches{[_initialTouches[0] release];[_initialTouches[1] release];[_currentTouches[0] release];[_currentTouches[1] release];memset(_initialTouches, 0, sizeof(_initialTouches));memset(_currentTouches, 0, sizeof(_currentTouches));}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
 
    if (touches.count == 2) {
        NSPoint windowLocation = event.locationInWindow;
        NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
        self->initialPoint = [self convertPointFromBacking:viewLocation];
        NSArray *array = [touches allObjects];
        _initialTouches[0] = [[array objectAtIndex:0] retain];
        _initialTouches[1] = [[array objectAtIndex:1] retain];
        _currentTouches[0] = [_initialTouches[0] retain];
        _currentTouches[1] = [_initialTouches[1] retain];
    } else if (touches.count > 2) {
        // More than 2 touches. Only track 2.
        if (self->isTracking) {
            [self cancelTracking];
        } else {
            [self releaseTouches];
        }
    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event {

    self->modifiers = [event modifierFlags];
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    if (touches.count == 2 && _initialTouches[0]) {
        NSArray *array = [touches allObjects];
        [_currentTouches[0] release];
        [_currentTouches[1] release];
 
        NSTouch *touch;
        touch = [array objectAtIndex:0];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = [touch retain];
        } else {
            _currentTouches[1] = [touch retain];
        }
        touch = [array objectAtIndex:1];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = [touch retain];
        } else {
            _currentTouches[1] = [touch retain];
        }
        NSPoint p = [self deltaOrigin];
        p.x = p.x/10;
        p.y = -p.y/10;
        [self moveScales:p];
    }
}
//end touchesMovedWithEvent:

- (NSPoint)deltaOrigin {
    if (!(_initialTouches[0] && _initialTouches[1] &&
        _currentTouches[0] && _currentTouches[1])) return NSZeroPoint;
 
    CGFloat x1 = MIN(_initialTouches[0].normalizedPosition.x, _initialTouches[1].normalizedPosition.x);
    CGFloat x2 = MAX(_currentTouches[0].normalizedPosition.x, _currentTouches[1].normalizedPosition.x);
    CGFloat y1 = MIN(_initialTouches[0].normalizedPosition.y, _initialTouches[1].normalizedPosition.y);
    CGFloat y2 = MAX(_currentTouches[0].normalizedPosition.y, _currentTouches[1].normalizedPosition.y);
 
    NSSize deviceSize = _initialTouches[0].deviceSize;
    NSPoint delta;
    delta.x = (x2 - x1) * deviceSize.width;
    delta.y = (y2 - y1) * deviceSize.height;
    return delta;
}


- (void)touchesEndedWithEvent:(NSEvent *)event {
    self->modifiers = [event modifierFlags];
    [self cancelTracking];
}
 
- (void)touchesCancelledWithEvent:(NSEvent *)event {
    [self cancelTracking];
}
*/

-(void) viewDidChangeBackingProperties
{
  [self invalidateData:nil];
}
//end viewDidChangeBackingProperties

-(void) viewDidResize:(NSNotification*)notification
{
  [self invalidateData:notification];
}
//end viewDidResize:

-(void) moveScales:(NSPoint)delta
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (delta.x)
  {
    CHGraphScale* xScale = graphContext.axisHorizontal1.scale;
    mpfi_ptr xScaleRange = xScale.computeRange;
    chgraph_scale_t xScaleType = xScale.scaleType;
    if ((xScaleType == CHGRAPH_SCALE_LINEAR) || (xScaleType == CHGRAPH_SCALE_LOGARITHMIC))
    {
      CGFloat width = self.bounds.size.width;
      mpfr_t deltaX;
      mpfrDepool(deltaX, self->graphContext.axisPrec, self->graphGmpPool);
      mpfr_set_d(deltaX, delta.x, MPFR_RNDN);
      if (!width)
        mpfr_set_d(deltaX, 0, MPFR_RNDN);
      else
        mpfr_div_d(deltaX, deltaX, width, MPFR_RNDN);
      mpfr_t diam;
      mpfrDepool(diam, self->graphContext.axisPrec, self->graphGmpPool);
      mpfi_diam_abs(diam, xScaleRange);
      mpfr_mul(deltaX, deltaX, diam, MPFR_RNDN);
      mpfrRepool(diam, self->graphGmpPool);
      mpfi_set_prec(xScaleRange, self->graphContext.axisPrec);
      mpfi_set(xScaleRange, self->draggingStartXRange);
      mpfi_sub_fr(xScaleRange, xScaleRange, deltaX);
      mpfrRepool(deltaX, self->graphGmpPool);
      [xScale updateData];
    }//end if ((xScaleType == CHGRAPH_SCALE_LINEAR) || (xScaleType == CHGRAPH_SCALE_LOGARITHMIC))
    [self invalidateData:nil];
    if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangeAxis:didZoom:)])
      [self->delegate graphView:self didChangeAxis:CHGRAPH_AXIS_ORIENTATION_HORIZONTAL didZoom:NO];
  }//end if (delta)
  if (delta.y)
  {
    CHGraphScale* yScale = graphContext.axisVertical1.scale;
    mpfi_ptr yScaleRange = yScale.computeRange;
    chgraph_scale_t yScaleType = yScale.scaleType;
    if ((yScaleType == CHGRAPH_SCALE_LINEAR) || (yScaleType == CHGRAPH_SCALE_LOGARITHMIC))
    {
      CGFloat height = self.bounds.size.height;
      mpfr_t deltaY;
      mpfrDepool(deltaY, self->graphContext.axisPrec, self->graphGmpPool);
      mpfr_set_d(deltaY, delta.y, MPFR_RNDN);
      if (!height)
        mpfr_set_d(deltaY, 0, MPFR_RNDN);
      else
        mpfr_div_d(deltaY, deltaY, height, MPFR_RNDN);
      mpfr_t diam;
      mpfrDepool(diam, self->graphContext.axisPrec, self->graphGmpPool);
      mpfi_diam_abs(diam, yScaleRange);
      mpfr_mul(deltaY, deltaY, diam, MPFR_RNDN);
      mpfrRepool(diam, self->graphGmpPool);
      mpfi_set_prec(yScaleRange, self->graphContext.axisPrec);
      mpfi_set(yScaleRange, self->draggingStartYRange);
      mpfi_sub_fr(yScaleRange, yScaleRange, deltaY);
      mpfrRepool(deltaY, self->graphGmpPool);
      [yScale updateData];
    }//end if ((yScaleType == CHGRAPH_SCALE_LINEAR) || (yScaleType == CHGRAPH_SCALE_LOGARITHMIC))
    [self invalidateData:nil];
    if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangeAxis:didZoom:)])
      [self->delegate graphView:self didChangeAxis:CHGRAPH_AXIS_ORIENTATION_VERTICAL  didZoom:NO];
  }//end if (delta)
  chalkGmpFlagsRestore(oldFlags);
}
//end moveScales:

-(void) scaleScales:(NSPoint)delta
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  chgraph_axis_orientation_flags_t axisFlags = CHGRAPH_AXIS_ORIENTATION_NONE;
  if (delta.x)
  {
    CHGraphScale* xScale = graphContext.axisHorizontal1.scale;
    //...
    [xScale updateData];
    [self invalidateData:nil];
    axisFlags |= CHGRAPH_AXIS_ORIENTATION_HORIZONTAL;
  }//end if (delta)
  if (delta.y)
  {
    CHGraphScale* yScale = graphContext.axisVertical1.scale;
    //...
    [yScale updateData];
    axisFlags |= CHGRAPH_AXIS_ORIENTATION_VERTICAL;
  }//end if (delta)
  if (axisFlags != CHGRAPH_AXIS_ORIENTATION_NONE)
  {
    [self invalidateData:nil];
    if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangeAxis:didZoom:)])
      [self->delegate graphView:self didChangeAxis:axisFlags didZoom:YES];
  }//end if (axisFlags != CHGRAPH_AXIS_ORIENTATION_NONE)
  chalkGmpFlagsRestore(oldFlags);
}
//end scaleScales:

-(BOOL) updateMajorStep:(CHGraphAxis*)axis axisFlags:(chgraph_axis_orientation_flags_t)axisFlags
{
  BOOL result = NO;
  CHGraphScale* scale = axis.scale;
  if (scale)
  {
    mpfr_t tmp1;
    mpfr_t tmp2;
    mpfr_t tmp3;
    mpfrDepool(tmp1, self->graphContext.axisPrec, self->graphGmpPool);
    mpfrDepool(tmp2, self->graphContext.axisPrec, self->graphGmpPool);
    mpfrDepool(tmp3, self->graphContext.axisPrec, self->graphGmpPool);
    int base = scale.currentBase;
    mpfr_set_si(tmp2, base, MPFR_RNDN);
    mpfr_log(tmp1, tmp2, MPFR_RNDN);
    mpfi_diam_abs(tmp3, scale.computeRange);
    mpfr_log(tmp2, tmp3, MPFR_RNDN);
    mpfr_div(tmp3, tmp2, tmp1, MPFR_RNDN);
    mpfr_floor(tmp2, tmp3);
    mpfr_set_si(tmp1, base, MPFR_RNDN);
    mpfr_pow(tmp3, tmp1, tmp2, MPFR_RNDN);
    mpfr_div_2exp(tmp1, tmp3, 2, MPFR_RNDN);
    result |= (mpfr_cmp(axis.majorStep, tmp1) != 0);
    mpfr_set(axis.majorStep, tmp1, MPFR_RNDN);
    mpfrRepool(tmp1, self->graphGmpPool);
    mpfrRepool(tmp2, self->graphGmpPool);
    mpfrRepool(tmp3, self->graphGmpPool);
    if (result)
      [self setNeedsDisplay:YES];
  }//end if (scale)
  return result;
}
//end updateMajorStep:axisFlags:

-(CHGraphCurveCachedData*) cacheForCurve:(CHGraphCurve*)curve
{
  __block CHGraphCurveCachedData* result = nil;
  [self->curvesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveCachedData* graphCurveCachedData = [obj dynamicCastToClass:[CHGraphCurveCachedData class]];
    CHGraphCurve* graphCurve = graphCurveCachedData.curve;
    if (graphCurve == curve)
      result = graphCurveCachedData;
    if (result)
      *stop = YES;
  }];//end for each curve
  return result;
}
//end cacheForCurve:

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  CHGraphCurveCachedData* cache = [object dynamicCastToClass:[CHGraphCurveCachedData class]];
  if ([keyPath isEqualToString:@"isPreparing"])
  {
    if ([(id)self->delegate respondsToSelector:@selector(graphView:didChangePreparingCurveWithCache:)])
      [self->delegate graphView:self didChangePreparingCurveWithCache:cache];
  }//end if ([keyPath isEqualToString:@"isPreparing"])
}
//end observeValueForKeyPath:ofObject:change:context:

@end
