//
//  AudioAnalyzer.m
//  MeanAmbien
//
//  Created by User on 15/10/2016.
//  Copyright © 2016 User. All rights reserved.
//

#import "AudioAnalyzer.h"
#import <Accelerate/Accelerate.h>

#define SAMPLE_SIZE 1024
#define SAMPLING_FREQUENCY 44100.0
#define HALF_SAMPLE SAMPLE_SIZE/2
#define LOG2N log2f((float)SAMPLE_SIZE)

#define UPDATE_LAG 10

@interface AudioAnalyzer (){
    AVCaptureSession* captureSession;
    COMPLEX_SPLIT A;
    float* magnitudes;
    int frequenciesCounted;
    float avgFrequency;
    float *convertedSamples;
    
    float* hammingWindowVector;
    
    int updatedSecondsAgo;
    FFTSetup fftSetup;
}

@end

@implementation AudioAnalyzer

-(instancetype) init{
    self = [super init];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:NULL];
    [session setMode:AVAudioSessionModeMeasurement error:NULL];
    [session setActive:YES error:NULL];
    
    // Optional - default gives 1024 samples at 44.1kHz
    //[session setPreferredIOBufferDuration:samplesPerSlice/session.sampleRate error:NULL];
    
    hammingWindowVector = (float*) malloc(sizeof(float)*SAMPLE_SIZE);
    // Configure the capture session (strongly-referenced instance variable, otherwise the capture stops after one slice)
    captureSession = [AVCaptureSession new];
    
    // Configure audio device input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    [captureSession addInput:input];
    
    A.realp = (float*) malloc(sizeof(float) * HALF_SAMPLE);
    A.imagp = (float*) malloc(sizeof(float) * HALF_SAMPLE);
    
    
    magnitudes = (float*)(malloc(sizeof(float)*HALF_SAMPLE));
    convertedSamples = (float*)malloc(sizeof(float) * SAMPLE_SIZE);
    
    // Configure audio data output
    AVCaptureAudioDataOutput *output = [AVCaptureAudioDataOutput new];
    dispatch_queue_t queue = dispatch_queue_create("audio_analysis", DISPATCH_QUEUE_SERIAL);
    [output setSampleBufferDelegate:self queue:queue];
    [captureSession addOutput:output];
    
    
    fftSetup = vDSP_create_fftsetup(LOG2N, FFT_RADIX2);
    
    
    
    avgFrequency = 0.0;
    frequenciesCounted = 0;
    updatedSecondsAgo = 0;
    
 
    return self;
}

-(void) startSession{
    [captureSession startRunning];
}

-(void) stopSession{
    [captureSession stopRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    //get a pointer to the audio bytes, for future dft - audio bytes are amplitudes over time
    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
    CMBlockBufferRef audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffset;
    size_t totalLength;
    char *samples;
    CMBlockBufferGetDataPointer(audioBuffer, 0, &lengthAtOffset, &totalLength, &samples);
    
    CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *desc = CMAudioFormatDescriptionGetStreamBasicDescription(format);
    
    
    if (desc->mChannelsPerFrame == 1 && desc->mBitsPerChannel == 16) {
        memset(convertedSamples,0.0, sizeof(float)*SAMPLE_SIZE);
        vDSP_vflt16((short *)samples, 1, convertedSamples, 1, numSamples);
        
        //Make the data readable - update slower than data arrives - also, no unnecessary computations
        if(updatedSecondsAgo >= UPDATE_LAG){
            //Analyze sample from mic
            [self frequencesFromSampleInput:convertedSamples sampleSize:numSamples];
            updatedSecondsAgo = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate averageFrequencyUpdated:avgFrequency];
            });
        } else {
            updatedSecondsAgo++;
        }
    }
}

-(void) frequencesFromSampleInput:(float*) sampleInput sampleSize:(long) sampleSize{
    
    if(sampleSize == SAMPLE_SIZE){ //doesn't make any sense
    memset(A.realp, 0.0, sizeof(float)*HALF_SAMPLE);
    memset(A.imagp, 0.0, sizeof(float)*HALF_SAMPLE);
    memset(magnitudes, 0.0, sizeof(float)*HALF_SAMPLE);
    memset(hammingWindowVector, 0.0,sizeof(float)*sampleSize);
    vDSP_hamm_window(hammingWindowVector, sampleSize/2, 0); // smooth out the picture - results are closer to the reality
    vDSP_vmul(sampleInput, 1, hammingWindowVector, 1, sampleInput, 1, sampleSize);
    
    
    //We need to transform our input into the form, edible by fft
    vDSP_ctoz((COMPLEX *) sampleInput, 2, &A, 1, sampleSize);
    //Carry out a Forward FFT transform. This will allow to get the power spectrum.
    vDSP_fft_zrip(fftSetup, &A, 1, LOG2N, FFT_FORWARD);
    
    
    float totalIntensity = 0.0;
    avgFrequency = 0.0;
    vDSP_zvmags(&A, 1, magnitudes, 1, HALF_SAMPLE);
        
    //The mean frequency is calculated as follows Sum(intensity_i*frequency_i)/Sum(intensity_i)
    //So this one calculates enom and denom
        for(int i = 1; i < HALF_SAMPLE; i++){
            float mag = magnitudes[i];
            float frequency = (i * SAMPLING_FREQUENCY) / SAMPLE_SIZE;
            avgFrequency += mag*frequency;
            totalIntensity += mag;
        }
        
        if(totalIntensity != 0){
            avgFrequency /= totalIntensity;
        }
        
    }

}

-(void) dealloc{
    [captureSession stopRunning];
    free(magnitudes);
    free(convertedSamples);
    free(A.imagp);
    free(A.realp);
    free(hammingWindowVector);
}

@end
