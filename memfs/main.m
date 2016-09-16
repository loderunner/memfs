//
//  main.m
//  memfs
//
//  Created by Charles Francoise on 16/09/16.
//  Copyright © 2016 Charles Francoise. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OSXFUSE/OSXFUSE.h>

#import "MemDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MemDelegate* delegate = [[MemDelegate alloc] init];
        GMUserFileSystem* fs = [[GMUserFileSystem alloc] initWithDelegate:delegate isThreadSafe:NO];
        [fs mountAtPath:@(argv[1])
            withOptions:@[@"debug", @"local", @"volname=Memory File System"]
       shouldForeground:YES
        detachNewThread:NO];
    }
    return 0;
}
