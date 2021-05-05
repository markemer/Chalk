//
//  CHWebView.m
//  Chalk
//
//  Created by Pierre Chatelier on 13/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHWebView.h"

#import "CHUtils.h"
#import "NSObjectExtended.h"

@protocol WebDynamicScrollBarsViewProtocol
-(void) setAllowsScrollersToOverlapContent:(BOOL)value;
@end

@implementation CHWebView

@dynamic useWKView;
@dynamic webView;
@dynamic URL;
@synthesize webDelegate;

-(nullable instancetype) initWithFrame:(NSRect)frameRect createSubViews:(BOOL)createSubViews
{
  if (!((self = [super initWithFrame:frameRect])))
    return nil;
  self->jsMessageHandlers = [[NSMutableDictionary alloc] init];
  if (createSubViews)
    [self createSubviews];
  return self;
}
//end initWithFrame:createSubViews:

-(instancetype) initWithFrame:(NSRect)frameRect
{
  return [self initWithFrame:frameRect createSubViews:NO];
}
//end initWithFrame:

-(instancetype) initWithCoder:(NSCoder*)coder
{
  if (!((self = [super initWithCoder:coder])))
    return nil;
  self->jsMessageHandlers = [[NSMutableDictionary alloc] init];
  return self;
}
//end initWithCoder:

