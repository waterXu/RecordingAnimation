//
//  BIAssistantRecordAnimationView.m
//  RecordingAnimation
//
//  Created by xuyanlan on 2018/8/4.
//  Copyright © 2018年 xuyanlan. All rights reserved.
//

#import "BIAssistantRecordAnimationView.h"
#define kMainLayerMinWidth 25
#define kLocationLayerWidth 26
#define kLuanchLayerCacheCount 15

@interface BIAssistantRecordAnimationView()<CAAnimationDelegate>
@property(nonatomic, strong) NSMutableArray *cacheLaunchLayers;//动画完成的副方块缓存
@property(nonatomic, strong) CAGradientLayer *mainLayer; //主方块
@property(nonatomic, strong) CAGradientLayer *locationRightLayer; //定位菱形小方块
@property(nonatomic, strong) CAGradientLayer *locationLeftLayer; //定位菱形小方块
@property(nonatomic, strong) NSMutableArray *launchLayers; //展开中的副方块集合
@property(nonatomic, strong) NSArray<UIColor *> *launchColorArray;
@property(nonatomic, strong) NSTimer *launchTimer;
@property(nonatomic, assign) NSInteger volume;
@property(nonatomic, assign) int lastLuanchColorIndex; //随机生成的颜色和上一个不要一致
@end
@implementation BIAssistantRecordAnimationView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _launchColorArray =  @[
                               [UIColor colorWithRed:122/255.0 green:238/255.0 blue:227/255.0 alpha:1.0],
                               [UIColor colorWithRed:130/255.0 green:187/255.0 blue:255/255.0 alpha:1.0],
                               [UIColor colorWithRed:130/255.0 green:132/255.0 blue:255/255.0 alpha:1.0],
                               [UIColor colorWithRed:170/255.0 green:128/255.0 blue:251/255.0 alpha:1.0],
                               [UIColor colorWithRed:224/255.0 green:129/255.0 blue:252/255.0 alpha:1.0]];
        _volume = 10;
        _lastLuanchColorIndex = -1;
        _launchLayers = [NSMutableArray array];
        _cacheLaunchLayers = [NSMutableArray array];
        [self commonInit];
    }
    return self;
}

- (CAGradientLayer *)mainLayer {
    if(!_mainLayer) {
        _mainLayer = [[CAGradientLayer alloc] init];
        _mainLayer.bounds = CGRectMake(0, 0, kMainLayerMinWidth, kMainLayerMinWidth);
        _mainLayer.colors = @[
                              (id)[UIColor colorWithRed:167/255.0 green:248/255.0 blue:254/255.0 alpha:1.0].CGColor,
                              (id)[UIColor colorWithRed:245/255.0 green:192/255.0 blue:254/255.0 alpha:1.0].CGColor];
        _mainLayer.locations = @[@0.2,@0.8];
        _mainLayer.opacity = 0.9;
        _mainLayer.startPoint = CGPointMake(0, 0);
        _mainLayer.endPoint = CGPointMake(1,1);
        _mainLayer.transform = CATransform3DMakeRotation(radians(45), 0, 0, -1);
        _mainLayer.anchorPoint = CGPointMake(0.5, 0.5);
        _mainLayer.zPosition = 1000;
    }
    return _mainLayer;
}

- (CAGradientLayer *)locationRightLayer {
    if(!_locationRightLayer) {
        _locationRightLayer = [self createLocationLayer];
    }
    return _locationRightLayer;
}

