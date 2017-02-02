//
//  KeyboardView.swift
//  Mfrequency
//
//  Created by Thomas Anderson on 6/7/16.
//  Copyright © 2016 CAEN. All rights reserved.
//

import UIKit

protocol KeyboardDelegate {
    func addTextToField(_ charToAdd:String)
    func deleteTextFromField() -> Bool
}

class KeyboardView: UIView {
    
    var delegate:KeyboardDelegate!
    var decimalAdded = false

    @IBAction func addCharacterButtonPress(_ sender: AnyObject) {
        delegate.addTextToField(sender.titleLabel!!.text!)
    }
    
    @IBAction func addDecimalButtonPress(_ sender: AnyObject) {
        if !decimalAdded {
            decimalAdded = true
            delegate.addTextToField(sender.titleLabel!!.text!)
        }
    }
    
    @IBAction func deleteCharacterButtonPress(_ sender: AnyObject) {
        if delegate.deleteTextFromField() {
            decimalAdded = false
        }
    }
    
    func reset() {
        decimalAdded = false
    }

}
