//
//  RangePopoverViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 8/3/15.
//  Copyright © 2015 CAEN. All rights reserved.
//

import Foundation

protocol RangeDelegate {
    var selectedRange:NSIndexPath {get set}
    func rangeDidChange(range:Int)
}

class RangePopoverViewController: UITableViewController {
    var delegate:ViewController!
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath == delegate.selectedRange {
            cell.accessoryType = .Checkmark
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath != delegate.selectedRange {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.accessoryType = .Checkmark
            delegate.rangeDidChange(indexPath.row)
            //remove checkmark from old cell
            let oldcell = tableView.cellForRowAtIndexPath(delegate.selectedRange)
            oldcell?.accessoryType = .None
            delegate.selectedRange = indexPath
        }
        
    }
}