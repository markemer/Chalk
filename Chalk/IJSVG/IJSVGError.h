//
//  IJSVGError.h
//  IJSVGExample
//
//  Created by Curtis Hard on 16/09/2015.
//  Copyright © 2015 Curtis Hard. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const IJSVGErrorDomain = @"IJSVGErrorDomain";

typedef NS_ENUM(NSInteger, ijsvg_error_t) {
    IJSVGErrorReadingFile,
    IJSVGErrorParsingFile,
    IJSVGErrorParsingSVG,
    IJSVGErrorDrawing,
    IJSVGErrorInvalidViewBox
};
