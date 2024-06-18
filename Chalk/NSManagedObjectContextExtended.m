//
//  NSManagedObjectContext.m
//  Chalk
//
//  Created by Pierre Chatelier on 02/02/17.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSManagedObjectContextExtended.h"

#import "CHUtils.h"

@implementation NSManagedObjectContext (Extended)

-(NSPersistentStore*) addPersistentStoreIfNeededForURL:(NSURL*)fileURL error:(NSError**)outError
{
  NSPersistentStore* result = nil;
  NSPersistentStoreCoordinator* persistentStoreCoordinator = self.persistentStoreCoordinator;
  result = persistentStoreCoordinator.persistentStores.lastObject;
  if (!result)
  {
    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:[fileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
      DebugLog(0, @"error = %@", error);
    if (outError && error)
      *outError = error;
    error = nil;
    NSDictionary* sqliteOptions = @{
      NSSQLitePragmasOption:@{@"journal_mode":@"DELETE"}
    };
    result = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileURL options:sqliteOptions error:&error];
    if (outError && error)
      *outError = error;
    for(NSManagedObject* mo in self.registeredObjects)
      [self assignObject:mo toPersistentStore:result];
  }//end if (!result)
  return result;
}
//end addPersistentStoreIfNeededForURL:error:

@end
