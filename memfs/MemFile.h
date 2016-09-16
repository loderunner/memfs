//
//  MemFile.h
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import "MemEntry.h"

@interface MemFile : MemEntry

@property (nonatomic, readonly) NSMutableData* data;

@end
