//
//  CHEquationImageView.m
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//
#import "CHEquationImageView.h"

#import "CHAppDelegate.h"
#import "CHDragFilterWindowController.h"
#import "CHEquationDocument.h"
#import "CHPreferencesController.h"
#import "CHUtils.h"

#import "NSFileManagerExtended.h"
#import "NSImageExtended.h"
#import "NSMenuExtended.h"
#import "NSObjectExtended.h"

NSString* CHCopyCurrentImageNotification = @"CHCopyCurrentImageNotification";
NSString* CHImageDidChangeNotification = @"CHImageDidChangeNotification";

@interface CHEquationImageView (PrivateAPI)
-(NSMenu*) lazyCopyAsContextualMenu;
-(void) _copyCurrentImageNotification:(NSNotification*)notification;
-(BOOL) copyToPasteboard:(NSPasteboard*)pasteboard format:(chalk_export_format_t)format;
-(BOOL) pasteFromPasteboard:(NSPasteboard*)pasteboard;
@end

@implementation CHEquationImageView

@synthesize document;
@synthesize pdfData;
@synthesize svgString;
@synthesize mathMLString;

-(id) initWithCoder:(NSCoder*)coder
{
  if ((!(self = [super initWithCoder:coder])))
    return nil;
  [self lazyCopyAsContextualMenu];
  [self setMenu:self->copyAsContextualMenu];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_copyCurrentImageNotification:)
                                               name:CHCopyCurrentImageNotification object:nil];
  return self;
}
//end initWithCoder:

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->dragginSession release];
  [self->copyAsContextualMenu release];
  [self->svgString release];
  [self->mathMLString release];
  [self->pdfData release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  [self registerForDraggedTypes:@[(NSString*)kUTTypePDF, NSURLPboardType, @"public.file-url", NSFilenamesPboardType,(NSString*)kPasteboardTypeFilePromiseContent]];
}
//end awakeFromNib

-(NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
  NSDragOperation result = NSDragOperationCopy;
  return result;
}
//end draggingEntered:

-(BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
  BOOL result = NO;
  NSPasteboard* pasteboard = sender.draggingPasteboard;
  result = [self pasteFromPasteboard:pasteboard];
  return result;
}
//end performDragOperation:

-(BOOL) copyToPasteboard:(NSPasteboard*)pasteboard format:(chalk_export_format_t)format
{
  BOOL result = NO;
  if ((format == CHALK_EXPORT_FORMAT_UNDEFINED) || (format == CHALK_EXPORT_FORMAT_PDF))
  {
    if (self->pdfData)
    {
      [pasteboard declareTypes:@[(NSString*)kUTTypePDF] owner:nil];
      [pasteboard setData:self->pdfData forType:(NSString*)kUTTypePDF];
      result = YES;
    }//end if (self->pdfData)
  }//end if (format == CHALK_EXPORT_FORMAT_PDF)
  else if (format == CHALK_EXPORT_FORMAT_SVG)
  {
    if (self->svgString)
    {
      [pasteboard declareTypes:@[@"public.svg-image", NSStringPboardType] owner:nil];
      [pasteboard setString:self->svgString forType:@"public.svg-image"];
      [pasteboard setString:self->svgString forType:NSStringPboardType];
      result = YES;
    }//end if (self->svgString)
  }//end if (format == CHALK_EXPORT_FORMAT_SVG)
  else if (format == CHALK_EXPORT_FORMAT_MATHML)
  {
    if (self->mathMLString)
    {
      [pasteboard declareTypes:@[@"public.text", NSStringPboardType] owner:nil];
      [pasteboard setString:self->mathMLString forType:@"public.text"];
      [pasteboard setString:self->mathMLString forType:NSStringPboardType];
      result = YES;
    }//end if (self->mathMLString)
  }//end if (format == CHALK_EXPORT_FORMAT_MATHML)
  return result;
}
//end copyToPasteboard:format:

