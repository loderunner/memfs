//
//  MemFile.m
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemFile.h"

@implementation MemFile

+ (NSString*)entryType
{
    return NSFileTypeRegular;
}

- (instancetype)initWithName:(NSString *)name andAttributes:(NSDictionary *)attr
{
    self = [super initWithName:name andAttributes:attr];
    if (self != nil)
    {
        _data = [NSMutableData data];
    }
    return self;
}

- (NSString *)description
{
    return self.name;
}

- (off_t)size
{
    return (off_t)self.data.length;
}

@end
