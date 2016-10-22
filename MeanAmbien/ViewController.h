//
//  ViewController.h
//  MeanAmbien
//
//  Created by User on 15/10/2016.
//  Copyright © 2016 User. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioAnalyzer.h"

typedef NS_ENUM(NSUInteger, MAListeningState){
    MAListeningStateListening,
    MAListeningStateNotListening
};

@interface ViewController : UIViewController<AudioAnalyzerProtocol>{
    
}


@end

