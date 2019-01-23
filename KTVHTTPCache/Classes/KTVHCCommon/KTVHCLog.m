//
//  KTVHCLog.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCLog.h"
#import "KTVHCPathTool.h"

#import <UIKit/UIKit.h>

@interface KTVHCLog ()

@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSFileHandle *writingHandle;
@property (nonatomic, strong) NSMutableArray<NSError *> *internalErrors;

@end

@implementation KTVHCLog

+ (instancetype)log
{
    static KTVHCLog *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.consoleLogEnable = NO;
        self.recordLogEnable = NO;
        self.lock = [[NSLock alloc] init];
        self.internalErrors = [NSMutableArray array];
    }
    return self;
}

- (void)addRecordLog:(NSString *)log
{
    if (!self.recordLogEnable) {
        return;
    }
    if (log.length <= 0) {
        return;
    }
    [self.lock lock];
    NSString *string = [NSString stringWithFormat:@"%@  %@\n", [NSDate date], log];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!self.writingHandle) {
        [KTVHCPathTool deleteFileAtPath:[KTVHCPathTool logPath]];
        [KTVHCPathTool createFileAtPath:[KTVHCPathTool logPath]];
        self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:[KTVHCPathTool logPath]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    [self.writingHandle writeData:data];
    [self.lock unlock];
}

- (NSString *)recordLogFilePath
{
    NSString *path = nil;
    [self.lock lock];
    long long size = [KTVHCPathTool sizeAtPath:[KTVHCPathTool logPath]];
    if (size > 0) {
        path = [KTVHCPathTool logPath];
    }
    [self.lock unlock];
    return path;
}

- (void)deleteRecordLog
{
    [self.lock lock];
    [self.writingHandle synchronizeFile];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [self.lock unlock];
}

- (NSError *)lastError
{
    return self.internalErrors.lastObject;
}

- (NSArray<NSError *> *)allErrors
{
    return [self.internalErrors copy];
}

- (void)addError:(NSError *)error
{
    if (error && [error isKindOfClass:[NSError class]]) {
        if (self.internalErrors.count >= 20) {
            [self.internalErrors removeObjectAtIndex:0];
        }
        [self.internalErrors addObject:error];
    }
}

#pragma mark - UIApplicationWillTerminateNotification

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self deleteRecordLog];
}

@end
