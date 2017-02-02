//
//  RangePopoverViewController.swift
//  Mfrequency
//
//  Created by Mike Dobrowolski on 8/3/15.
//  Copyright © 2015 CAEN. All rights reserved.
//

import Foundation

protocol RangeDelegate {
    var selectedRange:IndexPath {get set}
    func rangeDidChange(_ range:Int)
}

class RangePopoverViewController: UITableViewController {
    var delegate:ViewController!
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath == delegate.selectedRange as IndexPath {
            cell.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath != delegate.selectedRange as IndexPath {
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
            delegate.rangeDidChange((indexPath as NSIndexPath).row)
            //remove checkmark from old cell
            let oldcell = tableView.cellForRow(at: delegate.selectedRange as IndexPath)
            oldcell?.accessoryType = .none
            delegate.selectedRange = indexPath
        }
        
    }
}