- (CAGradientLayer *)locationLeftLayer {
    if(!_locationLeftLayer) {
        _locationLeftLayer = [self createLocationLayer];
    }
    return _locationLeftLayer;
}
- (CAGradientLayer *)createLocationLayer {
    CAGradientLayer *layer = [[CAGradientLayer alloc] init];
    layer.bounds = CGRectMake(0, 0, kLocationLayerWidth, kLocationLayerWidth);
    layer.backgroundColor = [UIColor colorWithRed:122/255.0 green:238/255.0 blue:227/255.0 alpha:1.0].CGColor;
    layer.opacity = 0.75;
    layer.anchorPoint = CGPointMake(0.5, 0.5);
    CATransform3D baseXform = CATransform3DIdentity;
    CATransform3D scaleFrom = CATransform3DScale(baseXform, 1, (6 * 1.0)/kLocationLayerWidth, 0);
    CATransform3D rotationFrom = CATransform3DRotate(scaleFrom, radians(45), 0, 0, -1);
    layer.transform = rotationFrom;
    layer.zPosition = 10;
    return layer;
}
- (void)setSpeechStatus:(BIAssistantSpeechStatus)speechStatus {
    _speechStatus = speechStatus;
    switch (speechStatus) {
        case BIAssistantSpeechStatusNormal:
            break;
        case BIAssistantSpeechStatusRecording:
            [self playRecordingAnimation];
            break;
        case BIAssistantSpeechStatusRecognising:
            [self recordingTransferToRecognisingAnimation];
            break;
    }
}
- (void)commonInit {
    
}
- (void)playRecordingAnimation {
    //主方块
    if(![self.mainLayer superlayer]) {
        self.mainLayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self.layer addSublayer:self.mainLayer];
    }
    if(!self.mainLayer.animationKeys || ![self.mainLayer.animationKeys containsObject:@"mainLayerAnimation"]){
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.duration = 3;
        scale.fromValue = [[NSNumber alloc] initWithFloat:1.0];
        scale.toValue = [[NSNumber alloc] initWithFloat:2.0];
        scale.repeatCount = HUGE;
        scale.autoreverses = YES;
        [self.mainLayer addAnimation:scale forKey:@"mainLayerAnimation"];
    }
    //副方块
    _launchTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(createLuanchTimer) userInfo:nil repeats:YES];
    
    //菱形定位
    if(![self.locationRightLayer superlayer]){
        self.locationRightLayer.position = CGPointMake(self.frame.size.width, self.frame.size.height/2);
        [self.layer addSublayer:self.locationRightLayer];
    }
    if(!self.locationRightLayer.animationKeys || ![self.locationRightLayer.animationKeys containsObject:@"LocationRightTransfromX"]){
        CABasicAnimation *transfromX = [self locationAnimationIsTransLeft:NO];
        [self.locationRightLayer addAnimation:transfromX forKey:@"LocationRightTransfromX"];
    }
    
    if(![self.locationLeftLayer superlayer]){
        self.locationLeftLayer.position = CGPointMake(0, self.frame.size.height/2);
        [self.layer addSublayer:self.locationLeftLayer];
    }
    if(!self.locationLeftLayer.animationKeys || ![self.locationRightLayer.animationKeys containsObject:@"LocationLeftTransfromX"]){
        CABasicAnimation *transfromX = [self locationAnimationIsTransLeft:YES];
        [self.locationLeftLayer addAnimation:transfromX forKey:@"LocationLeftTransfromX"];
    }
}
//菱形方块动画
- (CABasicAnimation *)locationAnimationIsTransLeft:(BOOL)isTransLeft{
    CABasicAnimation *transfromX = [CABasicAnimation animationWithKeyPath:@"position"];
    transfromX.fromValue = [NSValue valueWithCGPoint:CGPointMake(isTransLeft ? self.frame.size.width*1.0/4 : self.frame.size.width * 3.0/4 , self.frame.size.height/2)];
    transfromX.toValue = [NSValue valueWithCGPoint:CGPointMake(isTransLeft ? 0 : self.frame.size.width, self.frame.size.height/2)];
    transfromX.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    transfromX.repeatCount = HUGE;
    transfromX.autoreverses = YES;
    transfromX.duration = 2.0;
    transfromX.fillMode = kCAFillModeForwards;
    return transfromX;
}

- (void)createLuanchTimer {
    [self updateRandomIndex];
    CALayer *rightLayer = [self createLuanchLayer];
    CAAnimationGroup *rightGroup = [self animationGroupIsTransToLeft:NO luanchLayerPosition:rightLayer.position];
    [rightLayer addAnimation:rightGroup forKey:@"rightAnimationGroup"];
    [self.layer addSublayer:rightLayer];
    
    CALayer *leftLayer = [self createLuanchLayer];
    CAAnimationGroup *leftGroup = [self animationGroupIsTransToLeft:YES luanchLayerPosition:rightLayer.position];
    [leftLayer addAnimation:leftGroup forKey:@"leftAnimationGroup"];
    [self.layer addSublayer:leftLayer];
    
}
//副方块动画
- (CAAnimationGroup *)animationGroupIsTransToLeft:(BOOL)isTransToLeft luanchLayerPosition:(CGPoint)position {
    //位移动画
    float transfromOffset = self.frame.size.width/2;
    CABasicAnimation *transfromx = [CABasicAnimation animationWithKeyPath:@"position"];
    transfromx.byValue = [NSValue valueWithCGPoint:CGPointMake((isTransToLeft ? transfromOffset : -transfromOffset), 0)] ;
    transfromx.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    
    //渐变动画
    CABasicAnimation *opacity1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity1.fromValue = [[NSNumber alloc] initWithFloat: 0.2];
    opacity1.toValue = [[NSNumber alloc] initWithFloat: 0.9];
    opacity1.duration = 0.5;
    
    
    CABasicAnimation *opacity2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity2.fromValue = [[NSNumber alloc] initWithFloat: 0.9];
    opacity2.toValue = [[NSNumber alloc] initWithFloat: 0.0];
    opacity2.duration = 1.25;
    
    
    //缩放动画
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = [[NSNumber alloc] initWithFloat: 1.0];
    scale.toValue = [[NSNumber alloc] initWithFloat: 0.1];
    scale.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 1.75;
    group.repeatCount = 1;
    group.animations = @[transfromx,opacity1,opacity2,scale];
    group.delegate = self;
    group.fillMode = kCAFillModeForwards;
    
    return group;
}

