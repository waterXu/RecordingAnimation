//
//  BIAssistantRecordAnimationView.h
//  RecordingAnimation
//
//  Created by xuyanlan on 2018/8/4.
//  Copyright © 2018年 xuyanlan. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,BIAssistantSpeechStatus) {
    BIAssistantSpeechStatusNormal,
    BIAssistantSpeechStatusRecording,
    BIAssistantSpeechStatusRecognising,
};
@interface BIAssistantRecordAnimationView : UIView

@property(nonatomic, assign) BIAssistantSpeechStatus speechStatus;

- (void)updateRecordingVolume:(NSInteger)level;


@end
