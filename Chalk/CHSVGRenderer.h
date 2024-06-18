//
//  CHSVGRenderer.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "CHChalkTypes.h"
#import "CHWebView.h"

@class CHSVGRenderer;

@protocol CHSVGRendererDelegate

@required
-(void) svgRenderer:(CHSVGRenderer*)renderer didEndRender:(chalk_export_format_t)format;

@end

@interface CHSVGRenderer : NSObject <CHWebViewDelegate> {
  NSMutableArray* renderQueue;
  CHWebView* _webView;
  BOOL isMathjaxLoaded;
  BOOL isFrameLoaded;
  chalk_export_format_t nextFormat;
  BOOL nextFeedPasteboard;
  NSData*   lastMetadata;
  NSString* lastErrorString;
  NSString* lastResultString;
  NSString* lastSvgString;
  NSData*   lastPDFData;
  NSDictionary* lastRenderedInformation;
  CGFloat renderScale;
}
//end lastRenderedInformation

+(NSData*) metadataFromInputString:(NSString*)inputString foregroundColor:(NSColor*)foregroundColor;
+(NSDictionary*) chalkMetadataFromPDFData:(NSData*)pdfData;

@property(nonatomic,assign) id<CHSVGRendererDelegate> delegate;
@property(nonatomic,copy,readonly) NSString*     lastErrorString;
@property(nonatomic,copy,readonly) NSString*     lastResultString;
@property(nonatomic,copy,readonly) NSString*     lastSvgString;
@property(nonatomic,copy,readonly) NSData*       lastPDFData;
@property(nonatomic,copy,readonly) NSDictionary* lastRenderedInformation;
@property(nonatomic)               CGFloat       renderScale;

-(void) render:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard;

@end
