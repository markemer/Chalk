//
//  CHPersistentDocument.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/03/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHPersistentDocument.h"

#import "CHUtils.h"
#import "NSWorkspaceExtended.h"

@implementation CHPersistentDocument

@dynamic isDefaultDocument;

+(BOOL) autosavesInPlace
{
  return YES;
}
//end autosavesInPlace

+(BOOL) autosavesDrafts
{
  return NO;
}
//end autosavesDrafts

+(NSURL*) defaultDocumentFolderURL
{
  NSURL* result = nil;
  NSString* defaultFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"];
  NSURL* defaultFolderURL = [NSURL fileURLWithPath:defaultFolder];
  result = [[NSWorkspace sharedWorkspace] getBestStandardURL:NSApplicationSupportDirectory domain:NSUserDomainMask defaultValue:defaultFolderURL];
  result = [result URLByAppendingPathComponent:[[NSWorkspace sharedWorkspace] applicationName]];
  return result;
}
//end defaultDocumentFolderURL

+(NSURL*) defaultDocumentFileURL
{
  NSURL* result = nil;
  NSURL* defaultDocumentFolderURL = [[self class] defaultDocumentFolderURL];
  result = [defaultDocumentFolderURL URLByAppendingPathComponent:[[self class] defaultDocumentFileName]];
  return result;
}
//end defaultDocumentFileURL

+(NSString*) defaultDocumentFileName
{
  NSString* result = @"default.chalk";
  return result;
}
//end defaultDocumentFileName

+(NSString*) defaultDocumentType
{
  NSString* result = [NSString stringWithFormat:@"%@_SQLite", NSStringFromClass([self class])];
  return result;
}
//end defaultDocumentType

-(BOOL) isDefaultDocument
{
  BOOL result = [self.fileURL isEqualTo:[[self class] defaultDocumentFileURL]];
  return result;
}
//end isDefaultDocument

-(void) commitChangesIntoManagedObjectContext:(void (^)(void))completionHandler
{
  DebugLog(1, @">commitChangesIntoManagedObjectContext");
  @synchronized(self.managedObjectContext)
  {
    if (!self.managedObjectContext.hasChanges)
    {
      if (completionHandler)
        completionHandler();
    }//end if (!self.managedObjectContext.hasChanges)
    else if (self.managedObjectContext.persistentStoreCoordinator.persistentStores.count)
    {
      NSError* error = nil;
      [self writeSafelyToURL:self.fileURL ofType:[[self class] defaultDocumentType] forSaveOperation:NSAutosaveInPlaceOperation error:&error];
      if (error)
        DebugLog(0, @"autosaveInPlace: error : <%@>", error);
      if (completionHandler)
        completionHandler();
    }//end if (self.managedObjectContext.persistentStoreCoordinator.persistentStores.count)
    else
      [self autosaveWithImplicitCancellability:YES completionHandler:^(NSError * _Nullable errorOrNil) {
        if (errorOrNil)
          DebugLog(0, @"autosaveWithImplicitCancellability: error : <%@>", errorOrNil);
        if (completionHandler)
          completionHandler();
      }];
  }//end @synchronized(self.managedObjectContext)
  DebugLog(1, @"<commitChangesIntoManagedObjectContext");
}
//end commitChangesIntoManagedObjectContext:

@end