-(void) dealloc
{
  self.webDelegate = nil;
  [self->jsMessageHandlers release];
  [self->webView removeFromSuperview];
  [self->wkWebView removeFromSuperview];
  [self->webView release];
  [self->wkWebView release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  [self createSubviews];
}
//end awakeFromNib

-(BOOL) isOpaque
{
  return YES;
}
//end isOpaque

-(BOOL) performKeyEquivalent:(NSEvent*)event
{
  BOOL result =
    self.useWKView ? [self->wkWebView performKeyEquivalent:event] :
    [self->webView performKeyEquivalent:event];
  return result;
}
//end performKeyEquivalent:

-(BOOL) useWKView
{
  BOOL result = NO;//isMacOS10_12OrAbove();
  return result;
}
//end useWKView

-(WebView*) webView
{
  return [[self->webView retain] autorelease];
}
//end webView

-(void) setWebView:(WebView*)value
{
  if (value != webView)
  {
    [self->webView removeFromSuperview];
    self->webView = [value retain];
    self->webView.autoresizingMask =  self.autoresizingMask;
    self->webView.frameLoadDelegate = self;
    self->webView.resourceLoadDelegate = self;
    self->webView.drawsBackground = NO;
    self->webView.shouldUpdateWhileOffscreen = YES;
    if (self->webView)
      [self addSubview:self->webView];
  }//end if (value != webView)
}
//end webView

-(void) createSubviews
{
  if (self.useWKView)
  {
    WKPreferences* preferences = [[[WKPreferences alloc] init] autorelease];
    [preferences setJavaScriptEnabled:YES];
    WKWebViewConfiguration* configuration = [[[WKWebViewConfiguration alloc] init] autorelease];
    [configuration setPreferences:preferences];
    configuration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    self->wkWebView = [[WKWebView alloc] initWithFrame:NSRectFromCGRect(self.bounds) configuration:configuration];
    self->wkWebView.autoresizingMask =  self.autoresizingMask;
    self->wkWebView.navigationDelegate = self;
    [self addSubview:self->wkWebView];
  }//end if (self.useWKView)
  else//if (!self.useWKView)
  {
    self->webView = [[WebView alloc] initWithFrame:NSRectFromCGRect(self.bounds) frameName:[NSString stringWithFormat:@"%p",self] groupName:[NSString stringWithFormat:@"%p",self]];
    WebPreferences* preferences = [self->webView preferences];
    preferences.javaEnabled = NO;
    preferences.javaScriptEnabled = YES;
    preferences.javaScriptCanOpenWindowsAutomatically = NO;
    self->webView.autoresizingMask =  self.autoresizingMask;
    self->webView.frameLoadDelegate = self;
    self->webView.resourceLoadDelegate = self;
    self->webView.drawsBackground = NO;
    self->webView.shouldUpdateWhileOffscreen = YES;
    [self addSubview:self->webView];
  }//end if (self.useWKView)
}
//end createSubviews

-(NSURL*) URL
{
  NSURL* result =
    (self->wkWebView != nil) ? self->wkWebView.URL :
    (self->webView != nil) ? [NSURL URLWithString:self->webView.mainFrameURL] :
    nil;
  return result;
}
//end URL

-(void) setURL:(NSURL*)value
{
  if (self->wkWebView != nil)
    [self->wkWebView loadRequest:[NSURLRequest requestWithURL:value cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:0]];
  else if (self->webView != nil)
    self->webView.mainFrameURL = [value path];
}
//end setURL:

-(void) setScrollerElasticity:(NSScrollElasticity)scrollElasticity
{
  if (self->webView != nil)
  {
    WebFrameView* frameView = self->webView.mainFrame.frameView;
    NSView* documentView = frameView.documentView;
    NSScrollView* scrollView = documentView.enclosingScrollView;
    id WebDynamicScrollBarsViewClass = NSClassFromString(@"WebDynamicScrollBarsView");
    id dynamicScrollBarsView = [scrollView dynamicCastToClass:WebDynamicScrollBarsViewClass];
    scrollView.horizontalScrollElasticity = NSScrollElasticityNone;
    scrollView.verticalScrollElasticity = NSScrollElasticityNone;
    scrollView.scrollerStyle = NSScrollerStyleLegacy;
    if ([dynamicScrollBarsView respondsToSelector:@selector(setAllowsScrollersToOverlapContent:)])
      [(id<WebDynamicScrollBarsViewProtocol>)dynamicScrollBarsView setAllowsScrollersToOverlapContent:NO];
  }//end if (self->webView != nil)
  else if (self->wkWebView)
  {
  }//end if (self->wkWebView)
}
//end setScrollerElasticity::

-(_Nullable id) evaluateJavaScript:(nonnull NSString*)jsCode
{
  __block id result = nil;
  if (self->wkWebView)
    [self->wkWebView evaluateJavaScript:jsCode completionHandler:^(id _Nullable localResult, NSError * _Nullable error) {
      result = [[localResult retain] autorelease];}];
  else if (self->webView)
    result = [self->webView.windowScriptObject evaluateWebScript:jsCode];
  return result;
}
//end evaluateJavaScript:

-(void) setExternalObject:(id)object forJSKey:(NSString*)key
{
  id previousMessageHandler = [self->jsMessageHandlers objectForKey:key];
  BOOL messageHandlerWillChange = (object != previousMessageHandler);
  if (!object)
    [self->jsMessageHandlers removeObjectForKey:key];
  else
    [self->jsMessageHandlers setObject:object forKey:key];
  if (!messageHandlerWillChange){
  }//end if (!messageHandlerWillChange)
  else if (self->webView)
  {
    id windowScriptObject = self->webView.windowScriptObject;
    [windowScriptObject setValue:object forKey:key];
  }//end if (self->webView)
  else if (self->wkWebView)
  {
    NSURL* url = self->wkWebView.URL;
    [self->wkWebView removeFromSuperview];
    [self->wkWebView release];
    WKWebViewConfiguration* configuration = [[[WKWebViewConfiguration alloc] init] autorelease];
    WKUserContentController* userContentController = [[[WKUserContentController alloc] init] autorelease];
    if (object)
      [userContentController addScriptMessageHandler:self name:key];
    configuration.userContentController = userContentController;
    WKPreferences* preferences = [[[WKPreferences alloc] init] autorelease];
    [preferences setJavaScriptEnabled:YES];
    [configuration setPreferences:preferences];
    self->wkWebView = [[WKWebView alloc] initWithFrame:NSRectFromCGRect(self.bounds) configuration:configuration];
    self->wkWebView.autoresizingMask = self.autoresizingMask;
    self->wkWebView.navigationDelegate = self;
    [self addSubview:self->wkWebView];
    [self->wkWebView loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:0]];
  }//end if (self->wkWebView && messageHandlerWillChange
}
//end setExternalObject:forJSKey:

