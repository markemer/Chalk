//
//  IJSVGLayer.h
//  IJSVGExample
//
//  Created by Curtis Hard on 07/01/2017.
//  Copyright © 2017 Curtis Hard. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "IJSVGTransaction.h"

@class IJSVGShapeLayer;
@class IJSVGGradientLayer;
@class IJSVGPatternLayer;
@class IJSVGStrokeLayer;

#define IJSVG_LAYER_ADD_SUBVIEW_DEFAULT_IMPLEMENTATION \
- (void)addSublayer:(CALayer *)layer { \
    if([layer isKindOfClass:[IJSVGLayer class]] == NO && \
       [layer isKindOfClass:[IJSVGShapeLayer class]] == NO) { \
        NSString * r = [NSString stringWithFormat:@"The layer must be an instance of IJSVGLayer, %@ given.", \
                [layer class]]; \
        NSException * exception = [NSException exceptionWithName:@"IJSVGInvalidSublayerException"\
            reason:r \
            userInfo:nil];\
        @throw exception; \
    }\
    [super addSublayer:layer];\
} \
\
- (void)setBackingScaleFactor:(CGFloat)newFactor \
{ \
    if(self.backingScaleFactor == newFactor) { \
        return; \
    } \
    backingScaleFactor = newFactor; \
    self.contentsScale = newFactor; \
    self.rasterizationScale = newFactor; \
    [self setNeedsDisplay]; \
};

#define IJSVG_LAYER_DEFAULT_PROPERTIES \
@property (nonatomic, assign) IJSVGGradientLayer * gradientFillLayer; \
@property (nonatomic, assign) IJSVGPatternLayer * patternFillLayer; \
@property (nonatomic, assign) IJSVGStrokeLayer * strokeLayer; \
@property (nonatomic, assign) BOOL requiresBackingScaleHelp; \
@property (nonatomic, assign) CGFloat backingScaleFactor;

#define IJSVG_LAYER_DEFAULT_SYNTHESIZE \
@synthesize gradientFillLayer; \
@synthesize patternFillLayer; \
@synthesize strokeLayer; \
@synthesize requiresBackingScaleHelp; \
@synthesize backingScaleFactor;

#define IJSVG_LAYER_DEFAULT_DEALLOC_INSTRUCTIONS \
IJSVGBeginTransactionLock(); \
    [super dealloc]; \
IJSVGEndTransactionLock();

@interface IJSVGLayer : CALayer {
    
}

IJSVG_LAYER_DEFAULT_PROPERTIES

@end
