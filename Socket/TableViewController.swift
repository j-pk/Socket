//
//  TableViewController.swift
//  Socket
//
//  Created by Jameson Kirby on 10/16/15.
//  Copyright © 2015 Jameson Kirby. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController, UIViewControllerPreviewingDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        } else { print("3D Touch is not available on this device.") }
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("ViewController") as? ViewController else { return nil }
        vc.preferredContentSize = CGSize(width: 0.0, height: 300.0)
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("login") as! TableViewCell
        return cell
    }

}
