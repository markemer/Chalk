//
//  CHSVGRenderer.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/05/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHSVGRenderer.h"

#import "CHUtils.h"
#import "IJSVG.h"

#import "NSColorExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

static void myPDFApplierFunction(const char *key, CGPDFObjectRef value, void *info)
{
  DebugLogStatic(1, @"PDF contains key %s", key);
}
//end myPDFApplierFunction

@interface CHSVGRenderer ()

-(void) jsConsoleLog:(NSString*)message;
-(void) mathjaxDidFinishLoading;
-(void) mathjaxDidEndTypesetting:(NSString*)svgOutput;
-(void) mathjaxReportedError:(NSString*)svgOutput;
-(NSData*) pdfDataFromSVGString:(NSString*)svgString metadata:(NSData*)metadata;

@end

@implementation CHSVGRenderer

@synthesize delegate;
@synthesize lastErrorString;
@synthesize lastResultString;
@synthesize lastSvgString;
@synthesize lastPDFData;

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
  DebugLog(0, @"jsConsoleLog : <%@>", message);
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
    NSArray* components = [string componentsMatchedByRegex:@"\\<svg ?.*>.*\\<\\/svg\\>" options:RKLDotAll|RKLMultiline|RKLCaseless range:string.range capture:0 error:&error];
    if (error)
      DebugLog(1, @"error = <%@>", error);
    NSMutableString* svgString = [NSMutableString stringWithString:@""];
    for(id component in components)
      [svgString appendString:component];
    
    [self->lastResultString release];
    self->lastResultString = [string copy];
    [self->lastSvgString release];
    self->lastSvgString = [svgString copy];
    [self->lastPDFData release];
    self->lastPDFData =
      (self->nextFormat == CHALK_EXPORT_FORMAT_PDF) ? [[self pdfDataFromSVGString:svgString metadata:self->lastMetadata] retain] : nil;

    if (self->nextFeedPasteboard)
    {
      NSMutableArray* types = [NSMutableArray array];
      if (self->nextFormat == CHALK_EXPORT_FORMAT_SVG)
        [types addObjectsFromArray:@[@"public.svg-image", NSPasteboardTypeString]];
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_PDF)
        [types addObject:NSPasteboardTypePDF];
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [types addObject:NSPasteboardTypeString];
      NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
      [pasteboard declareTypes:types owner:nil];
      if (self->nextFormat == CHALK_EXPORT_FORMAT_SVG)
      {
        [pasteboard setString:[[svgString copy] autorelease] forType:@"public.svg-image"];
        [pasteboard setString:[[svgString copy] autorelease] forType:NSPasteboardTypeString];
      }//end if (self->nextFormat == CHALK_EXPORT_FORMAT_SVG)
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_PDF)
        [pasteboard setData:[[self->lastPDFData copy] autorelease] forType:NSPasteboardTypePDF];
      else if (self->nextFormat == CHALK_EXPORT_FORMAT_STRING)
        [pasteboard setString:[[string copy] autorelease] forType:NSPasteboardTypeString];
    }//end if (self->nextFeedPasteboard)
    [self.delegate svgRenderer:self didEndRender:self->nextFormat];
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
    NSURL* webPageUrl = [[NSBundle mainBundle] URLForResource:@"svg-renderer" withExtension:@"html" subdirectory:@"Web"];
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
  [self->lastSvgString release];
  [self->lastPDFData release];
  [self->_webView setExternalObject:nil forJSKey:@"rendererDocument"];
  self->_webView.webDelegate = nil;
  [self->_webView release];
  [super dealloc];
}
//end dealloc

-(NSData*) lastPDFData
{
  NSData* result = nil;
  @synchronized(self)
  {
    result = self->lastPDFData;
    if (!result)
      result = [self pdfDataFromSVGString:self->lastSvgString metadata:self->lastMetadata];
     result = [[result copy] autorelease];
  }//end @synchronized(self)
  return result;
}
//end lastPDFData

