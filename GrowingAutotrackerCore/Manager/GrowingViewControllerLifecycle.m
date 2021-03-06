//
// Created by xiangyang on 2020/11/23.
//

#import "GrowingViewControllerLifecycle.h"

@interface GrowingViewControllerLifecycle ()
@property(strong, nonatomic, readonly) NSPointerArray *viewControllerLifecycleDelegates;
@property(strong, nonatomic, readonly) NSLock *delegateLock;
@end

@implementation GrowingViewControllerLifecycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _viewControllerLifecycleDelegates = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
        _delegateLock = [[NSLock alloc] init];
    }

    return self;
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (void)addViewControllerLifecycleDelegate:(id)delegate {
    [self.delegateLock lock];
    if (![self.viewControllerLifecycleDelegates.allObjects containsObject:delegate]) {
        [self.viewControllerLifecycleDelegates addPointer:(__bridge void *)delegate];
    }
    [self.delegateLock unlock];
}

- (void)removeViewControllerLifecycleDelegate:(id)delegate {
    [self.delegateLock lock];
    [self.viewControllerLifecycleDelegates.allObjects
            enumerateObjectsWithOptions:NSEnumerationReverse
                             usingBlock:^(NSObject *obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                 if (delegate == obj) {
                                     [self.viewControllerLifecycleDelegates removePointerAtIndex:idx];
                                     *stop = YES;
                                 }
                             }];
    
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerDidAppear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }
    [self.delegateLock lock];
    for (id delegate in self.viewControllerLifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerDidAppear:)]) {
            [delegate viewControllerDidAppear:controller];
        }
    }
    [self.delegateLock unlock];
}

- (void)dispatchViewControllerDidDisappear:(UIViewController *)controller {
    if (controller == nil) {
        return;
    }

    [self.delegateLock lock];
    for (id delegate in self.viewControllerLifecycleDelegates) {
        if ([delegate respondsToSelector:@selector(viewControllerDidDisappear:)]) {
            [delegate viewControllerDidDisappear:controller];
        }
    }
    [self.delegateLock unlock];
}
@end
