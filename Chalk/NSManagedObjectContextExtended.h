//
//  NSManagedObjectContextExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 02/02/17.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Extended)

-(NSPersistentStore*) addPersistentStoreIfNeededForURL:(NSURL*)fileURL error:(NSError**)error;

@end
