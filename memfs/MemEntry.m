//
//  MemEntry.m
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemEntry.h"

#import <OSXFUSE/OSXFUSE.h>

static ino_t currentNodeId = 0;

@implementation MemEntry

+ (ino_t)currentNodeId
{
    return currentNodeId;
}

+ (ino_t)nextNodeId
{
    ino_t nodeId = OSAtomicIncrement64((int64_t*)&currentNodeId);
    return nodeId;
}

+ (NSMutableDictionary*)defaultAttributes
{
    NSMutableDictionary* attr = [NSMutableDictionary dictionary];
    attr[NSFileSystemFileNumber] = @([MemEntry nextNodeId]);
    attr[NSFileOwnerAccountID] = @(getuid());
    attr[NSFileGroupOwnerAccountID] = @(getgid());
    NSDate* date = [NSDate date];
    attr[NSFileCreationDate] = date;
    attr[kGMUserFileSystemFileAccessDateKey] = date;
    attr[NSFileModificationDate] = date;
    attr[kGMUserFileSystemFileChangeDateKey] = date;
    return attr;
}

- (instancetype)init
{
    return [self initWithName:@"" andAttributes:nil];
}

- (instancetype)initWithName:(NSString*)name andAttributes:(NSDictionary *)attr
{
    self = [super init];
    if (self != nil)
    {
        NSMutableDictionary* defaultAttributes = [[self class] defaultAttributes];
        [defaultAttributes addEntriesFromDictionary:attr];
        _nodeId = [defaultAttributes[NSFileSystemFileNumber] unsignedIntegerValue];
        _name = name;
        _uid = [defaultAttributes[NSFileOwnerAccountID] unsignedIntValue];
        _gid = [defaultAttributes[NSFileGroupOwnerAccountID] unsignedIntValue];
        _creationDate = defaultAttributes[NSFileCreationDate];
        _accessDate = defaultAttributes[kGMUserFileSystemFileAccessDateKey];
        _modificationDate = defaultAttributes[NSFileModificationDate];
        _changeDate = defaultAttributes[kGMUserFileSystemFileChangeDateKey];
    }
    return self;
}

- (NSDictionary *)attributes
{
    NSMutableDictionary* attr = [NSMutableDictionary dictionary];
    attr[NSFileType] = [[self class] entryType];
    attr[NSFileSystemFileNumber] = @(self.nodeId);
    attr[NSFileSize] = @(self.size);
    attr[NSFilePosixPermissions] = @(0777);
    attr[NSFileOwnerAccountID] = @(self.uid);
    attr[NSFileGroupOwnerAccountID] = @(self.gid);
    attr[NSFileCreationDate] = self.creationDate;
    attr[kGMUserFileSystemFileAccessDateKey] = self.accessDate;
    attr[NSFileModificationDate] = self.modificationDate;
    attr[kGMUserFileSystemFileChangeDateKey] = self.changeDate;
    
    return attr;
}

- (void)setAttributes:(NSDictionary *)attr
{
    if (attr[NSFileOwnerAccountID])
    {
        self.uid = [attr[NSFileOwnerAccountID] unsignedIntValue];
    }
    
    if (attr[NSFileGroupOwnerAccountID])
    {
        self.gid = [attr[NSFileGroupOwnerAccountID] unsignedIntValue];
    }
    
    if (attr[NSFileCreationDate])
    {
        self.creationDate = attr[NSFileCreationDate];
    }
    
    if (attr[kGMUserFileSystemFileAccessDateKey])
    {
        self.accessDate = attr[kGMUserFileSystemFileAccessDateKey];
    }
    
    if (attr[NSFileModificationDate])
    {
        self.modificationDate = attr[NSFileModificationDate];
    }
    
    if (attr[kGMUserFileSystemFileChangeDateKey])
    {
        self.changeDate = attr[kGMUserFileSystemFileChangeDateKey];
    }
}

@end
