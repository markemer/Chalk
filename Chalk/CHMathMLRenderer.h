//
//  CHMathMLRenderer.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "CHChalkTypes.h"
#import "CHWebView.h"

@class CHMathMLRenderer;

@protocol CHMathMLRendererDelegate

@required
-(void) mathMLRenderer:(CHMathMLRenderer*)renderer didEndRender:(chalk_export_format_t)format;

@end

@interface CHMathMLRenderer : NSObject <CHWebViewDelegate> {
  CHWebView* _webView;
  BOOL isMathjaxLoaded;
  BOOL isFrameLoaded;
  chalk_export_format_t nextFormat;
  BOOL nextFeedPasteboard;
  NSData*   lastMetadata;
  NSString* lastErrorString;
  NSString* lastResultString;
  NSString* lastMathMLString;
}

+(NSData*) metadataFromInputString:(NSString*)inputString foregroundColor:(NSColor*)foregroundColor;

@property(assign) id<CHMathMLRendererDelegate> delegate;
@property(copy,readonly) NSString* lastErrorString;
@property(copy,readonly) NSString* lastResultString;
@property(copy,readonly) NSString* lastMathMLString;

-(void) render:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard;

@end
