//
//  ViewController.m
//  MeanAmbien
//
//  Created by User on 15/10/2016.
//  Copyright © 2016 User. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    
    UIButton* listenToAmbienButton;
    UILabel* averageFrequencyLabel;
    
    MAListeningState listeningState;
    
    AudioAnalyzer* audioAnalyzer;
}

@end

@implementation ViewController

-(instancetype) init{
    self = [super init];
    
    audioAnalyzer = [AudioAnalyzer new];
    audioAnalyzer.delegate = self;
    
    listeningState = MAListeningStateNotListening;
    
    listenToAmbienButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [listenToAmbienButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    averageFrequencyLabel = [UILabel new];
    [averageFrequencyLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector( enteringBackgroundNotification)
                                                 name:@"enteringBackground"
                                               object:nil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    averageFrequencyLabel.textAlignment = NSTextAlignmentCenter;
    averageFrequencyLabel.font = [UIFont systemFontOfSize:24.0f weight:UIFontWeightBold];
    averageFrequencyLabel.text = @"0.00 Hz";
    
    [listenToAmbienButton setTitle:@"Listen" forState:UIControlStateNormal];
    listenToAmbienButton.titleLabel.font = [UIFont systemFontOfSize:24.0f weight:UIFontWeightBold];
    listenToAmbienButton.titleLabel.textColor = [UIColor orangeColor];
    listenToAmbienButton.layer.cornerRadius = 10;
    [listenToAmbienButton addTarget:self action:@selector(toggleListen) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:averageFrequencyLabel];
    [self.view addSubview:listenToAmbienButton];
    
    [self setUpConstraints];
}

-(void) toggleListen{
    if(listeningState == MAListeningStateNotListening){
        [self setStateListen];
        
    } else if(listeningState == MAListeningStateListening) {
        [self setStateNotListen];
    
    }
}

-(void) averageFrequencyUpdated:(float) averageFrequency{
    averageFrequencyLabel.text = [NSString stringWithFormat:@"%4.2f Hz", averageFrequency];
}

-(void) enteringBackgroundNotification{
    [self setStateNotListen];
}

-(void) setStateListen{
    listeningState = MAListeningStateListening;
    [audioAnalyzer startSession];
    [listenToAmbienButton setTitle:@"Stop listening" forState:UIControlStateNormal];
}
-(void) setStateNotListen{
    listeningState = MAListeningStateNotListening;
    [audioAnalyzer stopSession];
    [listenToAmbienButton setTitle:@"Listen" forState:UIControlStateNormal];
}

-(void) setUpConstraints{
    //just some constraints
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:averageFrequencyLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:averageFrequencyLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:averageFrequencyLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:listenToAmbienButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0f constant:-5.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:listenToAmbienButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:listenToAmbienButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0f constant:-20.0f]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
