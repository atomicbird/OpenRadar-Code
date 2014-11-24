# Summary:

[Also see Openradar posting](http://www.openradar.me/radar?id=5521374336516096).

If a managed object model contains many-to-many relationships and a persistent store has non-nil values for these relationships, the relationships are zeroed out after a call to 
migratePersistentStore:toURL:options:withType:error:

"Zeroed out" meaning simply that calling valueForKey: with the relationship name returns an empty set where the set was not empty before making this call.

This bug is new in Yosemite.

# Steps to Reproduce:

1. Create a project which uses Core Data where the managed object model contains at least one many-to-many relationship.
2. Create a persistent store file using this model and populate it such that the many-to-many relationships are not empty.
3. Call 
migratePersistentStore:toURL:options:withType:error: to migrate the persistent store to a new location.

# Expected Results:

Many to many relationships would be preserved, along with all other data in the persistent store.

# Actual Results:

Many-to-many relationships are empty after the migrate call.

# Version:

Mac OS X 10.10.1 (14B25)

# Notes:

A sample project is attached. The model contains trivial "Item" and "Tag" entities which have a many-to-many relationship. The code creates five instances of each and links all Items to all Tags. It then migrates the store to a new location and fetches all instances of both
entities. After the migrate, no Items are related to any Tags.

# Configuration:

New on Yosemite.

# Attachments:

'Many2ManyTest.zip' was successfully uploaded.