-(BOOL) pasteFromPasteboard:(NSPasteboard*)pasteboard
{
  BOOL result = NO;
  NSData* draggedPdfData =
    [pasteboard availableTypeFromArray:@[(NSString*)kUTTypePDF]] ? [pasteboard dataForType:(NSString*)kUTTypePDF] :
    [pasteboard availableTypeFromArray:@[NSURLPboardType, @"public.file-url"]] ? [NSData dataWithContentsOfURL:[NSURL URLFromPasteboard:pasteboard]] :
    nil;
  if (!draggedPdfData && [pasteboard availableTypeFromArray:@[NSFilenamesPboardType]])
  {
    NSArray* filenames = [[pasteboard propertyListForType:NSFilenamesPboardType] dynamicCastToClass:[NSArray class]];
    NSString* filePath = [filenames.firstObject dynamicCastToClass:[NSString class]];
    draggedPdfData = !filePath ? nil : [NSData dataWithContentsOfFile:filePath];
  }//end if (!draggedPdfData && [pasteboard availableTypeFromArray:@[NSFilenamesPboardType]])
  if (!draggedPdfData && [pasteboard availableTypeFromArray:@[(NSString*)kPasteboardTypeFilePromiseContent]])
  {
    NSString* uti = [[pasteboard propertyListForType:(NSString*)kPasteboardTypeFilePromiseContent] dynamicCastToClass:[NSString class]];
    if (UTTypeConformsTo((CFStringRef)uti, kUTTypePDF))
    {
      PasteboardRef cfPBoardRef = 0;
      PasteboardCreate((CFStringRef)pasteboard.name, &cfPBoardRef);
      NSURL* fileURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
      PasteboardSetPasteLocation(cfPBoardRef, (CFURLRef)fileURL);
      NSString* filePath2 = [[pasteboard propertyListForType:(NSString*)kPasteboardTypeFileURLPromise] dynamicCastToClass:[NSString class]];
      draggedPdfData = !filePath2 ? nil : [NSData dataWithContentsOfFile:filePath2];
      if (draggedPdfData)
      {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath2 error:&error];
      }//end if (draggedPdfData)
    }//end if (UTTypeConformsTo((CFStringRef)uti, kUTTypePDF))
  }//end if (!draggedPdfData && [pasteboard availableTypeFromArray:@[(NSString*)kPasteboardTypeFilePromiseContent]])
  [pasteboard dataForType:(NSString*)kUTTypePDF];
  result = [self->document applyState:draggedPdfData];
  return result;
}
//end pasteFromPasteboard:

-(BOOL) acceptsFirstMouse:(NSEvent*)theEvent//we can start a drag without selecting the window first
{
  return YES;
}
//end acceptsFirstMouse

-(NSMenu*) lazyCopyAsContextualMenu
{
  //connect contextual copy As menu to imageView
  NSMenu* result = self->copyAsContextualMenu;
  if (!result)
  {
    self->copyAsContextualMenu = [[NSMenu alloc] init];
    NSMenuItem* superItem =
      [self->copyAsContextualMenu addItemWithTitle:NSLocalizedString(@"Copy the image as", @"Copy the image as") action:nil keyEquivalent:@""];
    NSMenu* subMenu = [[NSMenu alloc] init];
    [subMenu addItemWithTitle:@"PDF" target:self action:@selector(copy:) keyEquivalent:@"" keyEquivalentModifierMask:0
                          tag:CHALK_EXPORT_FORMAT_PDF];
    [subMenu addItemWithTitle:@"SVG" target:self action:@selector(copy:) keyEquivalent:@"" keyEquivalentModifierMask:0
                          tag:CHALK_EXPORT_FORMAT_SVG];
    [subMenu addItemWithTitle:@"MathML" target:self action:@selector(copy:) keyEquivalent:@"" keyEquivalentModifierMask:0
                          tag:CHALK_EXPORT_FORMAT_MATHML];
    [self->copyAsContextualMenu setSubmenu:subMenu forItem:superItem];
    [subMenu release];
    result = self->copyAsContextualMenu;
  }//end if (!result)
  return result;
}
//end lazyCopyAsContextualMenu

