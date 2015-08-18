//
//  ViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 6/13/15.
//  Copyright (c) 2015 CAEN. All rights reserved.
//

import UIKit
import AVFoundation

//slide for cell deletion
extension UIView {
    // Name this function in a way that makes sense to you...
    // slideFromLeft, slideRight, slideLeftToRight, etc. are great alternative names
    func slideOutToRight(duration: NSTimeInterval = 1.0, completion: () -> Void) {
        // Create a CATransition animation
        let slideOutToRightTransition = CATransition()
        
        CATransaction.setCompletionBlock(completion)
        
        // Customize the animation's properties
        slideOutToRightTransition.type = kCATransitionPush
        slideOutToRightTransition.subtype = kCATransitionFromLeft
        slideOutToRightTransition.duration = duration
        slideOutToRightTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideOutToRightTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.addAnimation(slideOutToRightTransition, forKey: "slideOutToRightTransition")
    }
    
    func slideOutToLeft(duration: NSTimeInterval = 1.0, completion: () -> Void) {
        // Create a CATransition animation
        let slideOutToLeftTransition = CATransition()
        
        CATransaction.setCompletionBlock(completion)
        
        // Customize the animation's properties
        slideOutToLeftTransition.type = kCATransitionPush
        slideOutToLeftTransition.subtype = kCATransitionFromRight
        slideOutToLeftTransition.duration = duration
        slideOutToLeftTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideOutToLeftTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.addAnimation(slideOutToLeftTransition, forKey: "slideOutToLeftTransition")
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, RangeDelegate {
    let musicMan = Musician();
    
    var masterpieces = Array<(String, String, String, String)>()
    
    var selectedRange:NSIndexPath = NSIndexPath(forItem: 0, inSection: 0) //range of slider
    
    var savedRange:String = "" //user saved range
    var shouldPlayRange = false
    var increaseWhilePlayingRange = true
    var startRange = 0.0
    var endRange = 0.0
    
    var upTimer:NSTimer!
    var downTimer:NSTimer!
    var rangeTimer:NSTimer? = nil

    var whitePlayer = AVAudioPlayer()
    var pinkPlayer = AVAudioPlayer()
    
    @IBOutlet weak var slider: OBSlider!
    @IBOutlet weak var currentFreq: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after load
        //view over background image to create fade effect over background
        //1 = mainView
        //2 = tableView
        masterpieces.append("Min", "Mid", "Max", "Band")

        self.view.viewWithTag(1)?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.55)
        self.view.viewWithTag(2)?.backgroundColor = UIColor.clearColor()
        
        //button & slider set-up
        playButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        currentFreq.textColor = UIColor.blackColor()
        currentFreq.text = "50.0"
        
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
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "RangeSegue" {
            let controller = segue.destinationViewController as! RangePopoverViewController
            controller.delegate = self
        }
    }
    