- (void)updateRandomIndex {
    int index = arc4random()%self.launchColorArray.count;
    while (index == _lastLuanchColorIndex) {
        index = arc4random()%self.launchColorArray.count;
    }
    _lastLuanchColorIndex = index;
}

- (CALayer *)createLuanchLayer {
    CALayer *luanchLayer = nil;
    if(self.cacheLaunchLayers && self.cacheLaunchLayers.count > 16) {
        int index = arc4random()%self.cacheLaunchLayers.count;
        CALayer *cacheLayer = [self.cacheLaunchLayers objectAtIndex:index];
        cacheLayer.backgroundColor = self.launchColorArray[self.lastLuanchColorIndex].CGColor;
        [self.cacheLaunchLayers removeObject:cacheLayer];
        luanchLayer = cacheLayer;
    } else {
        luanchLayer = [[CALayer alloc] init];
        luanchLayer.transform = CATransform3DMakeRotation(radians(45), 0, 0, -1);
        luanchLayer.anchorPoint = CGPointMake(0.5, 0.5);
        luanchLayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        luanchLayer.backgroundColor = self.launchColorArray[self.lastLuanchColorIndex].CGColor;
        luanchLayer.zPosition = 100;
    }
    
    CGFloat layerW = kMainLayerMinWidth + (kMainLayerMinWidth *_volume * 1.0/30);
    if (layerW > kMainLayerMinWidth * 2 - 10){
        layerW = kMainLayerMinWidth * 2 - 10;
    }
    luanchLayer.bounds = CGRectMake(0, 0, layerW, layerW);
    [self.launchLayers addObject:luanchLayer];
    return luanchLayer;
}

- (void)resetLaunchlayer:(CALayer *)layer {
    layer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    layer.opacity = 0.9;
}

- (void)updateRecordingVolume:(NSInteger)level {
    _volume = level;
    if(_speechStatus != BIAssistantSpeechStatusRecording) {
        return;
    }
    CABasicAnimation *rotate = (CABasicAnimation *)[self.mainLayer animationForKey:@"mainLayerAnimation"];
    if(rotate){
        CABasicAnimation *rotateNew = [rotate copy];
        [self.mainLayer removeAllAnimations];
        rotateNew.fromValue = [[NSNumber alloc] initWithFloat:(1.0 + level * 1.0/30)];
        [self.mainLayer addAnimation:rotateNew forKey:@"mainLayerAnimation"];
    }
    
}

- (void)recordingTransferToRecognisingAnimation {
    if(_launchTimer){
        [_launchTimer invalidate];
        _launchTimer = nil;
    }
    //移除动画，准备添加录音转换成识别动画
    //    self.mainLayer.bounds = CGRectMake(0, 0, kMainLayerMinWidth*2, kMainLayerMinWidth*2);
    //    [self.mainLayer removeAllAnimations];
    //    [self.locationLeftLayer removeAllAnimations];
    //    [self.locationRightLayer removeAllAnimations];
    
    
    //    for (CALayer *luanchLayer in self.launchLayers) {
    //        CAAnimationGroup *groupAnimation = [luanchLayer animationForKey:@"leftAnimationGroup"];
    //        if(groupAnimation){
    //            [luanchLayer removeAllAnimations];
    //        }
    //    }
    
    [self mainLayerAddEndAnim];
    [self locationLayerAddEndAnim];
    [self luanchLayersAddEndAnim];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.mainLayer removeAllAnimations];
