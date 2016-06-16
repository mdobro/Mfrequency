//
//  CalculatorViewController.swift
//  Mfrequency
//
//  Created by Thomas Anderson on 6/7/16.
//  Copyright © 2016 CAEN. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController, KeyboardDelegate {
    
    var delegate:ViewController!
    
    var harmonicFrequencies:[Float] = Array(count: 4, repeatedValue: -1)
    
    @IBOutlet weak var distanceTextField: UITextField!
    
    @IBOutlet weak var harmonic0: UILabel!
    @IBOutlet weak var harmonic1: UILabel!
    @IBOutlet weak var harmonic2: UILabel!
    @IBOutlet weak var harmonic3: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyboard = NSBundle.mainBundle().loadNibNamed("KeyboardView", owner: nil, options: nil)[0] as! KeyboardView
        keyboard.delegate = self
        
        distanceTextField.inputView = keyboard
    }
    
    @IBAction func calculateHarmonicValues() {
        if !(distanceTextField.text?.isEmpty)! {
            let distance = Float(distanceTextField.text!)!
            distanceTextField.text = nil
            let fundamental = round(distance * 1115.48566 * 10) / 10
            
            harmonicFrequencies[0] = fundamental
            harmonicFrequencies[1] = fundamental * 2
            harmonicFrequencies[2] = fundamental * 3
            harmonicFrequencies[3] = fundamental * 4
            
            self.harmonic0.text = "\(harmonicFrequencies[0]) Hz"
            self.harmonic1.text = "\(harmonicFrequencies[1]) Hz"
            self.harmonic2.text = "\(harmonicFrequencies[2]) Hz"
            self.harmonic3.text = "\(harmonicFrequencies[3]) Hz"
        }
    }
    
    func addTextToField(charToAdd:String) {
        distanceTextField.text = distanceTextField.text?.stringByAppendingString(charToAdd)
    }
    
    func deleteTextFromField() -> Bool {
        var decimalDeleted = false
        if distanceTextField.text?.characters.last == "." {
            decimalDeleted = true
        }
        
        if !(distanceTextField.text?.isEmpty)! {
            distanceTextField.text?.removeAtIndex((distanceTextField.text?.endIndex.predecessor())!)
        }
        
        return decimalDeleted
    }
    
    @IBAction func saveFrequency0() {
        if harmonicFrequencies[0] != -1 {
            delegate.addData(String(harmonicFrequencies[0]))
        }
    }
    
    @IBAction func saveFrequency1() {
        if harmonicFrequencies[1] != -1 {
            delegate.addData(String(harmonicFrequencies[1]))
        }
    }
    
    @IBAction func saveFrequency2() {
        if harmonicFrequencies[2] != -1 {
            delegate.addData(String(harmonicFrequencies[2]))
        }
    }
    
    @IBAction func saveFrequency3() {
        if harmonicFrequencies[3] != -1 {
            delegate.addData(String(harmonicFrequencies[3]))
        }
    }
    
    // Test if the user taps outside the view
    @IBAction func exitCalculator(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
