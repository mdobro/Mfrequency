//
//  ViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 6/13/15.
//  Copyright (c) 2015 CAEN. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, RangeDelegate, KeyboardDelegate {
    let musicMan = Musician();
    let ios9BlueColor = UIColor(red: 0, green: 122/225, blue: 1, alpha: 1)
    
    var masterpieces = Array<(String, String, String, String, String)>()
    
    var selectedRange:NSIndexPath = NSIndexPath(forItem: 0, inSection: 0) //range of slider
    
    var sliderRate:Float = 0.5
    
    var savedRange:String = "" //user saved range
    var curGain:String = ""
    var shouldPlayRange = false
    var increaseWhilePlayingRange = true
    var startRange = 0.0
    var endRange = 0.0
    
    var upTimer:NSTimer!
    var downTimer:NSTimer!
    var rangeTimer:NSTimer? = nil

    var whitePlayer = AVAudioPlayer()
    var pinkPlayer = AVAudioPlayer()
    
    var currentTextField:UITextField!
    var currentFrequencyValue:Float = 50.0
    
    @IBOutlet weak var slider: OBSlider!
    @IBOutlet weak var currentFreq: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var calculatorButton: UIButton!
    @IBOutlet weak var saveTable: UITableView!
    @IBOutlet weak var volumeButton: UIBarButtonItem!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after load
        // view over background image to create fade effect over background
        // 1 = mainView
        // 2 = tableView
        masterpieces.append(("Min", "Mid", "Max", "Gain", "BW"))

        self.view.viewWithTag(1)?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.55)
        self.view.viewWithTag(2)?.backgroundColor = UIColor.clearColor()
        
        //button & slider set-up
        playButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        currentFreq.textColor = UIColor.blackColor()
        currentFreq.text = "50.0"
        
        //settingButton.setImage(UIImage(named: "sliderSettingGray"), forState: .Disabled)
        //calculatorButton.setImage(UIImage(named: "calculatorGray"), forState: .Disabled)
        
        //synthesiser set-up
        musicMan.setFrequency(20)
        musicMan.initHelp()
        
        //white & pink noise setup
        if let path = NSBundle.mainBundle().pathForResource("White Noise", ofType: "wav") {
            let url = NSURL(fileURLWithPath: path)
            do {
                whitePlayer = try AVAudioPlayer(contentsOfURL: url)
                whitePlayer.numberOfLoops = -1
            } catch {
                print("white noise player failed!", true)
            }
        } else {
            print("white noise file missing!")
        }
        
        if let path = NSBundle.mainBundle().pathForResource("Pink Noise", ofType: "wav") {
            let url = NSURL(fileURLWithPath: path)
            do {
                pinkPlayer = try AVAudioPlayer(contentsOfURL: url)
                pinkPlayer.numberOfLoops = -1
            } catch {
                print("pink noise failed", true)
            }
        } else {
            print("pink noise file missing!")
        }
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplicationWillResignActiveNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(volumeDidChange), name: "AVSystemController_SystemVolumeDidChangeNotification", object: nil)
        
        if AVAudioSession().outputVolume == 0 {
            volumeButton.image = UIImage(imageLiteral: "mute")
        }
    }
    
    func appMovedToBackground() {
        //make sure slider isn't incrementing
        musicMan.stop()
        playButton.setTitle("Play", forState: .Normal)
        playButton.setTitleColor(.greenColor(), forState: .Normal)
        if upTimer != nil {
            upTimer.invalidate()
        }
        if downTimer != nil {
            downTimer.invalidate()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "RangeSegue" {
            let controller = segue.destinationViewController as! RangePopoverViewController
            controller.delegate = self
        }
        else if segue.identifier == "InfoSegue" {
            let controller = segue.destinationViewController as! InfoViewController
            controller.delegate = self
        }
        else if segue.identifier == "SettingSegue" {
            let controller = segue.destinationViewController as! SettingViewController
            controller.delegate = self
        }
        else if segue.identifier == "CalculatorSegue" {
            let controller = segue.destinationViewController as! CalculatorViewController
            controller.delegate = self
        }
    }
    
    func addData(min:String, max:String = " ") {
        var mid = " "
        var band = " "
        
        // Setup for adding the alert
        let setGainAlert = UIAlertController(title: "Set Gain", message: "\n\n\n\n", preferredStyle: UIAlertControllerStyle.Alert)
        
        let slider = UISlider(frame: CGRectMake(35, 55, 200, 30))
        slider.minimumValue = 0
        slider.maximumValue = 10
        slider.value = 5
        slider.continuous = true
        slider.addTarget(self, action: #selector(gainSliderValueChanged(_:)), forControlEvents: .ValueChanged)
        setGainAlert.view.addSubview(slider)
        
        let label = UILabel(frame: CGRectMake(114, 95, 42, 21))
        label.text = "-\(slider.value)"
        label.textAlignment = .Center
        setGainAlert.view.addSubview(label)
        
        // Set button
        let setAction = UIAlertAction(title: "Set", style: .Default, handler: { (action) in
            let gain = "-\(round(slider.value * 10) / 10)"
            if max != " " { // Range
                let minNum = Double(min)!
                let maxNum = Double(max)!
                mid = String(round(sqrt(minNum * maxNum) * 10) / 10)
                band = String(round((maxNum - minNum) / Double(mid)! * 1000) / 1000)
            }
            let toAppend = (min, mid, max, gain, band)
            self.masterpieces.append(toAppend)
            self.saveTable.reloadData()
        })
        setGainAlert.addAction(setAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        setGainAlert.addAction(cancelAction)
        
        if presentedViewController == nil {
            self.presentViewController(setGainAlert, animated: true, completion: nil)
        }
        else {
            presentedViewController!.presentViewController(setGainAlert, animated: true, completion: nil)
        }
    }
    
    func gainSliderValueChanged(sender: UISlider) {
        if let gainController = self.presentedViewController as? UIAlertController {
            let label = gainController.view.subviews[2] as! UILabel
            
            label.text = "-\(round(sender.value * 10) / 10)"
        }
        else {
            let gainController = self.presentedViewController!.presentedViewController as! UIAlertController
            let label = gainController.view.subviews[2] as! UILabel
            
            label.text = "-\(round(sender.value * 10) / 10)"
        }
    }
    
    @IBAction func ButtonPress(sender: AnyObject) {
        if (sender.titleLabel!!.text == "Play") {
            sender.setTitle("Stop", forState: .Normal)
            sender.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            musicMan.togglePlay()
            if shouldPlayRange {
                playRange()
            }
        } else if sender.titleLabel!!.text == "Stop"{
            sender.setTitle("Play", forState: .Normal)
            sender.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
            musicMan.stop()
            if shouldPlayRange {
                rangeTimer?.invalidate()
                rangeTimer = nil
            }
        } else if sender.titleLabel!!.text == "Save Frequency" {
            if let _ = Float(currentFreq.text!) {
                addData(currentFreq.text!)
                //saveTable.reloadData()
            }
        } else if sender.titleLabel!!.text == "Save Range" {
            if let _ = Float(currentFreq.text!) {
                sender.setTitle("End Save Range", forState: .Normal)
                sender.setTitleColor(UIColor.redColor(), forState: .Normal)
                savedRange = currentFreq.text!
            }
        } else if sender.titleLabel!!.text == "End Save Range" {
            if Double(currentFreq.text!) < Double(savedRange) {
                addData(currentFreq.text!, max: savedRange)
            } else {
                addData(savedRange, max: currentFreq.text!)
            }
            sender.setTitle("Save Range", forState: .Normal)
            sender.setTitleColor(ios9BlueColor, forState: .Normal)
            //saveTable.reloadData()
        } else if sender.titleLabel!!.text == "▶️" {
            upTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: #selector(ViewController.upHeldDown(_:)), userInfo: nil, repeats: true)
            slider.value += sliderRate
            currentFrequencyValue = slider.value
            musicMan.setFrequency(Double(slider.value))
            let roundedNum = round(slider.value * 10) / 10
            currentFreq.text = "\(roundedNum)"
            NSRunLoop.currentRunLoop().addTimer(upTimer, forMode: NSDefaultRunLoopMode)
            rangeTimer?.invalidate()
            rangeTimer = nil
        } else if sender.titleLabel!!.text == "◀️" {
            downTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: #selector(ViewController.downHeldDown(_:)), userInfo: nil, repeats: true)
            slider.value -= sliderRate
            currentFrequencyValue = slider.value
            let roundedNum = round(slider.value * 10) / 10
            currentFreq.text = "\(roundedNum)"
            musicMan.setFrequency(Double(slider.value))
            NSRunLoop.currentRunLoop().addTimer(downTimer, forMode: NSDefaultRunLoopMode)
            rangeTimer?.invalidate()
            rangeTimer = nil
        } else if sender.titleLabel!!.text == "White Noise" {
            if pinkPlayer.playing {
                pinkPlayer.stop()
            }
            if whitePlayer.playing {
                whitePlayer.stop()
            } else {
                whitePlayer.play()
            }
        } else if sender.titleLabel!!.text == "Pink Noise" {
            if whitePlayer.playing {
                whitePlayer.stop()
            }
            if pinkPlayer.playing {
                pinkPlayer.stop()
            } else {
                pinkPlayer.play()
            }
        }
    }
    
    @IBAction func cancelSaveRange(sender: AnyObject) {
        sender.setTitle("Save Range", forState: .Normal)
        sender.setTitleColor(ios9BlueColor, forState: .Normal)
    }
    
    @IBAction func setFrequencyButton(sender: AnyObject) {
        let setFreqAlert = UIAlertController(title: "Set Frequency", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        setFreqAlert.addTextFieldWithConfigurationHandler( { (textField) in
            textField.placeholder = "Enter Frequency"
            
            let keyboard = NSBundle.mainBundle().loadNibNamed("KeyboardView", owner: nil, options: nil)[0] as! KeyboardView
            keyboard.delegate = self
            
            textField.inputView = keyboard
            
            self.currentTextField = textField
        })
        
        let setAction = UIAlertAction(title: "Set", style: .Default, handler: { (action) in
            let freqField = setFreqAlert.textFields![0] as UITextField
            let freqString:String = freqField.text!
            let freq = round(Double(freqString)! * 10) / 10
            
            self.currentFrequencyValue = Float(freq)
            self.slider.value = Float(freq)
            self.currentFreq.text = "\(freq)"
            self.musicMan.setFrequency(freq)
        })
        setFreqAlert.addAction(setAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        setFreqAlert.addAction(cancelAction)
        
        self.presentViewController(setFreqAlert, animated: true, completion: nil)
    }
    
    func addTextToField(charToAdd:String) {
        currentTextField.text = currentTextField.text?.stringByAppendingString(charToAdd)
    }
    
    func deleteTextFromField() -> Bool {
        var decimalDeleted = false
        if currentTextField.text?.characters.last == "." {
            decimalDeleted = true
        }
        
        if !(currentTextField.text?.isEmpty)! {
            currentTextField.text?.removeAtIndex((currentTextField.text?.endIndex.predecessor())!)
        }
        
        return decimalDeleted
    }
    
    func setRange(first: Double, second: Double) {
        self.startRange = first
        self.endRange = second
    }
    
    func playRange() {
        if rangeTimer == nil {
            rangeTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: #selector(ViewController.rangeHelper(_:)), userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(rangeTimer!, forMode: NSDefaultRunLoopMode)
        }
    }
    
    func rangeHelper(sender:AnyObject) {
        if increaseWhilePlayingRange {
           upForRange()
            if currentFrequencyValue >= Float(endRange) {
                increaseWhilePlayingRange = false
            }
        } else {
            downForRange()
            if currentFrequencyValue <= Float(startRange) {
                increaseWhilePlayingRange = true
            }
        }
    }
    
    func upForRange() { // Allows the frequency to go past the end of the slider
        currentFrequencyValue += sliderRate
        slider.value = currentFrequencyValue
        musicMan.setFrequency(Double(currentFrequencyValue))
        currentFreq.text = "\(currentFrequencyValue)"
    }
    
    func downForRange() {
        currentFrequencyValue -= sliderRate
        slider.value = currentFrequencyValue
        musicMan.setFrequency(Double(currentFrequencyValue))
        currentFreq.text = "\(currentFrequencyValue)"
    }
    
    func updateSliderRate(rate:Float) {
        sliderRate = rate
    }
    
    func upHeldDown(sender:AnyObject) { // Doesn't allow the frequency to go past the end of the slider
        slider.value += sliderRate
        currentFrequencyValue = slider.value
        musicMan.setFrequency(Double(slider.value))
        currentFreq.text = "\(slider.value)"
    }
    
    func downHeldDown(sender:AnyObject) {
        slider.value -= sliderRate
        currentFrequencyValue = slider.value
        musicMan.setFrequency(Double(slider.value))
        currentFreq.text = "\(slider.value)"
    }
    
    @IBAction func releaseVolArrow(sender: UIButton) {
        if sender.titleLabel!.text == "▶️" {
            upTimer.invalidate()
        } else if sender.titleLabel!.text == "◀️" {
            downTimer.invalidate()
        }
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        let freq = round(sender.value * 10)/10
        currentFrequencyValue = freq
        currentFreq.text = "\(freq)"
        musicMan.setFrequency(Double(freq))
        
        //mangage range player
        shouldPlayRange = false
        rangeTimer?.invalidate()
        rangeTimer = nil
    }
    
    //RangeDelgate
    func rangeDidChange(range: Int) {
        if range == 0 {
            slider.minimumValue = 50
            slider.maximumValue = 500
            slider.value = 50
        } else if range == 1 {
            slider.minimumValue = 10
            slider.maximumValue = 1000
            slider.value = 10
        } else {
            slider.minimumValue = 20
            slider.maximumValue = 20000
            slider.value = 20
        }
        currentFreq.text = "\(slider.value)"
        musicMan.setFrequency(Double(slider.value))
        rangeTimer?.invalidate()
        rangeTimer = nil
        shouldPlayRange = false
    }
    
    //swipe gesture (to delete cells)
    @IBAction func CellSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            if sender.direction == .Right {
                let point = sender.locationInView(saveTable)
                let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
                let toDeleteDataIndex = toDeleteIndex?.row
                if toDeleteIndex != nil && toDeleteDataIndex != 0  {
                    self.masterpieces[toDeleteDataIndex!] = ("", "", "", "", "")
                    self.saveTable.reloadRowsAtIndexPaths([toDeleteIndex!], withRowAnimation: .Right)
                    self.masterpieces.removeAtIndex(1)
                    self.saveTable.reloadData()
                }
            } else {
                let point = sender.locationInView(saveTable)
                let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
                let toDeleteDataIndex = toDeleteIndex?.row
                if toDeleteIndex != nil && toDeleteDataIndex != 0 {
                    self.masterpieces[toDeleteDataIndex!] = ("", "", "", "", "")
                    self.saveTable.reloadRowsAtIndexPaths([toDeleteIndex!], withRowAnimation: .Left)
                    self.masterpieces.removeAtIndex(1)
                    self.saveTable.reloadData()
                }
            }
        }
    }
    
    @IBAction func editGainForCell(sender: AnyObject) {
        let point = sender.locationInView(saveTable)
        let toEditIndex = saveTable.indexPathForRowAtPoint(point)
        let toEditDataIndex = toEditIndex?.row
        if toEditDataIndex != nil && toEditDataIndex != 0 {
            
            let editGainAlert = UIAlertController(title: "Edit Gain", message: "\n\n\n\n", preferredStyle: UIAlertControllerStyle.Alert)
            
            let slider = UISlider(frame: CGRectMake(35, 55, 200, 30))
            slider.minimumValue = 0
            slider.maximumValue = 10
            slider.value = 5
            slider.continuous = true
            slider.addTarget(self, action: #selector(gainSliderValueChanged(_:)), forControlEvents: .ValueChanged)
            editGainAlert.view.addSubview(slider)
            
            let label = UILabel(frame: CGRectMake(114, 95, 42, 21))
            label.text = "-\(slider.value)"
            label.textAlignment = .Center
            editGainAlert.view.addSubview(label)
            
            // Set button
            let setAction = UIAlertAction(title: "Set", style: .Default, handler: { (action) in
                let gain = "-\(round(slider.value * 10) / 10)"
                self.masterpieces[toEditDataIndex!].3 = gain
                self.saveTable.reloadData()
            })
            editGainAlert.addAction(setAction)
            
            // Cancel button
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            editGainAlert.addAction(cancelAction)
            
            presentViewController(editGainAlert, animated: true, completion: nil)
        }

    }
    
    
    //table stuff
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let data = masterpieces[indexPath.row]
        if data.0 != "Min" {
            if shouldPlayRange {
                rangeTimer?.invalidate()
                rangeTimer = nil
                shouldPlayRange = false
            }
            
            let note = (data.0 as NSString).doubleValue
            let note2 = (data.2 as NSString).doubleValue
            slider.value = Float(note)
            musicMan.setFrequency(note)
            if data.2 != " " {
                //if the cell contains a range
                shouldPlayRange = true
                setRange(note, second: note2)
                currentFreq.text = data.0 + " - " + data.2
                //if this is already playing
                if playButton.titleLabel!.text == "Stop" {
                    playRange()
                }
            }
            else { // Not a range
                currentFreq.text = data.0
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterpieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        masterpieces.sortInPlace({(col1:(String, String, String, String, String), col2:(String, String, String, String, String)) -> (Bool) in
            let string1:String
            let string2:String
            //impliment sort by top col selection
            //impliment least to great/great to least sort
            string1 = col1.0 // sorts by min from least to greatest
            string2 = col2.0
            let d1 = (string1 as NSString).doubleValue
            let d2 = (string2 as NSString).doubleValue
            if (d1 < d2) {
                return true
            }
            return false
        })
        let item = masterpieces[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("frequency cell")!
        let myFont = UIFont(name: "Arial", size: 32)
        cell.backgroundColor = UIColor.clearColor()
        for i in 0..<5 {
            let val:String
            switch i {
            case 0: val = item.0
            case 1: val = item.1
            case 2: val = item.2
            case 3: val = item.3
            default: val = item.4
            }
            let view = cell.contentView.subviews[i] as! UILabel
            view.text = val
            view.font = myFont
            view.textAlignment = .Center
        }
        return cell
    }

    //share button
    @IBAction func shareSheet(sender: AnyObject) {
        
        var sendString:String = ""
        for item in masterpieces {
            sendString += item.0 + " " + item.1 + " " + item.2 + " " + item.3 + " " + item.4 + "\n"
        }
        print(sendString)
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [sendString], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = []
        
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // Volume button image update
    
    func volumeDidChange(notification:NSNotification) {
        let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
        
        if volume == 0 {
            volumeButton.image = UIImage(imageLiteral: "mute")
        }
        else {
            volumeButton.image = UIImage(imageLiteral: "volume")
        }
    }
}

// Information screen view controller
class InfoViewController:UIViewController {
    
    var delegate:ViewController!
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(white: 1, alpha: 0.6)
    }
    
    @IBAction func dismiss(sender:AnyObject) {
        delegate.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

// Scroll speed setting popup view controller
class SettingViewController:UIViewController {
    
    @IBOutlet var slider:UISlider!
    @IBOutlet var sliderValue:UILabel!
    
    var delegate:ViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.value = delegate.sliderRate
        sliderValue.text = "\(delegate.sliderRate)"
    }
    
    @IBAction func sliderValueChanged(sender:UISlider) {
        let value:Float = round(sender.value * 10)/10
        sliderValue.text = "\(value)"
        
        delegate.sliderRate = value  // Update the rate
    }
    
}