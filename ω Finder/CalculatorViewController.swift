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
    
    var harmonicFrequencies:[Float] = Array(repeating: -1, count: 4)
    
    let speedOfSound:Float = 1130.4 // ft/s
    
    var keyboardView:KeyboardView!
    
    var calcUsed = false
    
    @IBOutlet weak var distanceTextField: UITextField!
    
    @IBOutlet weak var harmonic0: UILabel!
    @IBOutlet weak var harmonic1: UILabel!
    @IBOutlet weak var harmonic2: UILabel!
    @IBOutlet weak var harmonic3: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calcUsed = false
        
        let keyboard = Bundle.main.loadNibNamed("KeyboardView", owner: nil, options: nil)?[0] as! KeyboardView
        keyboard.delegate = self
        
        keyboardView = keyboard
        
        distanceTextField.inputView = keyboard
        distanceTextField.becomeFirstResponder()
    }
    
    @IBAction func calculateHarmonicValues() {
        if !(distanceTextField.text?.isEmpty)! {
            calcUsed = true
            
            let distance = (Float(distanceTextField.text!)! * 2)
            //distanceTextField.text = nil
            distanceTextField.resignFirstResponder()
            let fundamental = round((speedOfSound / distance) * 10) / 10
            
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
    
    @IBAction func textFieldBeganEditing(_ sender: UITextField) {
        distanceTextField.text = nil
        keyboardView.reset()
    }
    
    func addTextToField(_ charToAdd:String) {
        distanceTextField.text = distanceTextField.text! + charToAdd
    }
    
    func deleteTextFromField() -> Bool {
        var decimalDeleted = false
        if distanceTextField.text?.characters.last == "." {
            decimalDeleted = true
        }
        
        if !(distanceTextField.text?.isEmpty)! {
            distanceTextField.text?.remove(at: (distanceTextField.text?.characters.index(before: (distanceTextField.text?.endIndex)!))!)
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
    @IBAction func exitCalculator(_ sender: UIButton) {
        if calcUsed {
            delegate.calcFundLabel.text = harmonic0.text
            delegate.calc2ndLabel.text = harmonic1.text
            delegate.calc3rdLabel.text = harmonic2.text
            delegate.calc4thLabel.text = harmonic3.text
            delegate.displayCalculatedValues();
        }
        
        self.dismiss(animated: true, completion: nil)
    }

}