    func addData(min:String, max:String = " ") {
        var mid = " "
        var band = " "
        if max != " " {
            let minNum = Double(min)!
            let maxNum = Double(max)!
            mid = String(round(sqrt(minNum * maxNum) * 10) / 10)
            band = String(round((maxNum - minNum) * 10) / 10)
        }
        let toAppend = (min, mid, max, band)
        masterpieces.append(toAppend)
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
            musicMan.togglePlay()
            if shouldPlayRange {
                rangeTimer?.invalidate()
                rangeTimer = nil
            }
        } else if sender.titleLabel!!.text == "Save Frequency" {
            addData(currentFreq.text!)
            saveTable.reloadData()
        } else if sender.titleLabel!!.text == "Save Range" {
            sender.setTitle("End Save Range", forState: .Normal)
            savedRange = currentFreq.text!
        } else if sender.titleLabel!!.text == "End Save Range" {
            if Double(currentFreq.text!) < Double(savedRange) {
                addData(currentFreq.text!, max: savedRange)
            } else {
                addData(savedRange, max: currentFreq.text!)
            }
            sender.setTitle("Save Range", forState: .Normal)
            saveTable.reloadData()
        } else if sender.titleLabel!!.text == "▶️" {
            upTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: "upHeldDown:", userInfo: nil, repeats: true)
            slider.value += 0.5
            musicMan.setFrequency(Double(slider.value))
            let roundedNum = round(slider.value * 10) / 10
            currentFreq.text = "\(roundedNum)"
            NSRunLoop.currentRunLoop().addTimer(upTimer, forMode: NSDefaultRunLoopMode)
            rangeTimer?.invalidate()
            rangeTimer = nil
        } else if sender.titleLabel!!.text == "◀️" {
            downTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: "downHeldDown:", userInfo: nil, repeats: true)
            slider.value -= 0.5
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
    
    func setRange(first: Double, second: Double) {
        self.startRange = first
        self.endRange = second
    }
    
    func playRange() {
        if rangeTimer == nil {
            rangeTimer = NSTimer(timeInterval: NSTimeInterval(0.2), target: self, selector: "rangeHelper:", userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(rangeTimer!, forMode: NSDefaultRunLoopMode)
        }
    }
    
    func rangeHelper(sender:AnyObject) {
        if increaseWhilePlayingRange {
            upHeldDown(self)
            if slider.value >= Float(endRange) {
                increaseWhilePlayingRange = false
            }
        } else {
            downHeldDown(self)
            if slider.value <= Float(startRange) {
                increaseWhilePlayingRange = true
            }
        }
    }
    
    func changeFreq(rate:Float) {
        slider.value += rate
        musicMan.setFrequency(Double(slider.value))
    }
    
    func upHeldDown(sender:AnyObject) {
        changeFreq(0.5)
        currentFreq.text = "\(slider.value)"
        
    }
    
    func downHeldDown(sender:AnyObject) {
        changeFreq(-0.5)
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
    //swipe gesture
    @IBAction func CellSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            if sender.direction == .Right {
                let point = sender.locationInView(saveTable)
                let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
                let toDeleteDataIndex = toDeleteIndex!.row
                if toDeleteIndex != nil && toDeleteDataIndex != 0  {
                    let cell = saveTable.cellForRowAtIndexPath(toDeleteIndex!)
                    cell!.slideOutToRight(0.5){ () in
                        self.masterpieces.removeAtIndex(toDeleteDataIndex)
                        self.saveTable.reloadData()
                    }
                }
            } else {
                let point = sender.locationInView(saveTable)
                let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
                let toDeleteDataIndex = toDeleteIndex!.row
                if toDeleteIndex != nil && toDeleteDataIndex != 0 {
                    let cell = saveTable.cellForRowAtIndexPath(toDeleteIndex!)
                    cell!.slideOutToLeft(0.5){ () in
                        self.masterpieces.removeAtIndex(toDeleteDataIndex)
                        self.saveTable.reloadData()
                    }
                }
            }
        }
    }
    
    
    //table stuff
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let data = masterpieces[indexPath.row]
        let note = (data.0 as NSString).doubleValue
        let note2 = (data.2 as NSString).doubleValue
        slider.value = Float(note)
        musicMan.setFrequency(note)
        shouldPlayRange = false
        if data.2 != " " {
            //if the cell contains a range
            shouldPlayRange = true
            setRange(note, second: note2)
            currentFreq.text = data.0 + " - " + data.2
            //if this is already playing
            if playButton.titleLabel!.text == "Stop" {
                playRange()
            }
        } else {
            currentFreq.text = data.0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterpieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        masterpieces.sortInPlace({(col1:(String, String, String, String), col2:(String, String, String, String)) -> (Bool) in
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
        for i in 0..<4 {
            let val:String
            switch i {
            case 0: val = item.0
            case 1: val = item.1
            case 2: val = item.2
            default: val = item.3
            }
            let view = cell.contentView.subviews[i] as! UILabel
            view.text = val
            view.font = myFont
            view.textAlignment = .Center
        }
        return cell
    }
}

