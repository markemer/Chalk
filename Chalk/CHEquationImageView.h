//  CHEquationImageView.h
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkTypes.h"

extern NSString* CHCopyCurrentImageNotification;
extern NSString* CHImageDidChangeNotification;

@class CHEquationDocument;

@interface CHEquationImageView : NSImageView <NSDraggingSource, NSPasteboardWriting, NSDraggingDestination, CHPasteboardDelegate> {
  NSData*     pdfData;
  NSString*   svgString;
  NSString*   mathMLString;
  NSMenu*     copyAsContextualMenu;
  BOOL        isDragging;
  NSDraggingSession* dragginSession;
}

@property(assign) CHEquationDocument* document;
@property(copy) NSData* pdfData;
@property(copy) NSString* mathMLString;
@property(copy) NSString* svgString;

-(IBAction) copy:(id)sender;
-(void)     copyAsFormat:(chalk_export_format_t)exportFormat;//copy the data into clipboard
-(IBAction) paste:(id)sender;
-(BOOL)     pasteDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard;
-(BOOL)     copyDelegated:(id)sender pasteboard:(NSPasteboard*)pasteboard;

@end
