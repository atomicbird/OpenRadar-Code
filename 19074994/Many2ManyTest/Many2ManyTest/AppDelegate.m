//
//  AppDelegate.m
//  Many2ManyTest
//
//  Created by Tom Harrington on 11/24/14.
//  Copyright (c) 2014 Atomic Bird, LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Erase data from previous runs
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[[self applicationDocumentsDirectory] path]];
    NSString *filename;
    while (filename = [dirEnum nextObject]) {
        [[NSFileManager defaultManager] removeItemAtPath:[[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:filename] error:nil];
    }
    
    NSMutableArray *tags = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    
    // Create some tags and items
    for (NSInteger i = 0; i<5; i++) {
        NSManagedObject *item = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
        [item setValue:[NSString stringWithFormat:@"item %ld", (long)i] forKey:@"name"];
        [items addObject:item];
        NSManagedObject *tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.managedObjectContext];
        [tag setValue:[NSString stringWithFormat:@"tag %ld", (long)i] forKey:@"name"];
        [tags addObject:tag];
    }
    
    // Link all tags to all items
    for (NSManagedObject *tag in tags) {
        for (NSManagedObject *item in items) {
            [[tag mutableSetValueForKey:@"items"] addObject:item];
        }
    }
    
    // Print tag count for each item
    for (NSManagedObject *item in items) {
        NSLog(@"Item named '%@' has %lu tags: %@", [item valueForKey:@"name"], [[item valueForKey:@"tags"] count], [item valueForKey:@"tags"]);
    }
    
    // Print item count for each tag
    for (NSManagedObject *tag in tags) {
        NSLog(@"Tag named '%@' has %lu items: %@", [tag valueForKey:@"name"], [[tag valueForKey:@"items"] count], [tag valueForKey:@"items"]);
    }

    // Save
    NSError *saveError = nil;
    if (![self.managedObjectContext save:&saveError]) {
        NSLog(@"Save error: %@", [saveError localizedDescription]);
        return;
    }
    
    // Migrate to a new location
    NSURL *newURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OSXCoreDataObjC-new.storedata"];
    
    NSError *migrateError = nil;
    NSPersistentStore *newStore = [self.persistentStoreCoordinator migratePersistentStore:[[self.persistentStoreCoordinator persistentStores] lastObject]
                                                                                    toURL:newURL
                                                                                  options:nil
                                                                                 withType:NSSQLiteStoreType
                                                                                    error:&migrateError];
    if (newStore == nil) {
        NSLog(@"Migrate error: %@", [migrateError localizedDescription]);
    }
    
    [self.managedObjectContext reset];
    

    // Print tag count for each item
    NSFetchRequest *itemFetch = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    NSError *fetchError = nil;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:itemFetch error:&fetchError];
    for (NSManagedObject *item in fetchedItems) {
        NSLog(@"Item named '%@' has %lu tags: %@", [item valueForKey:@"name"], [[item valueForKey:@"tags"] count], [item valueForKey:@"tags"]);
    }
    // Print item count for each tag
    NSFetchRequest *tagFetch = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    fetchError = nil;
    NSArray *fetchedTags = [self.managedObjectContext executeFetchRequest:tagFetch error:&fetchError];
    for (NSManagedObject *tag in fetchedTags) {
        NSLog(@"Tag named '%@' has %lu items: %@", [tag valueForKey:@"name"], [[tag valueForKey:@"items"] count], [tag valueForKey:@"items"]);
    }

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.atomicbird.Many2ManyTest" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.atomicbird.Many2ManyTest"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Many2ManyTest" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