-(void) setImage:(NSImage*)image
{
  [super setImage:image];
  [[NSNotificationCenter defaultCenter] postNotificationName:CHImageDidChangeNotification object:self];
}
//end setImage:

-(NSDragOperation) draggingSession:(NSDraggingSession*)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
  NSDragOperation result = !self.image ? NSDragOperationNone : NSDragOperationCopy;
  return result;
}
//end draggingSession:sourceOperationMaskForDraggingContext:

//begins a drag operation
-(void) mouseDown:(NSEvent*)theEvent
{
  if ([theEvent modifierFlags] & NSControlKeyMask)
    [super mouseDown:theEvent];
  else
    [super mouseDown:theEvent];
}
//end mouseDown:

-(void) mouseDragged:(NSEvent*)event
{
  if (!self->isDragging && !([event modifierFlags] & NSControlKeyMask))
  {
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    chalk_export_format_t exportFormat = preferencesController.exportFormatCurrentSession;
    if (exportFormat == CHALK_EXPORT_FORMAT_UNDEFINED)
      exportFormat = CHALK_EXPORT_FORMAT_PDF;
    preferencesController.exportFormatCurrentSession = exportFormat;

    NSImage* draggedImage = [self image];
    if (draggedImage)
    {
      self->isDragging = YES;
      NSDraggingItem* draggingItem = [[[NSDraggingItem alloc] initWithPasteboardWriter:self] autorelease];
      NSArray* (^draggingImageComponentsProvider)(void) = ^ {
        NSDraggingImageComponent* draggingImageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSStringFromClass([self class])];
        draggingImageComponent.contents = self.image;
        NSSize imageSize = self.image.size;
        NSRect frame = NSMakeRect(0, 0, imageSize.width, imageSize.height);
        frame.origin.x += (self.bounds.size.width-imageSize.width)/2;
        frame.origin.y += (self.bounds.size.height-imageSize.height)/2;
        draggingImageComponent.frame = frame;
        return @[draggingImageComponent];
      };
      draggingItem.imageComponentsProvider = draggingImageComponentsProvider;
      NSSize imageSize = self.image.size;
      draggingItem.draggingFrame = NSMakeRect(0, 0, imageSize.width, imageSize.height);
      [self beginDraggingSessionWithItems:@[draggingItem] event:event source:self];
      self->isDragging = NO;
    }//end if (draggedImage)
  }//end if (!self->isDragging)
  [super mouseDragged:event];
}
//end mouseDragged:

-(void) mouseUp:(NSEvent*)theEvent
{
  self->isDragging = NO;
  [super mouseUp:theEvent];
}
//end mouseUp:

-(NSDraggingSession*) beginDraggingSessionWithItems:(NSArray*)items event:(NSEvent*)event source:(id<NSDraggingSource>)source
{
  NSDraggingSession* result = nil;

  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t exportFormat = preferencesController.exportFormatCurrentSession;
  if (exportFormat == CHALK_EXPORT_FORMAT_UNDEFINED)
    exportFormat = CHALK_EXPORT_FORMAT_PDF;
  preferencesController.exportFormatCurrentSession = exportFormat;

  result = [super beginDraggingSessionWithItems:items event:event source:source];
  [self->dragginSession release];
  self->dragginSession = [result retain];

  [self dragFilterWindowController:nil exportFormatDidChange:exportFormat];
  
  return result;
}
//end beginDraggingSessionWithItems:event:source

-(void) draggingSession:(NSDraggingSession*)session willBeginAtPoint:(NSPoint)screenPoint
{
  CHDragFilterWindowController* dragFilterWindowController = [CHAppDelegate appDelegate].dragFilterWindowController;
  [dragFilterWindowController setWindowVisible:YES withAnimation:YES atPoint:screenPoint];
  dragFilterWindowController.window.ignoresMouseEvents = NO;
  dragFilterWindowController.delegate = self;
}
//end draggingSession:willBeginAtPoint:

