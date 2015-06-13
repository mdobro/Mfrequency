//
//  toneGen.h
//  Mfrequency
//
//  Created by Mike Dobrowolski on 6/13/15.
//  Copyright (c) 2015 CAEN. All rights reserved.
//

#ifndef Mfrequency_toneGen_h
#define Mfrequency_toneGen_h

@import CoreAudio;
@import AudioToolbox;
#import "Mfrequency-Bridging-Header.h"

@interface Musician : NSObject
{
    AudioComponentInstance toneUnit;
    
@public
    double frequency;
    double sampleRate;
    double theta;
}

- (void)createToneUnit;
- (void)togglePlay;
- (void)setFrequency:(double)value;
- (void)initHelp;
- (void)stop;



@end

#endif
