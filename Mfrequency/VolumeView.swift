//
//  VolumeView.swift
//  Mfrequency
//
//  Created by Thomas Anderson on 6/15/16.
//  Copyright © 2016 CAEN. All rights reserved.
//

import MediaPlayer

class VolumeView: MPVolumeView {

    override func volumeSliderRectForBounds(bounds: CGRect) -> CGRect { return bounds }
    
}
