//
//  CHGraphView.h
//  Chalk
//
//  Created by Pierre Chatelier on 08/05/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkIdentifierManager.h"
#import "CHGraphUtils.h"

@class CHGraphAxis;
@class CHGraphContext;
@class CHGraphCurve;
@class CHGraphCurveCachedData;
@class CHGraphScale;
@class CHGraphView;

@protocol CHGraphViewDelegate
@optional
-(void) graphView:(CHGraphView*)graphView didUpdateCursorValue:(CHGraphCurve*)graphCurve;
-(void) graphView:(CHGraphView*)graphView didChangeAxis:(chgraph_axis_orientation_flags_t)axisFlags didZoom:(BOOL)didZoom;
-(void) graphView:(CHGraphView*)graphView didChangePreparingCurveWithCache:(CHGraphCurveCachedData*)cache;
-(NSUInteger) graphView:(CHGraphView*)graphView curveThicknessForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView curveColorForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView curveInteriorColorForCurve:(CHGraphCurve*)curve;
-(BOOL)       graphView:(CHGraphView*)graphView curveUncertaintyVisibleForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView curveUncertaintyColorForCurve:(CHGraphCurve*)curve;
-(BOOL)       graphView:(CHGraphView*)graphView curveUncertaintyNaNVisibleForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView curveUncertaintyNaNColorForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView predicateColorFalseForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphView:(CHGraphView*)graphView predicateColorTrueForCurve:(CHGraphCurve*)curve;
-(NSColor*)   graphViewBackgroundColor:(CHGraphView*)graphView;
-(NSFont*)    graphViewFont:(CHGraphView*)graphView;
-(NSColor*)   graphView:(CHGraphView*)graphView axisColorForOrientation:(chgraph_axis_orientation_flags_t)orientation;
@end

@interface CHGraphView : NSView {
  CHGmpPool* graphGmpPool;
  CHGraphContext* graphContext;
  CHGraphDataPool* graphDataPool;
  mpfr_t halfOne;
  mpz_t cachedPixelXZ;
  mpz_t cachedPixelYZ;
  mpz_t cachedBoundsWidthPixelZ;
  mpz_t cachedBoundsHeightPixelZ;
  NSTrackingArea* trackingArea;
  BOOL isDragging;
  NSPoint draggingStartLocation;
  mpfi_t draggingStartXRange;
  mpfi_t draggingStartYRange;
  NSMutableString* xString;
  NSMutableString* yString;
  
  NSMutableArray* curvesData;
  chgraph_action_t currentAction;
  
  chalk_gmp_value_t  dataCursorCachedX;
  chalk_gmp_value_t* dataCursorCachedYs;
  size_t             dataCursorCachedYsCount;
  
  volatile BOOL didUpdateCache;
}

@property(readonly,assign) CHGraphContext* graphContext;
@property(readonly,copy)   NSString* xString;
@property(readonly,copy)   NSString* yString;
@property(assign)          IBOutlet id<CHGraphViewDelegate> delegate;
@property(nonatomic,copy)  NSArray* curvesData;
@property(nonatomic)       chgraph_action_t currentAction;
@property                  BOOL isWindowResizing;

-(void) addCurve:(CHGraphCurve*)curve;
-(void) removeCurve:(CHGraphCurve*)curve;

-(void) moveScales:(NSPoint)delta;
-(void) scaleScales:(NSPoint)delta;

-(CHGraphCurveCachedData*) cacheForCurve:(CHGraphCurve*)curve;
-(void) renderInContext:(CGContextRef)context bounds:(CGRect)bounds drawAxes:(BOOL)drawAxes drawMajorGrid:(BOOL)drawMajorGrid drawMinorGrid:(BOOL)drawMinorGrid drawMajorValues:(BOOL)drawMajorValues drawDataCursors:(BOOL)drawDataCursors mouseLocation:(CGPoint)mouseLocation;

-(BOOL) updateMajorStep:(CHGraphAxis*)axis axisFlags:(chgraph_axis_orientation_flags_t)axisFlags;

-(void) convertPixelRange:(NSRange)pixelRange toGraphValue:(chalk_gmp_value_t*)value
              pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                   context:(CHChalkContext*)context;
-(NSRange) convertGraphValueToPixelRange:(const chalk_gmp_value_t*)value
                             pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                                 context:(CHChalkContext*)context;
-(chalk_graph_pixel_t) convertGraphValueToPixel:(const chalk_gmp_value_t*)value
                                    pixelsCount:(mpz_srcptr)pixelsCount scale:(CHGraphScale*)scale
                                        context:(CHChalkContext*)context;
@end
