//
//  NSImageExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Extended)

-(void)              removeRepresentationsOfClass:(Class)representationClass;
-(NSBitmapImageRep*) bitmapImageRepresentation;
-(NSBitmapImageRep*) newBitmapImageRepresentation;
-(NSBitmapImageRep*) bitmapImageRepresentationWithMaxSize:(NSSize)maxSize;
-(NSPDFImageRep*)    pdfImageRepresentation;
-(NSImageRep*)       bestImageRepresentationInContext:(NSGraphicsContext*)context;

@end
