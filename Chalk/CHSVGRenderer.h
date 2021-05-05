//
//  CHSVGRenderer.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
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
}

+(NSData*) metadataFromInputString:(NSString*)inputString foregroundColor:(NSColor*)foregroundColor;
+(NSDictionary*) chalkMetadataFromPDFData:(NSData*)pdfData;

@property(assign) id<CHSVGRendererDelegate> delegate;
@property(copy,readonly) NSString* lastErrorString;
@property(copy,readonly) NSString* lastResultString;
@property(copy,readonly) NSString* lastSvgString;
@property(copy,readonly) NSData*   lastPDFData;

-(void) render:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard;

@end
