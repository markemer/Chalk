//
//  CHCGUtils.h
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#ifndef Chalk_CHCGUtils_h
#define Chalk_CHCGUtils_h

void CGDrawProgressIndicator(CGContextRef cgContext, CGRect bounds);
CGRect adaptRectangle(CGRect rectangle, CGRect containerRectangle, BOOL allowScaleDown, BOOL allowScaleUp, BOOL integerScale);
void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);

#endif
