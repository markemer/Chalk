//
//  CHQuickReferenceWindowController.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHWebView.h"

@class CHTreeController;

@interface CHQuickReferenceWindowController : NSWindowController <NSTextFieldDelegate, NSOutlineViewDelegate,
                                              NSSearchFieldDelegate,
                                              CHWebViewDelegate> {
  IBOutlet NSSearchField* searchField;
  IBOutlet NSOutlineView* outlineView;
  IBOutlet CHWebView*     webView;
  CHTreeController* treeController;
}

@end