-(void) webviewDidLoad:(CHWebView * _Nonnull)webview
{
  DebugLog(1, @"webviewDidLoad:");
  self->isFrameLoaded = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, webview.useWKView ? 0 : 1000000000Ull/10), dispatch_get_main_queue(), ^() {
    [webview evaluateJavaScriptFunction:@"configureMathJax" withJSONArguments:@[@"mathjax/current/tex-svg-full.js"] wait:NO];
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

-(NSData*) pdfDataFromSVGString:(NSString*)svgString metadata:(NSData*)metadata
{
  NSData* result = nil;
  if (svgString)
  {
    NSError* error = nil;
    IJSVG* ijSVG = [[IJSVG alloc] initWithSVGString:svgString error:&error];
    if (error)
      DebugLog(0, @"svg to pdf error : %@", error);
    NSRect viewRect = ijSVG.viewBox;
    CGSize proposedViewSize = ijSVG.viewBox.size;
    CGFloat scale = 1./10;
    proposedViewSize.width *= scale;
    proposedViewSize.height *= scale;
    NSMutableData* pdfData = [NSMutableData data];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfData);
    CGFloat scaleFactorX = !proposedViewSize.width || !viewRect.size.width ? 0 :
      ABS(proposedViewSize.width/viewRect.size.width);
    CGFloat scaleFactorY = !proposedViewSize.height || !viewRect.size.height ? 0 :
      ABS(proposedViewSize.height/viewRect.size.height);
    CGRect mediaBox = NSRectToCGRect(viewRect);
    mediaBox.origin.x = 0;
    mediaBox.origin.y = 0;
    if (scaleFactorX && scaleFactorY)
    {
      mediaBox.size.width *= scaleFactorX;
      mediaBox.size.height *= scaleFactorY;
    }//end if (scaleFactorX && scaleFactorY)
    CGContextRef cgContext = CGPDFContextCreate(dataConsumer, &mediaBox, 0);
    
    NSDictionary* metadataPlist = !metadata ? nil : @{@"Chalk":metadata};
    error = nil;
    NSData* medatataXML = !metadataPlist ? nil :
      [NSPropertyListSerialization dataWithPropertyList:metadataPlist format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (error)
      DebugLog(0, @"dataWithPropertyList error : %@", error);
    if (medatataXML)
      CGPDFContextAddDocumentMetadata(cgContext, (CFDataRef)medatataXML);
    CGPDFContextBeginPage(cgContext, 0);
    CGContextTranslateCTM(cgContext, 0, mediaBox.size.height);
    CGContextScaleCTM(cgContext, 1, -1);
    NSGraphicsContext* oldGraphicsContext = [[NSGraphicsContext currentContext] retain];
    NSGraphicsContext* newGraphicsContext = nil;
    if (isMacOS10_10OrAbove())
      newGraphicsContext = [NSGraphicsContext graphicsContextWithCGContext:cgContext flipped:NO];
    else
      newGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
    [NSGraphicsContext setCurrentContext:newGraphicsContext];
    [ijSVG drawInRect:mediaBox];
    [newGraphicsContext flushGraphics];
    [NSGraphicsContext setCurrentContext:oldGraphicsContext];
    [oldGraphicsContext release];
    CGPDFContextEndPage(cgContext);
    CGPDFContextClose(cgContext);
    CGContextRelease(cgContext);
    CGDataConsumerRelease(dataConsumer);
    [ijSVG release];
    result = [[pdfData copy] autorelease];
  }//end if (svgString)
  return result;
}
//end pdfDataFromSVGString:metadata:

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

+(NSDictionary*) chalkMetadataFromPDFData:(NSData*)pdfData
{
  NSDictionary* result = nil;
  CGDataProviderRef cgDataProvider = !pdfData ? 0 : CGDataProviderCreateWithCFData((CFDataRef)pdfData);
  CGPDFDocumentRef pdfDocument = !cgDataProvider ? 0 : CGPDFDocumentCreateWithProvider(cgDataProvider);
  CGPDFDictionaryRef pdfDict = !pdfDocument ? 0 : CGPDFDocumentGetCatalog(pdfDocument);
  CGPDFStreamRef pdfStream = 0;
  if (pdfDict && !pdfStream)
    CGPDFDictionaryGetStream(pdfDict, "Metadata", &pdfStream);
  if (pdfDict && !pdfStream)
    CGPDFDictionaryGetStream(pdfDict, "metadata", &pdfStream);
  if (pdfDict && !pdfStream)
    CGPDFDictionaryApplyFunction(pdfDict, myPDFApplierFunction, self);
  CGPDFDataFormat pdfDataFormat = CGPDFDataFormatRaw;
  CFDataRef pdfMetadata = !pdfStream ? 0 : CGPDFStreamCopyData(pdfStream, &pdfDataFormat);
  NSError* error = nil;
  NSPropertyListFormat plistFormat = NSPropertyListXMLFormat_v1_0;
  error = nil;
  id plist = !pdfMetadata ? nil :
    [NSPropertyListSerialization propertyListWithData:(NSData*)pdfMetadata options:NSPropertyListImmutable format:&plistFormat error:&error];
  if (error)
    DebugLog(0, @"propertyListWithData error : %@", error);
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSData* chalkData = [[[[dict objectForKey:@"Chalk"] dynamicCastToClass:[NSData class]] copy] autorelease];
  plistFormat = NSPropertyListXMLFormat_v1_0;
  error = nil;
  id chalkPlist = !chalkData ? nil :
    [NSPropertyListSerialization propertyListWithData:chalkData options:NSPropertyListImmutable format:&plistFormat error:&error];
  if (error)
    DebugLog(0, @"chalk propertyListWithData error : %@", error);
  result = [chalkPlist dynamicCastToClass:[NSDictionary class]];
  if (pdfMetadata)
    CFRelease(pdfMetadata);
  CGPDFDocumentRelease(pdfDocument);
  CGDataProviderRelease(cgDataProvider);
  return result;
}
//end chalkMetadataFromPDFData:

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

