//
//  CHInspectorView.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/11/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, chinspector_anchor_t) {
  CHINSPECTOR_ANCHOR_UNDEFINED,
  CHINSPECTOR_ANCHOR_TOP,
  CHINSPECTOR_ANCHOR_BOTTOM,
  CHINSPECTOR_ANCHOR_LEFT,
  CHINSPECTOR_ANCHOR_RIGHT,
};
//end chinspector_anchor_t

extern NSString* CHInspectorVisibleBinding;
extern NSString* CHInspectorVisibilityDidChangeNotification;

@interface CHInspectorView : NSView {
  BOOL visible;
}

@property(nonatomic) chinspector_anchor_t anchor;
@property(nonatomic) BOOL visible;
@property(nonatomic,assign) IBOutlet id delegate;

-(void) inspectorVisibilityDidChange:(NSNotification*)notification;

@end
