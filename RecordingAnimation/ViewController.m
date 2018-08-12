//
//  ViewController.m
//  RecordingAnimation
//
//  Created by xuyanlan on 2018/8/4.
//  Copyright © 2018年 xuyanlan. All rights reserved.
//
#import "BIAssistantRecordAnimationView.h"
#import "ViewController.h"

@interface ViewController ()
@property(nonatomic, strong) BIAssistantRecordAnimationView *assistantAnimation;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 200, 480, 300)];
    bg.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:bg];
    
    self.assistantAnimation = [[BIAssistantRecordAnimationView alloc] initWithFrame:CGRectMake(40, 400, 300, 100)];
    [self.view addSubview:self.assistantAnimation];
    self.assistantAnimation.layer.borderColor = [UIColor redColor].CGColor;
    self.assistantAnimation.layer.borderWidth = 1.5;
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20, 50, 120, 50)];
    [button setTitle:@"录音动画开始" forState:(UIControlStateNormal)];
    [button setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
    [button addTarget:self action:@selector(recordingClick) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button];
    
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(20, 120, 120, 50)];
    [button1 setTitle:@"录音动画结束" forState:(UIControlStateNormal)];
    [button1 setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
    [button1 addTarget:self action:@selector(recordingEndClick) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button1];
    
    
    UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(220, 50, 120, 50)];
    [button2 setTitle:@"加大音量" forState:(UIControlStateNormal)];
    [button2 setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
    [button2 addTarget:self action:@selector(addLevel) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button2];
    
    
    UIButton *button3 = [[UIButton alloc] initWithFrame:CGRectMake(220, 120, 120, 50)];
    [button3 setTitle:@"减小音量" forState:(UIControlStateNormal)];
    [button3 setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
    [button3 addTarget:self action:@selector(oddLevel) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button3];
    
    
}

- (void)recordingClick {
    self.assistantAnimation.speechStatus = BIAssistantSpeechStatusRecording;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];
}
- (void)changeVolume {
    int volume = arc4random()%31;
    if(volume < 10){
        volume = 10;
    }
    [self.assistantAnimation updateRecordingVolume:volume];
}
- (void)recordingEndClick {
    self.assistantAnimation.speechStatus = BIAssistantSpeechStatusRecognising;
}
- (void)addLevel {
    [self.assistantAnimation updateRecordingVolume:10];
}
- (void)oddLevel {
    [self.assistantAnimation updateRecordingVolume:5];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
