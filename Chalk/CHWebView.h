//
//  CHWebView.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <WebKit/WebKit.h>

@class CHWebView;

@protocol CHWebViewDelegate
-(void) webviewDidLoad:(CHWebView * _Nonnull)webview;
-(void) jsDidLoad:(CHWebView* _Nonnull)webview;
@end

@interface CHWebView : NSView <WebFrameLoadDelegate, WebResourceLoadDelegate,
                               WKNavigationDelegate, WKScriptMessageHandler> {
  WebView* webView;
  WKWebView* wkWebView;
  NSMutableDictionary* jsMessageHandlers;
}

@property(readonly,nonatomic) BOOL useWKView;
@property(nullable,retain,nonatomic) WebView* webView;
@property(nullable,copy,nonatomic) NSURL* URL;
@property(nonatomic, assign, nullable, nonatomic) id<CHWebViewDelegate> webDelegate;
@property CGFloat fontSize;

-(nullable instancetype) initWithFrame:(NSRect)frameRect createSubViews:(BOOL)createSubViews;

-(void) setScrollerElasticity:(NSScrollElasticity)scrollElasticity;

-(_Nullable id) evaluateJavaScript:(nonnull NSString*)jsCode;
-(_Nullable id) evaluateJavaScriptFunction:(nonnull NSString*)function withJSONArguments:(nullable NSArray*)jsonArguments wait:(BOOL)wait;

-(void) setExternalObject:(_Nullable id)object forJSKey:(NSString* _Nonnull)key;

@end
