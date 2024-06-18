//
//  CHPersistentDocument.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/03/17.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHPersistentDocument : NSPersistentDocument {
}

@property(nonatomic,readonly) BOOL isDefaultDocument;

-(void) commitChangesIntoManagedObjectContext:(void (^)(void))completionHandler;

+(NSURL*)    defaultDocumentFolderURL;
+(NSURL*)    defaultDocumentFileURL;
+(NSString*) defaultDocumentFileName;
+(NSString*) defaultDocumentType;

@end
