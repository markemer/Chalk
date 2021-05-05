//
//  CHMathMLRenderer.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHMathMLRenderer.h"

#import "CHUtils.h"

#import "NSColorExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@interface CHMathMLRenderer ()

-(void) jsConsoleLog:(NSString*)message;
-(void) mathjaxDidFinishLoading;
-(void) mathjaxDidEndTypesetting:(NSString*)mathMLOutput;
-(void) mathjaxReportedError:(NSString*)mathMLOutput;

@end

@implementation CHMathMLRenderer

@synthesize delegate;
@synthesize lastErrorString;
@synthesize lastResultString;
@synthesize lastMathMLString;

+(void) initialize
{
}
//end initialize:
 
+(BOOL) isSelectorExcludedFromWebScript:(SEL)sel
{
  BOOL result = YES;
  BOOL included =
    (sel == @selector(jsConsoleLog:)) ||
    (sel == @selector(mathjaxDidFinishLoading)) ||
    (sel == @selector(mathjaxDidEndTypesetting:)) ||
    (sel == @selector(mathjaxReportedError:));
  result = !included;
  return result;
}
//end isSelectorExcludedFromWebScript:

-(void) jsConsoleLog:(NSString*)message
{
  DebugLog(1, @"jsConsoleLog : <%@>", message);
}
//end jsConsoleLog:

-(void) mathjaxDidFinishLoading
{
  DebugLog(1, @"mathjaxDidFinishLoading");
  self->isMathjaxLoaded = YES;
}
//end mathjaxDidFinishLoading

-(void) mathjaxReportedError:(NSString*)string
{
  DebugLog(1, @"mathjaxReportedError:%@", string);
  @synchronized(self)
  {
    [self->lastErrorString release];
    self->lastErrorString = [[string stringByMatching:@"TeX Jax \\- parse error\\,?([^,]*),?.*" capture:1] copy];
    DebugLog(1, @"self->lastErrorString = <%@>", self->lastErrorString);
  }//end @synchronized(self)
}
//end mathjaxReportedError

-(void) mathjaxDidEndTypesetting:(NSString*)string
{
  @synchronized(self)
  {
    DebugLog(1, @"mathjaxDidEndTypesetting: %@", string);
    NSError* error = nil;
    NSArray* components = [string componentsMatchedByRegex:@"\\<math ?.*>.*\\<\\/math\\>" options:RKLDotAll|RKLMultiline|RKLCaseless range:string.range capture:0 error:&error];
    if (error)
      DebugLog(1, @"error = <%@>", error);
    NSMutableString* mathMLString = [NSMutableString stringWithString:@""];
    for(id component in components)
      [mathMLString appendString:component];
    
    [self->lastResultString release];
    self->lastResultString = [string copy];
    [self->lastMathMLString release];
    self->lastMathMLString = [mathMLString copy];

    if (self->nextFeedPasteboard)
    {
      NSMutableArray* types = [NSMutableArray array];
      if (self->nextFormat == CHALK_EXPORT_FORMAT_MATHML)
        [types addObjectsFromArray:@[@"public.text", NSPasteboardTypeString]];
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [types addObject:NSPasteboardTypeString];
      NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
      [pasteboard declareTypes:types owner:nil];
      if (self->nextFormat == CHALK_EXPORT_FORMAT_MATHML)
      {
        [pasteboard setString:[[mathMLString copy] autorelease] forType:@"public.text"];
        [pasteboard setString:[[mathMLString copy] autorelease] forType:NSPasteboardTypeString];
      }//end if (self->nextFormat == CHALK_EXPORT_FORMAT_MATHML)
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [pasteboard setString:[[string copy] autorelease] forType:NSPasteboardTypeString];
    }//end if (self->nextFeedPasteboard)
    [self.delegate mathMLRenderer:self didEndRender:self->nextFormat];
  }//end @synchronized(self)
}
//end mathjaxDidEndTypesetting:

-(id) init
{
  if (!((self = [super init])))
    return nil;
  self->_webView = [[CHWebView alloc] initWithFrame:NSZeroRect createSubViews:YES];
  [self->_webView setExternalObject:self forJSKey:@"rendererDocument"];
  self->_webView.webDelegate = self;
  if (!self->_webView.URL)
  {
    NSURLCache* sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL* webPageUrl = [[NSBundle mainBundle] URLForResource:@"mml-renderer" withExtension:@"html" subdirectory:@"Web"];
    @try{
      NSHTTPCookieStorage* cookieJar = !webPageUrl ? nil : [NSHTTPCookieStorage sharedHTTPCookieStorage];
      NSArray* cookies = [cookieJar cookiesForURL:[NSURL URLWithString:webPageUrl.absoluteString]];
      for(NSHTTPCookie* cookie in cookies)
        [cookieJar deleteCookie:cookie];
    }
    @catch(NSException* e){
      DebugLog(0, @"deleteCookie exception <%@>", e);
    }
    DebugLog(1, @"self->_webView.URL <= %@", webPageUrl);
    self->_webView.URL = webPageUrl;
  }//end if (!self->webView.URL)
  return self;
}
//end init

