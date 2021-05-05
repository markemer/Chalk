//
//  IJSVGExporter.h
//  IJSVGExample
//
//  Created by Curtis Hard on 06/01/2017.
//  Copyright © 2017 Curtis Hard. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IJSVG;

typedef void (^IJSVGCGPathHandler)(const CGPathElement * pathElement);

void IJSVGExporterPathCaller(void * info, const CGPathElement * pathElement);

typedef NS_OPTIONS( NSInteger, IJSVGExporterOptions) {
    IJSVGExporterOptionRemoveUselessGroups = 1 << 1,
    IJSVGExporterOptionRemoveUselessDef = 1 << 2,
    IJSVGExporterOptionMoveAttributesToGroup = 1 << 3,
    IJSVGExporterOptionCreateUseForPaths = 1 << 4,
    IJSVGExporterOptionSortAttributes = 1 << 5,
    IJSVGExporterOptionCollapseGroups = 1 << 6,
    IJSVGExporteroptionCleanupPaths = 1 << 7,
    IJSVGExporterOptionAll = IJSVGExporterOptionRemoveUselessDef|
        IJSVGExporterOptionRemoveUselessGroups|
        IJSVGExporterOptionCreateUseForPaths|
        IJSVGExporterOptionMoveAttributesToGroup|
        IJSVGExporterOptionSortAttributes|
        IJSVGExporterOptionCollapseGroups|
        IJSVGExporteroptionCleanupPaths
};

@interface IJSVGExporter : NSObject {
    
@private
    IJSVG * _svg;
    IJSVGExporterOptions _options;
    NSXMLDocument * _dom;
    NSXMLElement * _defElement;
    NSInteger _gradCount;
    NSInteger _patternCount;
    NSInteger _imageCount;
    NSInteger _maskCount;
    NSInteger _pathCount;
    
}

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * description;

- (id)initWithSVG:(IJSVG *)svg
          options:(IJSVGExporterOptions)options;
- (NSString *)SVGString;
- (NSData *)SVGData;

@end
