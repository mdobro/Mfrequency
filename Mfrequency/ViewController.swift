//
//  ViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 6/13/15.
//  Copyright (c) 2015 CAEN. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    let musicMan = Musician();
    
    var masterpieces = Set<String>()

    @IBOutlet weak var slider: OBSlider!
    @IBOutlet weak var currentFreq: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveTable: UITableView!
    @IBOutlet var longPressGesture:UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        currentFreq.text = "20.0"
        musicMan.setFrequency(20)
        slider.minimumValue = 20
        slider.maximumValue = 5000
        musicMan.initHelp()
    }
    
    @IBAction func ButtonPress(sender: AnyObject) {
        if (sender.titleLabel!!.text == "Play") {
            sender.setTitle("Stop", forState: .Normal)
            musicMan.togglePlay()
        } else if sender.titleLabel!!.text == "Stop"{
            sender.setTitle("Play", forState: .Normal)
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
    
    //long press gesture
    @IBAction func CellLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Ended {
            let point = sender.locationInView(saveTable)
            let toDeleteIndex = saveTable.indexPathForRowAtPoint(point)
            if toDeleteIndex != nil {
                let cell = saveTable.cellForRowAtIndexPath(toDeleteIndex!)
                let freq = cell?.textLabel?.text
                masterpieces.remove(freq!)
                saveTable.reloadData()
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
        let collection = Array(masterpieces)
        let item = collection[indexPath.item]
        let cell = tableView.dequeueReusableCellWithIdentifier("Frequencies") as! UITableViewCell
        cell.textLabel?.text = item
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

