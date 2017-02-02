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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, RangeDelegate, KeyboardDelegate {
    
    // MARK: Member Variables
    
    let musicMan = Musician();
    let ios9BlueColor = UIColor(red: 0, green: 122/225, blue: 1, alpha: 1)
    
    var masterpieces = Array<(String, String, String, String, String)>()
    
    var selectedRange:IndexPath = IndexPath(item: 0, section: 0) //range of slider
    
    var sliderRate:Float = 0.5
    
    var savedRange:String = "" //user saved range
    var curGain:String = ""
    var shouldPlayRange = false
    var increaseWhilePlayingRange = true
    var startRange = 0.0
    var endRange = 0.0
    
    var upTimer:Timer!
    var downTimer:Timer!
    var rangeTimer:Timer? = nil

    var whitePlayer = AVAudioPlayer()
    var pinkPlayer = AVAudioPlayer()
    
    var currentTextField:UITextField!
    var currentFrequencyValue:Float = 50.0
    
    var calcFrequencyDisplayed = false
    
    @IBOutlet weak var slider: OBSlider!
    @IBOutlet weak var currentFreq: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var calculatorButton: UIButton!
    @IBOutlet weak var saveTable: UITableView!
    @IBOutlet weak var volumeButton: UIBarButtonItem!
    @IBOutlet weak var markImage: UIImageView!
    @IBOutlet weak var markLabel: UILabel!
    
    @IBOutlet weak var calcFundLabel: UILabel!
    @IBOutlet weak var calc2ndLabel: UILabel!
    @IBOutlet weak var calc3rdLabel: UILabel!
    @IBOutlet weak var calc4thLabel: UILabel!
    
    @IBOutlet weak var markImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var clearButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var indicatorOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var calcFrequencyDisplayConstraint: NSLayoutConstraint!
    
    // MARK: Lifecycle methods
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after load
        // view over background image to create fade effect over background
        // 1 = mainView
        // 2 = tableView

        self.view.viewWithTag(1)?.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        self.view.viewWithTag(2)?.backgroundColor = UIColor.clear
        
        //button & slider set-up
        playButton.setTitleColor(UIColor.green, for: UIControlState())
        currentFreq.textColor = UIColor.black
        currentFreq.text = "50.0"
        
        //synthesiser set-up
        musicMan.setFrequency(20)
        musicMan.initHelp()
        
        //hide mark
        markLabel.alpha = 0
        markImage.alpha = 0
        
        //white & pink noise setup
        if let path = Bundle.main.path(forResource: "White Noise", ofType: "wav") {
            let url = URL(fileURLWithPath: path)
            do {
                whitePlayer = try AVAudioPlayer(contentsOf: url)
                whitePlayer.numberOfLoops = -1
            } catch {
                print("white noise player failed!", true)
            }
        } else {
            print("white noise file missing!")
        }
        
        if let path = Bundle.main.path(forResource: "Pink Noise", ofType: "wav") {
            let url = URL(fileURLWithPath: path)
            do {
                pinkPlayer = try AVAudioPlayer(contentsOf: url)
                pinkPlayer.numberOfLoops = -1
            } catch {
                print("pink noise failed", true)
            }
        } else {
            print("pink noise file missing!")
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(volumeDidChange), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        if AVAudioSession().outputVolume == 0 {
            volumeButton.image = UIImage(imageLiteralResourceName: "mute")
        }
    }
    
    func appMovedToBackground() {
        //make sure slider isn't incrementing
        musicMan.stop()
        playButton.setTitle("Play", for: UIControlState())
        playButton.setTitleColor(UIColor.green, for: UIControlState())
        if upTimer != nil {
            upTimer.invalidate()
        }
        if downTimer != nil {
            downTimer.invalidate()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RangeSegue" {
            let controller = segue.destination as! RangePopoverViewController
            controller.delegate = self
        }
        else if segue.identifier == "InfoSegue" {
            let controller = segue.destination as! InfoViewController
            controller.delegate = self
            
            if !calcFrequencyDisplayed {
                UIView.animate(withDuration: 0.3, animations: {
                    self.clearButtonConstraint.constant = 54
                    self.view.layoutIfNeeded()
                })
            }
        }
        else if segue.identifier == "SettingSegue" {
            let controller = segue.destination as! SettingViewController
            controller.delegate = self
        }
        else if segue.identifier == "CalculatorSegue" {
            let controller = segue.destination as! CalculatorViewController
            controller.delegate = self
        }
    }
    
    // MARK: Add Data
    
    func addData(_ min:String, max:String = " ") {
        var mid = " "
        var band = "0.167"
        
        // Setup for adding the alert
        let setGainAlert = UIAlertController(title: "Set Gain", message: "\n\n\n\n", preferredStyle: UIAlertControllerStyle.alert)
        
        let slider = UISlider(frame: CGRect(x: 35, y: 55, width: 200, height: 30))
        slider.minimumValue = -10
        slider.maximumValue = 0
        slider.value = -5
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(gainSliderValueChanged(_:)), for: .valueChanged)
        setGainAlert.view.addSubview(slider)
        
        let label = UILabel(frame: CGRect(x: 114, y: 95, width: 42, height: 21))
        label.text = "\(slider.value)"
        label.textAlignment = .center
        setGainAlert.view.addSubview(label)
        
        // Set button
        let setAction = UIAlertAction(title: "Set", style: .default, handler: { (action) in
            let gain = "\(round(slider.value * 10) / 10)"
            var maxStr:String
            var minStr:String
            
            if max != " " { // Range
                let minNum = Double(min)!
                let maxNum = Double(max)!
                mid = String(round(sqrt(minNum * maxNum) * 10) / 10)
                band = String(round((maxNum - minNum) / Double(mid)! * 1000) / 1000)
                minStr = min
                maxStr = max
            }
            else {
                let midNum = Double(min)!
                let bandNum = Double(band)!
                let maxNum = round((bandNum * midNum + sqrt(pow(bandNum * midNum, 2) + 4 * pow(midNum, 2))) / 2 * 10 ) / 10
                let minNum = round(pow(midNum, 2) / maxNum * 10) / 10
                mid = String(midNum)
                minStr = String(minNum)
                maxStr = String(maxNum)
            }
            let toAppend = (minStr, mid, maxStr, gain, band)
            self.masterpieces.append(toAppend)
            self.saveTable.reloadData()
        })
        setGainAlert.addAction(setAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        setGainAlert.addAction(cancelAction)
        
        if presentedViewController == nil {
            self.present(setGainAlert, animated: true, completion: nil)
        }
        else {
            presentedViewController!.present(setGainAlert, animated: true, completion: nil)
        }
    }
    
    // MARK: Buttons
    
    @IBAction func ButtonPress(_ sender: AnyObject) {
        if (sender.titleLabel!!.text == "Play") {
            sender.setTitle("Stop", for: UIControlState())
            sender.setTitleColor(UIColor.red, for: UIControlState())
            musicMan.togglePlay()
            if shouldPlayRange {
                playRange()
            }
        } else if sender.titleLabel!!.text == "Stop"{
            sender.setTitle("Play", for: UIControlState())
            sender.setTitleColor(UIColor.green, for: UIControlState())
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
            if let freq = Float(currentFreq.text!) {
                sender.setTitle("End Save Range", for: UIControlState())
                sender.setTitleColor(UIColor.red, for: UIControlState())
                savedRange = currentFreq.text!
                
                setMark(frequency: freq)
            }
        } else if sender.titleLabel!!.text == "End Save Range" {
            if Double(currentFreq.text!) < Double(savedRange) {
                addData(currentFreq.text!, max: savedRange)
            } else {
                addData(savedRange, max: currentFreq.text!)
            }
            sender.setTitle("Save Range", for: UIControlState())
            sender.setTitleColor(ios9BlueColor, for: UIControlState())
            //saveTable.reloadData()
            
            hideMark()
        } else if sender.titleLabel!!.text == "▶️" {
            upTimer = Timer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(ViewController.upHeldDown(_:)), userInfo: nil, repeats: true)
            slider.value += sliderRate
            setMasterFrequency(newFreq: Double(slider.value))
            
            RunLoop.current.add(upTimer, forMode: RunLoopMode.defaultRunLoopMode)
            rangeTimer?.invalidate()
            rangeTimer = nil
        } else if sender.titleLabel!!.text == "◀️" {
            downTimer = Timer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(ViewController.downHeldDown(_:)), userInfo: nil, repeats: true)
            slider.value -= sliderRate
            setMasterFrequency(newFreq: Double(slider.value))
            
            RunLoop.current.add(downTimer, forMode: RunLoopMode.defaultRunLoopMode)
            rangeTimer?.invalidate()
            rangeTimer = nil
        } else if sender.titleLabel!!.text == "White Noise" {
            if pinkPlayer.isPlaying {
                pinkPlayer.stop()
            }
            if whitePlayer.isPlaying {
                whitePlayer.stop()
            } else {
                whitePlayer.play()
            }
        } else if sender.titleLabel!!.text == "Pink Noise" {
            if whitePlayer.isPlaying {
                whitePlayer.stop()
            }
            if pinkPlayer.isPlaying {
                pinkPlayer.stop()
            } else {
                pinkPlayer.play()
            }
        }
    }
    
    func setMark(frequency: Float) {
        let range = slider.maximumValue - slider.minimumValue
        let width = slider.frame.width - 31
        
        if frequency > slider.maximumValue { // Check if frequency has been set off the end of the slider
            markImageConstraint.constant = CGFloat(-width)
        }
        else if frequency < slider.minimumValue {
            markImageConstraint.constant = 0
        }
        else {
            markImageConstraint.constant = CGFloat(-((frequency-slider.minimumValue)/range) * Float(width))
        }
        
        view.layoutIfNeeded()
        
        if markLabel.frame.intersects(currentFreq.frame) { // Does the mark intersect the frequency label
            let interception = markLabel.frame.intersection(currentFreq.frame)
            
            if interception.midX < view.frame.midX { // Move mark to left
                indicatorOffsetConstraint.constant = (interception.width + 10)
            }
            else { // Move mark to right
                indicatorOffsetConstraint.constant = -(interception.width + 10)
            }
        }
        
        view.layoutIfNeeded()
        
        markLabel.text = savedRange // Show mark
        markLabel.alpha = 1
        markImage.alpha = 1
    }
    
    func hideMark() {
        indicatorOffsetConstraint.constant = 0
        markLabel.alpha = 0
        markImage.alpha = 0
    }
    
    @IBAction func cancelSaveRange(_ sender: AnyObject) {
        sender.setTitle("Save Range", for: UIControlState())
        sender.setTitleColor(ios9BlueColor, for: UIControlState())
        
        hideMark()
    }
    
    @IBAction func setFrequencyButton(_ sender: AnyObject) {
        let setFreqAlert = UIAlertController(title: "Set Frequency", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        setFreqAlert.addTextField( configurationHandler: { (textField) in
            textField.placeholder = "Enter Frequency"
            
            let keyboard = Bundle.main.loadNibNamed("KeyboardView", owner: nil, options: nil)?[0] as! KeyboardView
            keyboard.delegate = self
            
            textField.inputView = keyboard
            
            self.currentTextField = textField
        })
        
        let setAction = UIAlertAction(title: "Set", style: .default, handler: { (action) in
            let freqField = setFreqAlert.textFields![0] as UITextField
            let freqString:String = freqField.text!
            
            let freq = round(Double(freqString)! * 10) / 10
            self.setMasterFrequency(newFreq: freq)
        })
        setFreqAlert.addAction(setAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        setFreqAlert.addAction(cancelAction)
        
        self.present(setFreqAlert, animated: true, completion: nil)
    }
    
    func setMasterFrequency(newFreq:Double) {
        let roundedFreq = round(newFreq * 10) / 10
        
        self.currentFrequencyValue = Float(roundedFreq)
        self.slider.value = Float(roundedFreq)
        self.currentFreq.text = "\(roundedFreq)"
        self.musicMan.setFrequency(roundedFreq)
    }
    
    @IBAction func clearTable() {
        let clearTableAlert = UIAlertController(title: "Clear Table", message: "Are you sure you want to clear the table?", preferredStyle: UIAlertControllerStyle.alert)
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive , handler: { (action) in
            self.masterpieces.removeAll()
            self.saveTable.reloadData()
        })
        
        clearTableAlert.addAction(clearAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        clearTableAlert.addAction(cancelAction)
        
        self.present(clearTableAlert, animated: true, completion: nil)
    }
    
    // MARK: Calculated Values Display
    
    func displayCalculatedValues() {
        calcFrequencyDisplayed = true
        UIView.animate(withDuration: 0.3, animations: {
            self.calcFrequencyDisplayConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func hideCalculatedValues() {
        calcFrequencyDisplayed = false
        UIView.animate(withDuration: 0.3, animations: {
            self.calcFrequencyDisplayConstraint.constant = -66
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func setFreqToCalculatedValue(_ sender: UIButton) {
        var newFreq:String = "0"
        if sender.titleLabel!.text == "F" {
            newFreq = String(calcFundLabel.text!.characters.dropLast(3))
        }
        else if sender.titleLabel!.text == "2" {
            newFreq = String(calc2ndLabel.text!.characters.dropLast(3))
        }
        else if sender.titleLabel!.text == "3" {
            newFreq = String(calc3rdLabel.text!.characters.dropLast(3))
        }
        else if sender.titleLabel!.text == "4" {
            newFreq = String(calc4thLabel.text!.characters.dropLast(3))
        }
        setMasterFrequency(newFreq: Double(newFreq)!)
    }
    
    // MARK: Keyboard Delegate
    
    func addTextToField(_ charToAdd:String) {
        currentTextField.text = currentTextField.text! + charToAdd
    }
    
    func deleteTextFromField() -> Bool {
        var decimalDeleted = false
        
        if !(currentTextField.text?.isEmpty)! {
            if currentTextField.text?.characters.last == "." {
                decimalDeleted = true
            }
            currentTextField.text?.remove(at: (currentTextField.text?.characters.index(before: (currentTextField.text?.endIndex)!))!)
        }
        
        return decimalDeleted
    }
    
    // MARK: Range methods
    
    func setRange(_ first: Double, second: Double) {
        self.startRange = first
        self.endRange = second
    }
    
    func playRange() {
        if rangeTimer == nil {
            rangeTimer = Timer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(ViewController.rangeHelper(_:)), userInfo: nil, repeats: true)
            RunLoop.current.add(rangeTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    func rangeHelper(_ sender:AnyObject) {
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
    
    func upForRange() { // Allows the frequency to go past the end of the slider when playing a range
        setMasterFrequency(newFreq: Double(currentFrequencyValue + sliderRate))
    }
    
    func downForRange() {
        setMasterFrequency(newFreq: Double(currentFrequencyValue - sliderRate))
    }
    
    func upHeldDown(_ sender:AnyObject) { // Doesn't allow the frequency to go past the end of the slider when pressing the increment buttons
        slider.value += sliderRate
        setMasterFrequency(newFreq: Double(slider.value))
    }
    
    func downHeldDown(_ sender:AnyObject) {
        slider.value -= sliderRate
        setMasterFrequency(newFreq: Double(slider.value))
    }
    
    @IBAction func releaseVolArrow(_ sender: UIButton) {
        if sender.titleLabel!.text == "▶️" {
            upTimer.invalidate()
        } else if sender.titleLabel!.text == "◀️" {
            downTimer.invalidate()
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
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
    func rangeDidChange(_ range: Int) {
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
    @IBAction func CellSwipe(_ sender: UISwipeGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended {
            if sender.direction == .right {
                let point = sender.location(in: saveTable)
                let toDeleteIndex = saveTable.indexPathForRow(at: point)
                let toDeleteDataIndex = (toDeleteIndex as NSIndexPath?)?.row
                if toDeleteIndex != nil {
                    self.masterpieces[toDeleteDataIndex!] = ("", "", "", "", "")
                    self.saveTable.reloadRows(at: [toDeleteIndex!], with: .right)
                    // Delete at index 0 because the deleted row is sorted to the front when the save table reloads
                    self.masterpieces.remove(at: 0)
                    self.saveTable.reloadData()
                }
            } else {
                let point = sender.location(in: saveTable)
                let toDeleteIndex = saveTable.indexPathForRow(at: point)
                let toDeleteDataIndex = (toDeleteIndex as NSIndexPath?)?.row
                if toDeleteIndex != nil {
                    self.masterpieces[toDeleteDataIndex!] = ("", "", "", "", "")
                    self.saveTable.reloadRows(at: [toDeleteIndex!], with: .left)
                    // Delete at index 0 because the deleted row is sorted to the front when the save table reloads
                    self.masterpieces.remove(at: 0)
                    self.saveTable.reloadData()
                }
            }
        }
    }
    
    // MARK: Long Press Gesture Recognizer
    
    @IBAction func longPressForCell(_ sender: AnyObject) {
        if sender.state == .began {
            let point = sender.location(in: saveTable)
            let toEditIndex = (saveTable.indexPathForRow(at: point) as NSIndexPath?)?.row
            if toEditIndex != nil { // Check that long press is on a table cell
                if (point.x > view.frame.width * (3 / 5)) && (point.x < view.frame.width * (4 / 5)) { // Edit gain
                    let editGainAlert = UIAlertController(title: "Edit Gain", message: "\n\n\n\n", preferredStyle: UIAlertControllerStyle.alert)
                    
                    let slider = UISlider(frame: CGRect(x: 35, y: 55, width: 200, height: 30))
                    slider.minimumValue = -10
                    slider.maximumValue = 0
                    slider.value = Float(masterpieces[toEditIndex!].3)!
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
                        self.masterpieces[toEditIndex!].3 = gain
                        self.saveTable.reloadData()
                    })
                    editGainAlert.addAction(setAction)
                    
                    // Cancel button
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    editGainAlert.addAction(cancelAction)
                    
                    present(editGainAlert, animated: true, completion: nil)
                }
                else { // Set Tesira
                    if point.x > view.frame.width * (4 / 5) { // Bandwidth
                        addFreqGainView(masterpieces[toEditIndex!].0, gain: masterpieces[toEditIndex!].3, bandwidth: masterpieces[toEditIndex!].4, row: toEditIndex!, col: 0)
                    }
                    else if point.x > view.frame.width * (2 / 5) { // Max
                        addFreqGainView(masterpieces[toEditIndex!].2, gain: masterpieces[toEditIndex!].3, bandwidth: masterpieces[toEditIndex!].4, row: toEditIndex!, col: 2)
                    }
                    else if point.x > view.frame.width * (1 / 5) { // Mid
                        addFreqGainView(masterpieces[toEditIndex!].1, gain: masterpieces[toEditIndex!].3, bandwidth: masterpieces[toEditIndex!].4, row: toEditIndex!, col: 1)
                    }
                    else { // Min
                        addFreqGainView(masterpieces[toEditIndex!].0, gain: masterpieces[toEditIndex!].3, bandwidth: masterpieces[toEditIndex!].4, row: toEditIndex!, col: 0)
                    }
                }
            }
        }
    }
    
    func gainSliderValueChanged(_ sender: UISlider) {
        if let gainController = self.presentedViewController as? UIAlertController {
            let label = gainController.view.subviews[2] as! UILabel
            
            label.text = "\(round(sender.value * 10) / 10)"
        }
        else {
            let gainController = self.presentedViewController!.presentedViewController as! UIAlertController
            let label = gainController.view.subviews[2] as! UILabel
            
            label.text = "\(round(sender.value * 10) / 10)"
        }
    }
    
    func addFreqGainView(_ freq:String, gain:String, bandwidth:String, row:Int, col:Int) {
        
        let freqGainView = Bundle.main.loadNibNamed("EqualizerFreqGainView", owner: nil, options: nil)?[0] as! EqualizerFreqGainView
        freqGainView.frame = view.bounds
        freqGainView.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        freqGainView.delegate = self
        freqGainView.rowIndex = row
        freqGainView.colIndex = col
        freqGainView.freqValueLabel.text = freq
        freqGainView.gainValueLabel.text = gain
        freqGainView.bandwidthValueLabel.text = bandwidth
        self.view.addSubview(freqGainView)
    }
    
    // MARK: Table View
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let data = masterpieces[(indexPath as NSIndexPath).row]
        
        if shouldPlayRange {
            rangeTimer?.invalidate()
            rangeTimer = nil
            shouldPlayRange = false
        }
        
        let note = (data.0 as NSString).doubleValue
        let note2 = (data.2 as NSString).doubleValue
        currentFrequencyValue = Float(note)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterpieces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        masterpieces.sort(by: {(col1:(String, String, String, String, String), col2:(String, String, String, String, String)) -> (Bool) in
            let string1:String
            let string2:String
            //impliment sort by top col selection
            //impliment least to great/great to least sort
            string1 = col1.0 // sorts by min from least to greatest
            string2 = col2.0
            let d1 = Double(string1)
            let d2 = Double(string2)
            if (d1 < d2) {
                return true
            }
            return false
        })
        let item = masterpieces[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "frequency cell")!
        let myFont = UIFont(name: "Arial", size: 32)
        cell.backgroundColor = UIColor.clear
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
            view.textAlignment = .center
        }
        return cell
    }

    // MARK: Share Button
    
    @IBAction func shareSheet(_ sender: AnyObject) {
        
        var sendString:String = "Min Mid Max Gain BW\n"
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
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // Volume button image update
    func volumeDidChange(_ notification:Notification) {
        let volume = (notification as NSNotification).userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
        
        if volume == 0 {
            volumeButton.image = UIImage(imageLiteralResourceName: "mute")
        }
        else {
            volumeButton.image = UIImage(imageLiteralResourceName: "volume")
        }
    }
}

// Information screen view controller
class InfoViewController:UIViewController {
    
    var delegate:ViewController!
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(white: 1, alpha: 0.6)
    }
    
    @IBAction func dismiss(_ sender:AnyObject) {
        UIView.animate(withDuration: 0.3, animations: {
            self.delegate.clearButtonConstraint.constant = 20
            self.delegate.view.layoutIfNeeded()
        })
        
        delegate.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
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
    
    @IBAction func sliderValueChanged(_ sender:UISlider) {
        let value:Float = round(sender.value * 10)/10
        sliderValue.text = "\(value)"
        
        delegate.sliderRate = value  // Update the rate
    }
    
}