-(void) dealloc
{
  [self->lastMetadata release];
  [self->lastResultString release];
  [self->lastErrorString release];
  [self->lastMathMLString release];
  [self->_webView setExternalObject:nil forJSKey:@"rendererDocument"];
  self->_webView.webDelegate = nil;
  [self->_webView release];
  [super dealloc];
}
//end dealloc

-(void) webviewDidLoad:(CHWebView * _Nonnull)webview
{
  DebugLog(1, @"webviewDidLoad:");
  self->isFrameLoaded = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, webview.useWKView ? 0 : 1000000000Ull/10), dispatch_get_main_queue(), ^() {
    [webview evaluateJavaScriptFunction:@"configureMathJax" withJSONArguments:@[@"mathjax/current/tex-mml-chtml.js"] wait:NO];
  });
}
//end webviewDidLoad:

-(void) jsDidLoad:(CHWebView* _Nonnull)webview
{
  DebugLog(1, @"jsDidLoad");
  if (DebugLogLevel >= 1)
    [webview evaluateJavaScript:@"debugLogEnable([true,true])"];
  [webview setExternalObject:self forJSKey:@"rendererDocument"];
}
//end jsDidLoad:

+(NSData*) metadataFromInputString:(NSString*)inputString foregroundColor:(NSColor*)foregroundColor
{
  NSData* result = nil;
  NSMutableDictionary* dict = !inputString && !foregroundColor ? nil :
    [NSMutableDictionary dictionary];
  if (inputString)
    [dict setObject:inputString forKey:@"inputString"];
  NSData* foregroundColorAsData = [foregroundColor colorAsData];
  if (foregroundColorAsData)
    [dict setObject:foregroundColorAsData forKey:@"foregroundColor"];
  NSError* error = nil;
  result = !dict ? nil :
    [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
  if (error)
    DebugLog(0, @"error = <%@>", error);
  return result;
}
//end metadataFromString:foregroundColor:

-(void) render:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard
{
  if (!self->isMathjaxLoaded)
  {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100000000), dispatch_get_main_queue(), ^{
      [self render:[[string copy] autorelease] foregroundColor:foregroundColor format:format metadata:[[metadata copy] autorelease] feedPasteboard:feedPasteboard];
    });
  }//end if (!self->isMathjaxLoaded)
  else//if (self->isMathjaxLoaded)
  {
    @synchronized(self)
    {
      [self->lastMetadata release];
      self->lastMetadata = [metadata copy];
      [self->lastErrorString release];
      self->lastErrorString = nil;
      self->nextFeedPasteboard = feedPasteboard;
      self->nextFormat = format;
      if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [self mathjaxDidEndTypesetting:string];
      else if (self->nextFormat != CHALK_EXPORT_FORMAT_UNDEFINED)
      {
        BOOL ignoreColor = !foregroundColor ||
          [foregroundColor isEqualTo:[NSColor blackColor]] ||
          [foregroundColor isEqualTo:[NSColor clearColor]] ||
          [foregroundColor isRGBEqualTo:[NSColor blackColor]] ||
          [foregroundColor isRGBEqualTo:[NSColor clearColor]] ||
          (foregroundColor.alphaComponent == 0);
        NSColor* rgbaColor = ignoreColor ? nil :
          [foregroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        CGFloat rgba[4] = {0};
        [rgbaColor getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
        NSString* hexColorString = !rgbaColor ? nil :
          [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)(unsigned char)(255*rgba[0]),
            (int)(unsigned char)(255*rgba[1]),
            (int)(unsigned char)(255*rgba[2])];
        NSString* mathjaxTeXString = (hexColorString.length != 0) ?
          [NSString stringWithFormat:@"\\(\\color{%@}{%@}\\)", hexColorString, string] :
          [NSString stringWithFormat:@"\\(%@\\)", string];
        NSArray* args = !mathjaxTeXString ? nil : @[mathjaxTeXString];
        [self->_webView evaluateJavaScriptFunction:@"render" withJSONArguments:args wait:NO];
      }//end if (self->nextFormat != CHALK_EXPORT_FORMAT_UNDEFINED)
    }//end @synchronized(self)
  }//end if (self->isMathjaxLoaded)
}
//end render:foregroundColor:format:

@end

