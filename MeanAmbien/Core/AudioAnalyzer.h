//
//  AudioAnalyzer.h
//  MeanAmbien
//
//  Created by User on 15/10/2016.
//  Copyright © 2016 User. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioAnalyzerProtocol;

@interface AudioAnalyzer : NSObject<AVCaptureAudioDataOutputSampleBufferDelegate>

@property(nonatomic, weak) id<AudioAnalyzerProtocol> delegate;

-(void) startSession;
-(void) stopSession;

@end

@protocol AudioAnalyzerProtocol <NSObject>
@required

-(void) averageFrequencyUpdated:(float) averageFrequency;

@end
