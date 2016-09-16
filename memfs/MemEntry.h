//
//  MemEntry.h
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MemDirectory;

@interface MemEntry : NSObject

@property (nonatomic, readonly) ino_t nodeId;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, readonly) off_t size;
@property (nonatomic, assign) uid_t uid;
@property (nonatomic, assign) gid_t gid;
@property (nonatomic, strong) NSDate* creationDate;
@property (nonatomic, strong) NSDate* accessDate;
@property (nonatomic, strong) NSDate* modificationDate;
@property (nonatomic, strong) NSDate* changeDate;

@property (nonatomic, weak) MemDirectory* parent;

+ (ino_t)currentNodeId;
+ (NSString*)entryType;

- (instancetype)init;
- (instancetype)initWithName:(NSString*)name andAttributes:(NSDictionary*)attr;

- (NSDictionary*)attributes;
- (void)setAttributes:(NSDictionary*)attr;

@end