-(void) draggingSession:(NSDraggingSession*)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
  CHDragFilterWindowController* dragFilterWindowController = [CHAppDelegate appDelegate].dragFilterWindowController;
  [dragFilterWindowController setWindowVisible:NO withAnimation:YES atPoint:screenPoint];
  dragFilterWindowController.window.ignoresMouseEvents = YES;
  dragFilterWindowController.delegate = nil;
  [self->dragginSession release];
  self->dragginSession = nil;
}
//end draggingSession:endedAtPoint:

-(NSArray*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  NSArray* result = nil;
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t exportFormat = preferencesController.exportFormatCurrentSession;
  NSMutableArray* types = [NSMutableArray arrayWithArray:@[CHChalkPBoardType]];
  if (exportFormat == CHALK_EXPORT_FORMAT_PDF)
    [types addObject:(NSString*)kUTTypePDF];
  else if (exportFormat == CHALK_EXPORT_FORMAT_SVG)
    [types addObjectsFromArray:@[@"public.svg-image", @"public.text"]];
  else if (exportFormat == CHALK_EXPORT_FORMAT_MATHML)
    [types addObjectsFromArray:@[@"public.text"]];
  [types addObject:(NSString*)kPasteboardTypeFileURLPromise];
  result = [[types copy] autorelease];
  return result;
}
//end writableTypesForPasteboard:

-(id) pasteboardPropertyListForType:(NSString*)type
{
  id result = nil;
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t exportFormat = preferencesController.exportFormatCurrentSession;
  if ([type isEqualToString:CHChalkPBoardType])
    result = @"";
  else if ([type isEqualToString:(NSString*)kUTTypePDF])
    result = [[self->pdfData copy] autorelease];
  else if ([type isEqualToString:@"public.svg-image"])
    result = [[self->svgString copy] autorelease];
  else if ([type isEqualToString:NSStringPboardType] || [type isEqualToString:@"public.text"])
  {
    if (exportFormat == CHALK_EXPORT_FORMAT_SVG)
      result = [[self->svgString copy] autorelease];
    else if (exportFormat == CHALK_EXPORT_FORMAT_MATHML)
      result = [[self->mathMLString copy] autorelease];
  }//end if ([type isEqualToString:NSStringPboardType])
  else if ([type isEqualToString:(NSString*)kPasteboardTypeFileURLPromise])
    result = nil;
  else
    result = nil;
  return result;
}
//end pasteboardPropertyListForType:

-(void) dragFilterWindowController:(CHDragFilterWindowController*)dragFilterWindowController exportFormatDidChange:(chalk_export_format_t)exportFormat
{
  NSPasteboard* pasteboard = self->dragginSession.draggingPasteboard;
  NSMutableArray* types = [NSMutableArray arrayWithArray:@[CHChalkPBoardType]];
  if (exportFormat == CHALK_EXPORT_FORMAT_PDF)
    [types addObject:(NSString*)kUTTypePDF];
  else if (exportFormat == CHALK_EXPORT_FORMAT_SVG)
    [types addObjectsFromArray:@[@"public.svg-image", NSStringPboardType]];
  else if (exportFormat == CHALK_EXPORT_FORMAT_MATHML)
    [types addObjectsFromArray:@[@"public.text", NSStringPboardType]];
  [types addObject:(NSString*)kPasteboardTypeFileURLPromise];
  [pasteboard declareTypes:types owner:self];
}
//end dragFilterWindowController:exportFormatDidChange:

