//
//  ViewController.m
//  学习OpenGL1
//
//  Created by liter on 16/10/20.
//  Copyright © 2016年 liter. All rights reserved.
//

#import "ViewController.h"
#import "openGLView.h"
#import <AVFoundation/AVFoundation.h>

# define ONE_FRAME_DURATION 0.03

@interface ViewController () <AVPlayerItemOutputPullDelegate>

@property(nonatomic,strong)openGLView *openView;

/// 播放器
@property(nonatomic , strong) AVPlayer *player;
/// video 输出对象
@property(nonatomic , strong) AVPlayerItemVideoOutput *videoOutput;
/// 管理 video 输出 对象的队列
@property(nonatomic , strong) dispatch_queue_t myVideoOutputQueue;
/// 屏幕同步时间起
@property(nonatomic , strong) CADisplayLink *displayLink;
@property(nonatomic , strong) UIImageView *imgView;

@end

@implementation ViewController


- (openGLView *)openView{
    if (_openView == nil) {
        _openView = [[openGLView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_openView customInit];
        [self.view addSubview:_openView];
    }
    return _openView;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
//    self.view.backgroundColor = [UIColor redColor];
    
    self.openView;
    
    
    
    return;;
    [self createPlayer];
    [self createVideoOutput];
    [self createDisplayLink];
    
    NSString *mp4 = [[NSBundle mainBundle] pathForResource:@"wu" ofType:@"mp4"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:mp4];
    
    [self setupPlayerbackForUrl:url];
    

    
}

- (void)createPlayer{
    _player = [[AVPlayer alloc] init];
    
}
- (void)createVideoOutput{
    NSDictionary *pixBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBufferAttributes];
    _myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [_videoOutput setDelegate:self queue:_myVideoOutputQueue];
    
}
- (void)setupPlayerbackForUrl:(NSURL *)url{
    if (url == nil) {
        NSLog(@"视频资源不存在");
        return;
    }
    if ([_player currentItem] == nil){}
    
    [[_player currentItem] removeOutput:_videoOutput];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVAsset *asset = [item asset];
    
    [item addOutput:_videoOutput];
    [_player replaceCurrentItemWithPlayerItem:item];
    [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
    [_player play];
    
//    /// 获取asset里面信息，因为第一次被加载大多数属性值是Unknown状态
//    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
//        /// 判断一个值是否可以被成功取到
//        NSError *error;
//        NSInteger index = [asset statusOfValueForKey:@"tracks" error:&error];
//        if([asset statusOfValueForKey:@"tracks" error:&error] == AVKeyValueStatusLoaded){
//            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
//            if (tracks.count > 0) {
//                AVAssetTrack *videoTrack = [tracks firstObject];
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [item addOutput:_videoOutput];
//                    [_player replaceCurrentItemWithPlayerItem:item];
//                    [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
//                    [_player play];
//                });
////                if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
////                    CGAffineTransform preferredTransform = [videoTrack preferredTransform];
////                }
//            }
//        }
//        else{
//            NSLog(@"%@",error);
//        }
//    }];
}


- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender NS_AVAILABLE(10_8, 6_0){
    NSLog(@"AVPlayerItemOutputPullDelegate");
    [_displayLink setPaused:NO];
}

- (void)createDisplayLink{
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_displayLink setPaused:YES];
}



- (void)displayLinkCallback:(CADisplayLink *)sender{
    CMTime outputItemTime = kCMTimeInvalid;
    /// 计算下一次同步时间，当屏幕下次刷新
    CFTimeInterval nextVSync = ([sender timestamp]+[sender duration]);
    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    if ([self.videoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [_videoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        
        [self.openView setImageBuffer:pixelBuffer];
        
//        [_displayVC loadPixbuffer:pixelBuffer];
//         [_displayLink setPaused:YES];
        if (pixelBuffer != NULL) {
            CFRelease(pixelBuffer);
        }
        
    }
}


@end
