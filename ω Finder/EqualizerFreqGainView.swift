//
//  EqualizerViewController.swift
//  Mfrequency
//
//  Created by Thomas Anderson on 6/28/16.
//  Copyright © 2016 CAEN. All rights reserved.
//

import UIKit
import Foundation

class EqualizerFreqGainView: UIView, KeyboardDelegate {
    
    let speakerList = ["Front", "Back", "Left", "Right"]
    let tesiraDSPIP = "60.160.160.123"
    
    var delegate:ViewController!
    var currentTextField:UITextField!
    
    var rowIndex:Int!
    var colIndex:Int!
    
    @IBOutlet weak var freqValueLabel: UILabel!
    @IBOutlet weak var gainValueLabel: UILabel!
    @IBOutlet weak var bandwidthValueLabel: UILabel!
    @IBOutlet weak var bandSegmentedControl: UISegmentedControl!
    @IBOutlet weak var speakerSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var helpText1: UILabel!
    @IBOutlet weak var helpText2: UILabel!
    
    @IBAction func editFrequency(_ sender: UITapGestureRecognizer) {
        var alertTitle:String
        
        switch self.colIndex {
        case 0:
            alertTitle = "Edit Min Frequency"
        case 1:
            alertTitle = "Edit Mid Frequency"
        default:
            alertTitle = "Edit Max Frequency"
        }
        
        let editFreqAlert = UIAlertController(title: alertTitle, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        editFreqAlert.addTextField( configurationHandler: { (textField) in
            textField.placeholder = "Enter Frequency"
            
            let keyboard = Bundle.main.loadNibNamed("KeyboardView", owner: nil, options: nil)?[0] as! KeyboardView
            keyboard.delegate = self
            
            textField.inputView = keyboard
            
            self.currentTextField = textField
        })
        
        let setAction = UIAlertAction(title: "Set", style: .default, handler: { (action) in
            let freqField = editFreqAlert.textFields![0] as UITextField
            let freqString:String = freqField.text!
            var freq = round(Double(freqString)! * 10) / 10
            
            self.freqValueLabel.text = "\(freq)"
            
            switch self.colIndex { // Range of frequencies
            case 0: // Min was set
                // In this case the max value remains the same, and the mid and bandwidth are adjusted
                
                var max = Double(self.delegate.masterpieces[self.rowIndex].2)!
                
                if freq > max {
                    swap(&freq, &max)
                    self.colIndex = 2
                }
                
                let mid = round(sqrt(freq * max) * 10) / 10
                let band = round((max - freq) / mid * 1000) / 1000
                
                self.bandwidthValueLabel.text = "\(band)"
                
                self.delegate.masterpieces[self.rowIndex].0 = String(freq)
                self.delegate.masterpieces[self.rowIndex].1 = String(mid)
                self.delegate.masterpieces[self.rowIndex].2 = String(max)
                self.delegate.masterpieces[self.rowIndex].4 = String(band)
                self.delegate.setRange(freq, second: max)
                self.delegate.saveTable.reloadData()
            case 1: // Mid was set
                // These adjust the min and max based on the bandwidth
                // freq = mid
                
                let band = Double(self.delegate.masterpieces[self.rowIndex].4)!
                let min = round((freq * (band - sqrt(pow(band, 2) + 4))) / -2 * 10) / 10
                let max = round((freq * (band + sqrt(pow(band, 2) + 4))) / 2 * 10) / 10
                
                self.delegate.masterpieces[self.rowIndex].0 = String(min)
                self.delegate.masterpieces[self.rowIndex].1 = String(freq)
                self.delegate.masterpieces[self.rowIndex].2 = String(max)
                self.delegate.setRange(min, second: max)
                self.delegate.saveTable.reloadData()
            default: // Max was set
                // In this case the min value remains the same, and the mid and bandwidth are adjusted
                // freq = max
                
                var min = Double(self.delegate.masterpieces[self.rowIndex].0)!
                
                if freq < min {
                    swap(&freq, &min)
                    self.colIndex = 0
                }
                
                let mid = round(sqrt(freq * min) * 10) / 10
                let band = round((freq - min) / mid * 1000) / 1000
                
                self.bandwidthValueLabel.text = "\(band)"
                
                self.delegate.masterpieces[self.rowIndex].0 = String(min)
                self.delegate.masterpieces[self.rowIndex].1 = String(mid)
                self.delegate.masterpieces[self.rowIndex].2 = String(freq)
                self.delegate.masterpieces[self.rowIndex].4 = String(band)
                self.delegate.setRange(min, second: freq)
                self.delegate.saveTable.reloadData()
            }
        })
        editFreqAlert.addAction(setAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editFreqAlert.addAction(cancelAction)
        
        delegate.present(editFreqAlert, animated: true, completion: nil)
    }
    
    // Keyboard Delegate
    
    func addTextToField(_ charToAdd: String) {
        currentTextField.text = currentTextField.text! + charToAdd
    }
    
    func deleteTextFromField() -> Bool {
        var decimalDeleted = false
        if currentTextField.text?.characters.last == "." {
            decimalDeleted = true
        }
        
        if !(currentTextField.text?.isEmpty)! {
            currentTextField.text?.remove(at: (currentTextField.text?.characters.index(before: (currentTextField.text?.endIndex)!))!)
        }
        
        return decimalDeleted
    }
    
    @IBAction func editGain(_ sender: UITapGestureRecognizer) {
        let editGainAlert = UIAlertController(title: "Edit Gain", message: "\n\n\n\n", preferredStyle: UIAlertControllerStyle.alert)
        
        let slider = UISlider(frame: CGRect(x: 35, y: 55, width: 200, height: 30))
        slider.minimumValue = -10
        slider.maximumValue = 0
        slider.value = Float(gainValueLabel.text!)!
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(gainSliderValueChanged(_:)), for: .valueChanged)
        editGainAlert.view.addSubview(slider)
        
        let label = UILabel(frame: CGRect(x: 114, y: 95, width: 42, height: 21))
        label.text = "\(slider.value)"
        label.textAlignment = .center
        editGainAlert.view.addSubview(label)
        
        // Set button
        let setAction = UIAlertAction(title: "Set", style: .default, handler: { (action) in
            let gain = "\(round(slider.value * 10) / 10)"
            
            self.gainValueLabel.text = gain
            
            self.delegate.masterpieces[self.rowIndex].3 = gain
            self.delegate.saveTable.reloadData()
        })
        editGainAlert.addAction(setAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editGainAlert.addAction(cancelAction)
        
        delegate.present(editGainAlert, animated: true, completion: nil)
    }
    
    func gainSliderValueChanged(_ sender: UISlider) {
        let gainController = delegate.presentedViewController as! UIAlertController
        let gainLabel = gainController.view.subviews[2] as! UILabel
        
        gainLabel.text = "\(round(sender.value * 10) / 10)"
    }
    
    @IBAction func editBandwidth(_ sender: UITapGestureRecognizer) {
        let editBandwidthAlert = UIAlertController(title: "Edit Bandwidth", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        editBandwidthAlert.addTextField( configurationHandler: { (textField) in
            textField.placeholder = "Enter Bandwidth"
            
            let keyboard = Bundle.main.loadNibNamed("KeyboardView", owner: nil, options: nil)?[0] as! KeyboardView
            keyboard.delegate = self
            
            textField.inputView = keyboard
            
            self.currentTextField = textField
        })
        
        let setAction = UIAlertAction(title: "Set", style: .default, handler: { (action) in
            let bandwidthField = editBandwidthAlert.textFields![0] as UITextField
            let bandwidthString:String = bandwidthField.text!
            let bandwidth = round(Double(bandwidthString)! * 10) / 10
            let mid = Double(self.delegate.masterpieces[self.rowIndex].1)!
            
            self.bandwidthValueLabel.text = "\(bandwidth)"
            
            let min = round((mid * (bandwidth - sqrt(pow(bandwidth, 2) + 4))) / -2 * 10) / 10
            let max = round((mid * (bandwidth + sqrt(pow(bandwidth, 2) + 4))) / 2 * 10) / 10
            
            self.delegate.masterpieces[self.rowIndex].0 = String(min)
            self.delegate.masterpieces[self.rowIndex].1 = String(mid)
            self.delegate.masterpieces[self.rowIndex].2 = String(max)
            self.delegate.masterpieces[self.rowIndex].4 = String(bandwidth)
            self.delegate.setRange(min, second: max)
            self.delegate.saveTable.reloadData()
        })
        editBandwidthAlert.addAction(setAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editBandwidthAlert.addAction(cancelAction)
        
        delegate.present(editBandwidthAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func setFreqGain() {
        let stringToSend = "\"Room Res EQ " + speakerList[speakerSegmentedControl.selectedSegmentIndex] + "\" set frequencyGain \(bandSegmentedControl.selectedSegmentIndex + 1) {\"frequency\":\(freqValueLabel.text!) \"gain\":\(gainValueLabel.text!)}"
        print(stringToSend)
        
        let DSPPORT:UInt16 = 23
        var dspsocket: GCDAsyncSocket
        
        do {
            dspsocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            try dspsocket.connect(toHost: tesiraDSPIP, onPort: DSPPORT)
        }
        catch {
            print("Error with DSP socket")
        }
        
        dspsocket.write(stringToSend.data(using: String.Encoding.utf8), withTimeout: -1.0, tag: 0)
        dspsocket.readData(withTimeout: -1.0, tag: 0)
    }
    
    @IBAction func setBandwidth() {
        let stringToSend = "\"Room Res EQ " + speakerList[speakerSegmentedControl.selectedSegmentIndex] + "\" set bandwidth \(bandSegmentedControl.selectedSegmentIndex + 1) \(bandwidthValueLabel.text!)"
        print(stringToSend)
        
        let DSPPORT:UInt16 = 23
        var dspsocket: GCDAsyncSocket
        
        do {
            dspsocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            try dspsocket.connect(toHost: tesiraDSPIP, onPort: DSPPORT)
        }
        catch {
            print("Error with DSP socket")
        }
        
        dspsocket.write(stringToSend.data(using: String.Encoding.utf8), withTimeout: -1.0, tag: 0)
        dspsocket.readData(withTimeout: -1.0, tag: 0)
    }
    
    @IBAction func cancelSetFreqGain() {
        closeView()
    }
    
    @IBAction func infoButtonPressed() {
        if helpText1.alpha == 0 {
            helpText1.alpha = 1
            helpText2.alpha = 1
        }
        else { // alpha == 1
            helpText1.alpha = 0
            helpText2.alpha = 0
        }
    }
    
    func closeView() {
        //self.superview!.removeFromSuperview()
        self.removeFromSuperview()
    }
}
