//
//  ViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 6/13/15.
//  Copyright (c) 2015 CAEN. All rights reserved.
//

import UIKit


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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    let musicMan = Musician();
    
    var masterpieces = Set<String>()

    @IBOutlet weak var slider: OBSlider!
    @IBOutlet weak var currentFreq: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after load
        
        //sets background image view
        let backImageView = UIImageView(frame: self.view.bounds)
        backImageView.image = UIImage(named: "background.gif")
        self.view.addSubview(backImageView)
        self.view.sendSubviewToBack(backImageView)
        
        //view over background image to create fade effect over background
        //1 = mainView
        //2 = tableView

        self.view.viewWithTag(1)?.backgroundColor = UIColor.yellowColor().colorWithAlphaComponent(0.35)
        self.view.viewWithTag(2)?.backgroundColor = UIColor.clearColor()
        
        //button & slider set-up
/*
        currentFreq.textColor = UIColor.blueColor()
        playButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        saveButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
*/
        currentFreq.text = "20.0"
        slider.minimumValue = 20
        slider.maximumValue = 20000
        
        //synthesiser set-up
        musicMan.setFrequency(20)
        musicMan.initHelp()
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
        }
        
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        currentFreq.text = "\(sender.value)"
        musicMan.setFrequency(Double(sender.value))
    }
    
    //swipe gesture
    @IBAction func CellSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            let point = sender.locationInView(saveTable)
            let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
            if toDeleteIndex != nil {
                let cell = saveTable.cellForRowAtIndexPath(toDeleteIndex!)
                let freq = cell!.textLabel?.text
                cell!.slideOutToRight(duration: 0.5){ () in
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
        collection.sort({(string1:String, string2:String) -> (Bool) in
            let d1 = (string1 as NSString).doubleValue
            let d2 = (string2 as NSString).doubleValue
            if (d1 < d2) {
                return true
            }
            return false
        })
        let item = collection[indexPath.item]
        let cell = tableView.dequeueReusableCellWithIdentifier("Frequencies") as! UITableViewCell
        cell.textLabel?.text = item
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel?.textAlignment = .Center
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

