//
//  MemDirectory.m
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemDirectory.h"

@implementation MemDirectory
{
    NSMutableArray<MemEntry*>* _children;
}

+ (NSString*)entryType
{
    return NSFileTypeDirectory;
}

- (instancetype)initWithName:(NSString *)name andAttributes:(NSDictionary *)attr
{
    self = [super initWithName:name andAttributes:attr];
    if (self != nil)
    {
        _children = [NSMutableArray array];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ : %@", self.name, self.children];
}

- (off_t)size
{
    return (off_t)(self.children.count + 2);
}

-(off_t)contentSize
{
    off_t contentSize = 0;
    for (MemEntry* entry in self.children)
    {
        if ([entry isKindOfClass:[MemDirectory class]])
        {
            contentSize += [((MemDirectory*)entry) contentSize];
        }
        else if ([entry isKindOfClass:[MemEntry class]])
        {
            contentSize += entry.size;
        }
    }
    return contentSize;
}

- (NSUInteger)descendantCount
{
    NSUInteger count = self.children.count;
    for (MemEntry* entry in self.children)
    {
        if ([entry isKindOfClass:[MemDirectory class]])
        {
            count += [((MemDirectory*)entry) descendantCount];
        }
    }
    return count;
}

- (void)addEntry:(MemEntry *)entry
{
    NSAssert(entry != self, @"Cannot add entry to itself.");
    entry.parent = self;
    [_children addObject:entry];
}

- (void)removeEntry:(MemEntry *)entry
{
    entry.parent = nil;
    [_children removeObject:entry];
}

@end