-(void) pasteboard:(NSPasteboard*)pasteboard provideDataForType:(NSString*)type
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t exportFormat = preferencesController.exportFormatCurrentSession;
  NSData* data =
    (exportFormat == CHALK_EXPORT_FORMAT_PDF) ? self.pdfData :
    (exportFormat == CHALK_EXPORT_FORMAT_SVG) ? [self.svgString dataUsingEncoding:NSUTF8StringEncoding] :
    (exportFormat == CHALK_EXPORT_FORMAT_MATHML) ? [self.mathMLString dataUsingEncoding:NSUTF8StringEncoding] :
    nil;
  if ([type isEqualToString:(NSString*)kPasteboardTypeFileURLPromise])
  {
    CFURLRef cfDropPath = 0;
    PasteboardRef cfPBoardRef = 0;
    PasteboardCreate((CFStringRef)pasteboard.name, &cfPBoardRef);
    PasteboardCopyPasteLocation(cfPBoardRef, &cfDropPath);
    NSURL* dropPathURL = (NSURL*)cfDropPath;
    NSString* dropPath = !dropPathURL ? nil : [NSString stringWithUTF8String:dropPathURL.filePathURL.fileSystemRepresentation];
    [dropPathURL autorelease];
    if (cfPBoardRef)
      CFRelease(cfPBoardRef);

    NSString* extension = nil;
    NSString* uti = nil;
    switch(exportFormat)
    {
      case CHALK_EXPORT_FORMAT_PDF:
        extension = @"pdf";
        uti = @"com.adobe.pdf";
        break;
      case CHALK_EXPORT_FORMAT_SVG:
        extension = @"svg";
        uti = @"public.svg-image";
        break;
      case CHALK_EXPORT_FORMAT_MATHML:
        extension = @"mml";
        uti = @"public.text";
        break;
      default:
        break;
    }//end switch(exportFormat)
    NSString* filePrefix = @"chalk";
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filePath = !dropPath ? nil : [fileManager getUnusedFilePathFromPrefix:filePrefix extension:extension folder:dropPath startSuffix:0];
    if (filePath && ![fileManager fileExistsAtPath:filePath])
      [fileManager createFileAtPath:filePath contents:data attributes:nil];
  }//end if ([type isEqualToString:(NSString*)kPasteboardTypeFileURLPromise])
  else
    [pasteboard setData:data forType:type];
}
//end pasteboard:provideDataForType:

-(BOOL) validateMenuItem:(id)sender
{
  BOOL ok = YES;
  if ([sender action] == @selector(copy:))
    ok = ok && (self.image != nil);
  return ok;
}
//end validateMenuItem:

-(IBAction) copy:(id)sender
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  NSInteger tag = sender ? [sender tag] : -1;
  chalk_export_format_t copyExportFormat = (tag == -1) ? preferencesController.exportFormatCurrentSession : (chalk_export_format_t)tag;
  [self copyAsFormat:copyExportFormat];
}
//end copy:

-(void) copyAsFormat:(chalk_export_format_t)copyExportFormat
{
  NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t oldExportFormat = preferencesController.exportFormatCurrentSession;
  preferencesController.exportFormatCurrentSession = copyExportFormat;
  [self copyToPasteboard:pasteboard format:copyExportFormat];
  preferencesController.exportFormatCurrentSession = oldExportFormat;
}
//end copyAsFormat:

-(IBAction) paste:(id)sender
{
  [self pasteFromPasteboard:[NSPasteboard generalPasteboard]];
}
//end paste:

-(BOOL) pasteDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard
{
  BOOL result = [self pasteFromPasteboard:pasteboard];
  return result;
}
//end pasteDelegated:pasteboard:

-(BOOL) copyDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard
{
  BOOL result = YES;
  //CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_export_format_t exportFormat = CHALK_EXPORT_FORMAT_PDF;
  [self copyToPasteboard:pasteboard format:exportFormat];
  return result;
}
//end copyDelegated:pasteboard:

-(void) _copyCurrentImageNotification:(NSNotification*)notification
{
  [self copy:self];
}
//end _copyCurrentImageNotification:

@end