//        [weakSelf.mainLayer removeFromSuperlayer];
        [weakSelf.locationLeftLayer removeAllAnimations];
        [weakSelf.locationLeftLayer removeFromSuperlayer];
        [weakSelf.locationRightLayer removeAllAnimations];
        [weakSelf.locationRightLayer removeFromSuperlayer];
        for (CALayer *luanchLayer in weakSelf.launchLayers) {
            [luanchLayer removeAllAnimations];
            [luanchLayer removeFromSuperlayer];
        }
    });
    
}
- (void)mainLayerAddEndAnim {
    [self.mainLayer removeAllAnimations];
    id value = [[self.mainLayer.presentationLayer valueForKeyPath:@"transform.scale"] copy];
    
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.duration = 1.0;
    scale.fromValue = value;
    scale.toValue = [[NSNumber alloc] initWithFloat:0.2];
    scale.repeatCount = 1;
    scale.delegate = self;
    scale.removedOnCompletion = NO;
    [self.mainLayer addAnimation:scale forKey:@"mainLayerEndAnimation"];
}
- (void)locationLayerAddEndAnim {
    [self.locationLeftLayer removeAllAnimations];
    [self.locationRightLayer removeAllAnimations];
    CABasicAnimation *transfromL = [self endAnimationLocationLayer:self.locationLeftLayer];
    [self.locationLeftLayer addAnimation:transfromL forKey:@"LocationLeftTransfromXEnd"];
    
    CABasicAnimation *transfromR = [self endAnimationLocationLayer:self.locationRightLayer];
    [self.locationRightLayer addAnimation:transfromR forKey:@"LocationRightTransfromEnd"];
}
//菱形方块结束动画
- (CABasicAnimation *)endAnimationLocationLayer:(CALayer *)layer{
    id value = [[layer.presentationLayer valueForKeyPath:@"position"] copy];
    CABasicAnimation *transfromX = [CABasicAnimation animationWithKeyPath:@"position"];
    transfromX.fromValue = value;
    transfromX.toValue =  [NSValue valueWithCGPoint:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
    transfromX.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    transfromX.repeatCount = 1;
    transfromX.duration = 1.0;
    transfromX.fillMode = kCAFillModeForwards;
    transfromX.delegate = self;
    transfromX.removedOnCompletion = NO;
    return transfromX;
}
- (void)luanchLayersAddEndAnim {
    for (CALayer *luanchLayer in self.launchLayers) {
//        [luanchLayer removeAllAnimations];
        //位移动画
        id value = [[luanchLayer.presentationLayer valueForKeyPath:@"position"] copy];
        CABasicAnimation *transfromx = [CABasicAnimation animationWithKeyPath:@"position"];
        transfromx.fromValue = value;
        transfromx.toValue = [NSValue valueWithCGPoint:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
        transfromx.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        transfromx.duration = 1.0;
        transfromx.fillMode = kCAFillModeForwards;
        
        //渐变动画
        id opacityValue = [[luanchLayer.presentationLayer valueForKeyPath:@"opacity"] copy];
        CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.fromValue = opacityValue;
        opacity.toValue = [[NSNumber alloc] initWithFloat: 0.1];
        opacity.duration = 1.0;
        
        //缩放动画
        id scaleValue = [[luanchLayer.presentationLayer valueForKeyPath:@"transform.scale"] copy];
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.fromValue = scaleValue;
        scale.toValue = [[NSNumber alloc] initWithFloat: 0.1];
        scale.duration = 1.0;
        scale.fillMode = kCAFillModeForwards;
        scale.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.duration = 1.0;
        group.repeatCount = 1;
        group.animations = @[transfromx,scale];
        group.delegate = self;
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;
        [luanchLayer addAnimation:group forKey:@"animationEndGroup"];
    }
}
#pragma -mark CAAnimationDelegate
- (void)animationDidStart:(CAAnimation *)anim {
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if(_speechStatus == BIAssistantSpeechStatusRecording) {
        @synchronized(self) {
            if(self.launchLayers.count > 0){
                CALayer *layer = [self.launchLayers objectAtIndex:0];
                [self.launchLayers removeObjectAtIndex:0];
                [layer removeAllAnimations];
                [layer removeFromSuperlayer];
            }
            NSLog(@"launchLayers count is %lu, cacheLaunchLayers count is %lu",(unsigned long)self.launchLayers.count, (unsigned long)self.cacheLaunchLayers.count);
        };
    } else {
        
    }
}

#pragma -mark helper
double radians(float degrees) {
    return ( degrees * M_PI ) / 180.0;
}

-(void)dealloc {
    NSLog(@"----> %@ %s dealloc",self,__FUNCTION__);
    if(_launchTimer){
        [_launchTimer invalidate];
        _launchTimer = nil;
    }
}
@end