-(_Nullable id) evaluateJavaScriptFunction:(nonnull NSString*)function withJSONArguments:(nullable NSArray*)jsonArguments wait:(BOOL)wait
{
  __block id result = nil;
  if (self->wkWebView)
  {
    NSError* error = nil;
    NSData* jsonArgumentsData = !jsonArguments ? nil :
      [NSJSONSerialization dataWithJSONObject:jsonArguments options:0 error:&error];
    if (error)
      DebugLog(0, @"error = %@", error);
    NSString* jsonArgumentsString = !jsonArgumentsData ? nil :
      [[[NSString alloc] initWithData:jsonArgumentsData encoding:NSUTF8StringEncoding] autorelease];
    NSString* jsCall = [NSString stringWithFormat:@"%@(%@)", function, !jsonArgumentsString ? @"" : jsonArgumentsString];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [self->wkWebView evaluateJavaScript:jsCall completionHandler:^(id _Nullable localResult, NSError * _Nullable error) {
      result = [localResult retain];
      dispatch_semaphore_signal(sem);
    }];
    BOOL success = NO;
    while(wait && !success)
    {
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[[NSDate date] dateByAddingTimeInterval:.01]];
      success = !dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 1000000000ULL/100));
    }//end while(!done)
    [result autorelease];
  }//end if (self->wkWebView)
  else if (self->webView)
  {
    NSArray* args = !jsonArguments ? nil : @[jsonArguments];
    result = [self->webView.windowScriptObject callWebScriptMethod:function withArguments:args];
  }//end if (self->webView)
  return result;
}
//end evaluateJavaScriptFunction:withJSONArguments:wait:

-(void) webView:(WebView*)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(WebFrame*)frame
{
  [self.webDelegate jsDidLoad:self];
}
//end webView:didCreateJavaScriptContext:forFrame:

-(void) webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame
{
  [self.webDelegate webviewDidLoad:self];
}
//end webView:didFinishLoadForFrame:

-(NSURLRequest*) webView:(WebView*)sender resource:(id)identifier willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirectResponse fromDataSource:(WebDataSource*)dataSource
{
  NSURLRequest* result = [NSURLRequest requestWithURL:[request URL] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:[request timeoutInterval]];
  [[NSURLCache sharedURLCache] removeCachedResponseForRequest:result];
  return result;
}
//end webView:resource:willSendRequest:redirectResponse:fromDataSource:

-(void) webView:(WebView*)sender didStartProvisionalLoadForFrame:(WebFrame*)frame
{
  WebScriptObject* wobj = sender.windowScriptObject;
  dispatch_async(dispatch_get_main_queue(), ^{
      [wobj evaluateWebScript:[NSString stringWithFormat:@"document.__defineGetter__('cookie', function(){ return %@.getCookie();})", @"CHALKWEBVIEW"]];
      [wobj evaluateWebScript:[NSString stringWithFormat:@"document.__defineSetter__('cookie', function(v) { return %@.setCookie(v);})", @"CHALKWEBVIEW"]];
  });
}
//end webView:didStartProvisionalLoadForFrame:

-(void) webView:(WKWebView*)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
  [self.webDelegate jsDidLoad:self];
  [self.webDelegate webviewDidLoad:self];
}
//end webView:didFinishNavigation:

-(void) userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
  id object = [self->jsMessageHandlers objectForKey:message.name];
  id body = message.body;
  NSArray* jsonArray = [body dynamicCastToClass:[NSArray class]];
  NSUInteger count = jsonArray.count;
  NSString* selectorName = [[jsonArray.firstObject dynamicCastToClass:[NSString class]] stringByReplacingOccurrencesOfString:@"_" withString:@":"];
  NSArray* arguments = (count <= 1) ? nil : [jsonArray subarrayWithRange:NSMakeRange(1, count-1)];
  SEL selector = NSSelectorFromString(selectorName);
  if ([object respondsToSelector:selector])
    [object performSelector:selector withArguments:arguments];
  else if ([selectorName isEqualToString:@"console"])
    DebugLog(1, @"webkit.console => <%@>", body);
}
//end userContentController:didReceiveScriptMessage:

@end
