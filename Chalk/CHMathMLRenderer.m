//
//  CHMathMLRenderer.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHMathMLRenderer.h"

#import "CHUtils.h"

#import "NSColorExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@interface CHMathMLRendererQueueItem : NSObject {
  NSString* string;
  NSColor* foregroundColor;
  chalk_export_format_t format;
  NSData* metadata;
  BOOL feedPasteboard;
}

@property(nonatomic,copy) NSString* string;
@property(nonatomic,copy) NSColor* foregroundColor;
@property(nonatomic)      chalk_export_format_t format;
@property(nonatomic,copy) NSData* metadata;
@property(nonatomic)      BOOL feedPasteboard;

+(instancetype) queueItemWithString:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard;
-(instancetype) initWithString:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard;
@end//CHMathMLRendererQueueItem

@implementation CHMathMLRendererQueueItem

@synthesize string;
@synthesize foregroundColor;
@synthesize format;
@synthesize metadata;
@synthesize feedPasteboard;

+(instancetype) queueItemWithString:(NSString*)string foregroundColor:(NSColor*)foregroundColor format:(chalk_export_format_t)format metadata:(NSData*)metadata feedPasteboard:(BOOL)feedPasteboard
{
  return [[[[self class] alloc] initWithString:string foregroundColor:foregroundColor format:format metadata:metadata feedPasteboard:feedPasteboard] autorelease];
}
//end queueItemWithString:foregroundColor:format:metadata:feedPasteboard:

-(instancetype) initWithString:(NSString*)aString foregroundColor:(NSColor*)aForegroundColor format:(chalk_export_format_t)aFormat metadata:(NSData*)aMetadata feedPasteboard:(BOOL)aFeedPasteboard
{
  if (!((self = [super init])))
    return self;
  self.string = aString;
  self.foregroundColor = aForegroundColor;
  self.format = aFormat;
  self.metadata = aMetadata;
  self.feedPasteboard = aFeedPasteboard;
  return self;
}
//end queueItemWithString:foregroundColor:format:metadata:feedPasteboard:

-(void) dealloc
{
  self.string = nil;
  self.foregroundColor = nil;
  self.metadata = nil;
  [super dealloc];
}
//end dealloc

@end//CHMathMLRendererQueueItem

@interface CHMathMLRenderer ()

-(void) jsConsoleLog:(NSString*)message;
-(void) mathjaxDidFinishLoading;
-(void) mathjaxDidEndTypesetting:(NSString*)mathMLOutput extraInformation:(id)extraInformation;
-(void) mathjaxReportedError:(NSString*)mathMLOutput;
-(void) processRenderQueue;

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
    (sel == @selector(mathjaxDidEndTypesetting:extraInformation:)) ||
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
  [self processRenderQueue];
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

-(void) mathjaxDidEndTypesetting:(NSString*)string extraInformation:(id)extraInformation
{
  @synchronized(self)
  {
    DebugLog(1, @"mathjaxDidEndTypesetting:%@ extraInformation:%@", string, extraInformation);
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
  [self processRenderQueue];
}
//end mathjaxDidEndTypesetting:extraInformation:

-(id) init
{
  if (!((self = [super init])))
    return nil;
  self->renderQueue = [[NSMutableArray alloc] init];
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
  [self->renderQueue release];
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
  CHMathMLRendererQueueItem* queueItem = [CHMathMLRendererQueueItem queueItemWithString:string foregroundColor:foregroundColor format:format metadata:metadata feedPasteboard:feedPasteboard];
  if (queueItem)
  {
    @synchronized(self->renderQueue)
    {
      [self->renderQueue addObject:queueItem];
    }
    if (self->isMathjaxLoaded)
      [self processRenderQueue];
  }//end if (queueItem)
}
//end render:foregroundColor:format:metadata:feedPasteboard:

-(void) processRenderQueue
{
  CHMathMLRendererQueueItem* queueItem = nil;
  @synchronized(self->renderQueue)
  {
    if (self->renderQueue.count)
    {
      queueItem = [[[self->renderQueue firstObject] retain] autorelease];
      [self->renderQueue removeObjectAtIndex:0];
    }//end if (self->renderQueue.count)
  }//end @synchronized(self->renderQueue)
  if (queueItem)
  {
    @synchronized(self)
    {
      [self->lastMetadata release];
      self->lastMetadata = [queueItem.metadata copy];
      [self->lastErrorString release];
      self->lastErrorString = nil;
      self->nextFeedPasteboard = queueItem.feedPasteboard;
      self->nextFormat = queueItem.format;
      if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [self mathjaxDidEndTypesetting:queueItem.string extraInformation:nil];
      else if (self->nextFormat != CHALK_EXPORT_FORMAT_UNDEFINED)
      {
        NSColor* foregroundColor = queueItem.foregroundColor;
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
          [NSString stringWithFormat:@"\\(\\color{%@}{%@}\\)", hexColorString, queueItem.string] :
          [NSString stringWithFormat:@"\\(%@\\)", queueItem.string];
        NSArray* args = !mathjaxTeXString ? nil : @[mathjaxTeXString];
        [self->_webView evaluateJavaScriptFunction:@"render" withJSONArguments:args wait:NO];
      }//end if (self->nextFormat != CHALK_EXPORT_FORMAT_UNDEFINED)
    }//end @synchronized(self)
  }//end if (self->isMathjaxLoaded)
}
//end render:foregroundColor:format:

@end

