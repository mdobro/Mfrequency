//
//  KeyboardView.swift
//  Mfrequency
//
//  Created by Thomas Anderson on 6/7/16.
//  Copyright © 2016 CAEN. All rights reserved.
//

import UIKit

protocol KeyboardDelegate {
    func addTextToField(charToAdd:String)
    func deleteTextFromField() -> Bool
}

class KeyboardView: UIView {
    
    var delegate:KeyboardDelegate!
    var decimalAdded = false

    @IBAction func addCharacterButtonPress(sender: AnyObject) {
        delegate.addTextToField(sender.titleLabel!!.text!)
    }
    
    @IBAction func addDecimalButtonPress(sender: AnyObject) {
        if !decimalAdded {
            decimalAdded = true
            delegate.addTextToField(sender.titleLabel!!.text!)
        }
    }
    
    @IBAction func deleteCharacterButtonPress(sender: AnyObject) {
        if delegate.deleteTextFromField() {
            decimalAdded = false
        }
    }

}
