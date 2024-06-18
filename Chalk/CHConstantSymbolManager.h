//
//  CHConstantSymbolManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 28/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHSVGRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@class CHConstantSymbolManager;

@protocol CHConstantSymbolManagerDelegate
-(void) constantSymbolManager:(CHConstantSymbolManager*)constantSymbolManager didEndRenderTexSymbol:(NSString*)texSymbol;
@end

@interface CHConstantSymbolManager : NSObject<CHSVGRendererDelegate> {
  CHSVGRenderer* renderer;
  NSMutableDictionary* texImages;
  NSMutableArray* renderQueue;
  id<CHConstantSymbolManagerDelegate> delegate;
}

+(instancetype) sharedManager;

@property(nonatomic,assign) id<CHConstantSymbolManagerDelegate> delegate;

-(void) submit:(NSString*)symbol;
-(NSImage*) imageForTexSymbol:(NSString*)symbol renderedInformation:(NSDictionary**)outRenderedInformation;
-(NSData*) pdfDataForTexSymbol:(NSString*)symbol;

@end

NS_ASSUME_NONNULL_END
