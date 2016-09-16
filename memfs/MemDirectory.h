//
//  MemDirectory.h
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemEntry.h"

@interface MemDirectory : MemEntry

@property (nonatomic, readonly) NSArray<MemEntry*>* children;

- (off_t)contentSize;
- (NSUInteger)descendantCount;

- (void)addEntry:(MemEntry*)entry;
- (void)removeEntry:(MemEntry*)entry;

@end
