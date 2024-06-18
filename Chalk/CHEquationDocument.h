//
//  CHEquationDocument.h
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHMathMLRenderer.h"
#import "CHSVGRenderer.h"

@class CHEquationImageView;
@class CHEquationTextView;

@interface CHEquationDocument : NSDocument <CHMathMLRendererDelegate,CHSVGRendererDelegate>
{
  IBOutlet NSTextField* errorTextField;
  IBOutlet CHEquationImageView* imageView;
  IBOutlet CHEquationTextView* inputTextView;
  IBOutlet NSColorWell* foregroundColorColorWell;
  IBOutlet NSButton* renderButton;
  CHMathMLRenderer* mathMLRenderer;
  CHSVGRenderer* svgRenderer;
  NSDictionary* loadedEquationGeneratorDict;
}

+(NSString*) defaultDocumentType;

-(IBAction) renderAction:(id)sender;
-(IBAction) copy:(id)sender;
-(IBAction) paste:(id)sender;

-(BOOL) applyState:(NSData*)pdfData;

@end
