//
//  MemDelegate.m
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemDelegate.h"
#import "MemDirectory.h"
#import "MemFile.h"

#import <sys/mount.h>

#import <OSXFUSE/OSXFUSE.h>

@interface MemDelegate ()

@property (atomic, readonly) MemDirectory* root;

@end

@implementation MemDelegate

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _root = [[MemDirectory alloc] init];
    }
    return self;
}

- (MemEntry*)entryAtPath:(NSString*)path
{
    if ([path isEqualToString:@"/"])
    {
        return self.root;
    }
    
    NSArray<NSString*>* pathComponents = [[path stringByDeletingLastPathComponent] pathComponents];
    NSString* lastPathComponent = [path lastPathComponent];
    MemDirectory* dir = self.root;
    for (NSString* component in pathComponents)
    {
        if ([component isEqualToString:@"."])
        {
            continue;
        }
        else if ([component isEqualToString:@".."])
        {
            dir = dir.parent;
        }
        else
        {
            if ([component isEqualToString:@"/"])
            {
                dir = self.root;
            }
            else
            {
                NSUInteger entryIndex = [dir.children indexOfObjectPassingTest:
                    ^BOOL(MemEntry* _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                        return [entry.name isEqualToString:component];
                    }
                ];
                if (entryIndex != NSNotFound)
                {
                    MemEntry* entry = dir.children[entryIndex];
                    if ([entry isKindOfClass:[MemDirectory class]])
                    {
                        dir = (MemDirectory*)entry;
                    }
                    else
                    {
                        return nil;
                    }
                }
                else
                {
                    return nil;
                }
            }
        }
    }
    
    NSUInteger entryIndex = [dir.children indexOfObjectPassingTest:
                             ^BOOL(MemEntry* _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                                 return [entry.name isEqualToString:lastPathComponent];
                             }
                             ];
    if (entryIndex != NSNotFound)
    {
        return dir.children[entryIndex];
    }
    else
    {
        return nil;
    }
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if ((entry != nil) && ([entry isKindOfClass:[MemDirectory class]]))
    {
        MemDirectory* dir = (MemDirectory*)entry;
        NSArray* children = [dir.children sortedArrayUsingComparator:
            ^NSComparisonResult(MemEntry* _Nonnull left, MemEntry* _Nonnull right) {
                return [left.name localizedStandardCompare:right.name];
            }
        ];
        NSMutableArray* names = [NSMutableArray array];
        for (MemEntry* child in children)
        {
            [names addObject:child.name];
        }
        return names;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return nil;
    }
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path userData:(id)userData error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if (entry != nil)
    {
        return [entry attributes];
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return nil;
    }
}

- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSInteger size = [self.root contentSize];
    
    NSInteger freeSize = 0;
    struct statfs st;
    if (statfs("/", &st) == 0)
    {
        freeSize = (uint64_t)st.f_bsize * st.f_bfree;
    }
    
    NSInteger nodes = (NSInteger)[self.root descendantCount];
    
    NSInteger freeNodes = (NSIntegerMax - [MemEntry currentNodeId]);
    
    NSDictionary* attr = @{ NSFileSystemSize : @(size),
                            NSFileSystemFreeSize : @(freeSize),
                            NSFileSystemNodes : @(nodes),
                            NSFileSystemFreeNodes : @(freeNodes),
                            kGMUserFileSystemVolumeSupportsExtendedDatesKey : @YES,
                            kGMUserFileSystemVolumeSupportsCaseSensitiveNamesKey : @YES };
    return attr;
}

- (BOOL)setAttributes:(NSDictionary *)attr ofItemAtPath:(NSString *)path userData:(id)userData error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if (entry != nil)
    {
        [entry setAttributes:attr];
        return YES;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
}

- (BOOL)openFileAtPath:(NSString *)path mode:(int)mode userData:(__autoreleasing id *)userData error:(NSError *__autoreleasing *)error
{
    return YES;
}

- (void)releaseFileAtPath:(NSString *)path userData:(id)userData
{
}

- (int)readFileAtPath:(NSString *)path userData:(id)userData buffer:(char *)buffer size:(size_t)size offset:(off_t)offset error:(NSError *__autoreleasing *)error
{
    MemFile* file = (MemFile*)[self entryAtPath:path];
    int readSize = (int)MIN(size, (file.data.length - offset));
    [file.data getBytes:buffer range:NSMakeRange(offset, readSize)];
    
    return readSize;
}

- (int)writeFileAtPath:(NSString *)path userData:(id)userData buffer:(const char *)buffer size:(size_t)size offset:(off_t)offset error:(NSError *__autoreleasing *)error
{
    MemFile* file = (MemFile*)[self entryAtPath:path];
    [file.data replaceBytesInRange:NSMakeRange(offset, file.data.length - offset)
                         withBytes:buffer
                            length:size];
    
    return (int)size;
}

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if (entry != nil)
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:EEXIST
                                 userInfo:nil];
        return NO;
    }
    
    entry = [self entryAtPath:[path stringByDeletingLastPathComponent]];
    MemDirectory* dir = nil;
    if ([entry isKindOfClass:[MemDirectory class]])
    {
        dir = (MemDirectory*)entry;
        [dir addEntry:[[MemDirectory alloc] initWithName:[path lastPathComponent]
                                           andAttributes:attributes]];
        return YES;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
}

- (BOOL)createFileAtPath:(NSString *)path attributes:(NSDictionary *)attributes userData:(__autoreleasing id *)userData error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if (entry != nil)
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:EEXIST
                                 userInfo:nil];
        return NO;
    }
    
    entry = [self entryAtPath:[path stringByDeletingLastPathComponent]];
    MemDirectory* dir = nil;
    if ([entry isKindOfClass:[MemDirectory class]])
    {
        dir = (MemDirectory*)entry;
        [dir addEntry:[[MemFile alloc] initWithName:[path lastPathComponent]
                                      andAttributes:attributes]];
        return YES;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
}

- (BOOL)moveItemAtPath:(NSString *)source toPath:(NSString *)destination error:(NSError *__autoreleasing *)error
{
    MemEntry* srcEntry = [self entryAtPath:source];
    if (srcEntry == nil)
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
    
    MemDirectory* srcDir = srcEntry.parent;
    if (srcDir == nil)
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
    
    MemEntry* destEntry = [self entryAtPath:destination];
    if (destEntry != nil) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:EEXIST
                                 userInfo:nil];
        return NO;
    }
    
    destEntry = [self entryAtPath:[destination stringByDeletingLastPathComponent]];
    MemDirectory* destDir = nil;
    if ([destEntry isKindOfClass:[MemDirectory class]])
    {
        destDir = (MemDirectory*)destEntry;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
    
    [srcDir removeEntry:srcEntry];
    srcEntry.name = [destination lastPathComponent];
    [destDir addEntry:srcEntry];
    
    return YES;
}

- (BOOL)removeDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if ((entry != nil) && ([entry isKindOfClass:[MemDirectory class]]))
    {
        MemDirectory* dir = (MemDirectory*)entry;
        if (dir.children.count == 0)
        {
            [entry.parent removeEntry:entry];
            return YES;
        }
        else
        {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                         code:ENOTEMPTY
                                     userInfo:nil];
            return NO;
        }
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)error
{
    MemEntry* entry = [self entryAtPath:path];
    if ((entry != nil) && ([entry isKindOfClass:[MemFile class]]))
    {
        [entry.parent removeEntry:entry];
        return YES;
    }
    else
    {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                     code:ENOENT
                                 userInfo:nil];
        return NO;
    }
}

@end
