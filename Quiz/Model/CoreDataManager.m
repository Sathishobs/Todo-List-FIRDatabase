//
//  CoreDataManager.m
//  Quiz
//
//  Created by optisol on 14/02/19.
//  Copyright © 2019 optisol. All rights reserved.
//

#import "CoreDataManager.h"
#import "ConstantString.h"
#import "AppDelegate.h"
@implementation CoreDataManager

#pragma mark - SharedInstance
+ (CoreDataManager *)sharedInstance // Creating global instance for this app
{
    static CoreDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CoreDataManager alloc] init];
    });
    return sharedInstance;
}

+ (NSManagedObjectContext *)globalContext{
    return [[CoreDataManager sharedInstance] managedObjectContext];
}

- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    // By default, it will search for and if not found, create a sqlite file named Quiz.sqlite
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Quiz.sqlite"];
    
    /*Set up the store.
     For the sake of illustration, provide a pre-populated default store.
     */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:storePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Quiz" ofType:@"sqlite"];
        if (defaultStorePath) {
            [fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
        }
    }
    
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    NSError *error;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        // Fail
        exit(-1);
    }
    return persistentStoreCoordinator;
}

- (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSError *)saveContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"cotext saving error!");
        return error;
    }
    return error;
}

#pragma mark - Coredata Operations
+ (NSError *)insertARecordWithRecordValues:(NSDictionary*)values ToTable:(NSString *)tableName InContext:(NSManagedObjectContext*)context
{
    NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:tableName inManagedObjectContext:context];
    for(NSString *key in values.allKeys)
    {
        [entity setValue:[values valueForKey:key] forKey:key];
    }
    return [CoreDataManager saveContext:context];
}

// delete a record from context
+ (NSError *)deleteARecord:(NSManagedObject *)record InContext:(NSManagedObjectContext *)context
{
    [context deleteObject:record];
    return [CoreDataManager saveContext:context];
}

// update a record from context with given text
+ (NSError *)updateARecord:(NSManagedObject *)record WithNewRecordValues:(NSDictionary *)values InTable:(NSString *)tableName InContext:(NSManagedObjectContext *)context
{
    for(NSString *key in values.allKeys)
    {
        [record setValue:[values valueForKey:key] forKey:key];
    }
    return [CoreDataManager saveContext:context];
}

/** Fetch all the records from context, it will be changed into pagitaion mechanism if the system database has bulk record **/
+ (NSMutableArray *)fetchAllRecordsFromTable:(NSString *)tableName InContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:tableName inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error = nil;
    return [[context executeFetchRequest:request error:&error] mutableCopy];
}

/** Fetch all the records from context based on matched predicate, it will be changed into pagitaion mechanism if the system database has bulk record **/

+ (NSMutableArray *)fetchRecordsFromTable:(NSString *)tableName MatchedByPredicate:(NSPredicate *)predicate InContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:tableName inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSError *error = nil;
    return [[context executeFetchRequest:request error:&error] mutableCopy];
}

/** Fetch recrods with request **/

+ (NSMutableArray *)fetchRecordsWithFetchRequest:(NSFetchRequest *)request InContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    return [[context executeFetchRequest:request error:&error] mutableCopy];
}

// Check duplicate records are exists in the overall data
+ (bool)checkDuplicateRecord:(NSString *)userStr;
{
    NSMutableArray *taskListArray = [[NSMutableArray alloc]init];
    NSManagedObjectContext* context1 = [AppDelegate sharedAppDelegate].managedObjectContext;
    taskListArray = [[CoreDataManager fetchAllRecordsFromTable:QEntityname InContext:context1]mutableCopy];
    if(taskListArray.count != 0) {
        for (int i=0; i<taskListArray.count; i++) {
            NSString * str = [[taskListArray valueForKey:QTaskAttr] objectAtIndex:i];
            if([str isEqualToString: userStr])  {
                return YES;
            }
        }
    }
    return NO;
}

// delete all the entries
+ (void) deleteAllEntities:(NSManagedObjectContext*)context {
    NSFetchRequest * allRecords = [[NSFetchRequest alloc] init];
    [allRecords setEntity:[NSEntityDescription entityForName:QEntityname inManagedObjectContext:context]];
    [allRecords setIncludesPropertyValues:NO];
    NSError * error = nil;
    NSArray * result = [context executeFetchRequest:allRecords error:&error];
    for (NSManagedObject * profile in result) {
        [context deleteObject:profile];
    }
    NSError *saveError = nil;
    [context save:&saveError];
}

@end
