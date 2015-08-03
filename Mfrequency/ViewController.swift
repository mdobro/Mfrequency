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
        let slideInFromLeftTransition = CATransition()
        
        CATransaction.setCompletionBlock(completion)
        
        // Customize the animation's properties
        slideInFromLeftTransition.type = kCATransitionPush
        slideInFromLeftTransition.subtype = kCATransitionFromLeft
        slideInFromLeftTransition.duration = duration
        slideInFromLeftTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        slideInFromLeftTransition.fillMode = kCAFillModeRemoved
        
        // Add the animation to the View's layer
        self.layer.addAnimation(slideInFromLeftTransition, forKey: "slideInFromLeftTransition")
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, RangeDelegate {
    let musicMan = Musician();
    
    var masterpieces = Set<String>()
    
    var selectedRange:NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    
    var upTimer:NSTimer!
    var downTimer:NSTimer!

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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDidRotate:", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        //sets background image view
        let backImageView = UIImageView(frame: self.view.bounds)
        backImageView.image = UIImage(named: "background.jpg")
        self.view.addSubview(backImageView)
        self.view.sendSubviewToBack(backImageView)
        
        //view over background image to create fade effect over background
        //1 = mainView
        //2 = tableView

        self.view.viewWithTag(1)?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.55)
        self.view.viewWithTag(2)?.backgroundColor = UIColor.clearColor()
        
        //button & slider set-up
        playButton.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
        currentFreq.textColor = UIColor.blackColor()
        //saveButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
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
    
    func deviceDidRotate(notification:NSNotification) {
        let background = self.view.subviews[0]
        background.frame = self.view.bounds
    }
    
    @IBAction func ButtonPress(sender: AnyObject) {
        if (sender.titleLabel!!.text == "Play") {
            sender.setTitle("Stop", forState: .Normal)
            sender.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            musicMan.togglePlay()
        } else if sender.titleLabel!!.text == "Stop"{
            sender.setTitle("Play", forState: .Normal)
            sender.setTitleColor(UIColor.greenColor(), forState: UIControlState.Normal)
            musicMan.togglePlay()
        } else if sender.titleLabel!!.text == "Save Frequency" {
            masterpieces.insert(currentFreq.text!)
            saveTable.reloadData()
        } else if sender.titleLabel!!.text == "▶️" {
            upTimer = NSTimer(timeInterval: NSTimeInterval(0.5), target: self, selector: "upHeldDown:", userInfo: nil, repeats: true)
            slider.value += 0.5
            currentFreq.text = "\(slider.value)"
            NSRunLoop.currentRunLoop().addTimer(upTimer, forMode: NSDefaultRunLoopMode)
        } else if sender.titleLabel!!.text == "◀️" {
            downTimer = NSTimer(timeInterval: NSTimeInterval(0.5), target: self, selector: "downHeldDown:", userInfo: nil, repeats: true)
            slider.value -= 0.5
            currentFreq.text = "\(slider.value)"
            NSRunLoop.currentRunLoop().addTimer(downTimer, forMode: NSDefaultRunLoopMode)
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
    
    func upHeldDown(sender:AnyObject) {
        slider.value += 0.5
        currentFreq.text = "\(slider.value)"
    }
    
    func downHeldDown(sender:AnyObject) {
        slider.value -= 0.5
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
        currentFreq.text = "\(sender.value)"
        musicMan.setFrequency(Double(sender.value))
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
    }
    //swipe gesture
    @IBAction func CellSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            let point = sender.locationInView(saveTable)
            let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
            if toDeleteIndex != nil {
                let cell = saveTable.cellForRowAtIndexPath(toDeleteIndex!)
                let freq = cell!.textLabel?.text
                cell!.slideOutToRight(0.5){ () in
                    self.masterpieces.remove(freq!)
                    self.saveTable.reloadData()
                }
                cell?.textLabel?.text = ""
            }
        }
    }
    
    
    //table stuff
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        currentFreq.text = cell?.textLabel?.text
        let note = (currentFreq.text! as NSString).doubleValue
        musicMan.setFrequency(note)
        slider.value = Float(note)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterpieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var collection = Array(masterpieces)
        collection.sortInPlace({(string1:String, string2:String) -> (Bool) in
            let d1 = (string1 as NSString).doubleValue
            let d2 = (string2 as NSString).doubleValue
            if (d1 < d2) {
                return true
            }
            return false
        })
        let item = collection[indexPath.item]
        let cell = tableView.dequeueReusableCellWithIdentifier("Frequencies")!
        cell.textLabel?.text = item
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textAlignment = .Center
        return cell
    }
}

