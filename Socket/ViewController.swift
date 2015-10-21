//
//  ViewController.swift
//  Socket
//
//  Created by Jameson Kirby on 10/7/15.
//  Copyright © 2015 Jameson Kirby. All rights reserved.
//

import UIKit
import CoreData
import Socket_IO_Client_Swift

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var sendMessage: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var isTypingStatusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var managedObjectContext: NSManagedObjectContext!
    lazy var coreDataStack = CoreDataStack()
    var fetchedResultsController: NSFetchedResultsController!
    var currentUser: Person!
    
    var timer: NSTimer? = nil
    var connected = 0
    
    lazy var dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    //Use your IP
    let socket = SocketIOClient(socketURL: "192.168.0.24:8080", opts: ["log": true])
    var userName: String? {
        get {
            return defaults.objectForKey("USERNAME") as? String
        }
        set {
            defaults.setValue(newValue, forKey: "USERNAME")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0 // Replace with your actual estimation
        tableView.rowHeight = UITableViewAutomaticDimension
        navigationController?.navigationBar.tintColor = UIColor.grayColor()
        disconnectButton.enabled = false
        
        //Core Data
        managedObjectContext = coreDataStack.context
        
        let request = NSFetchRequest(entityName: "Message")
        let sortDescriptor = NSSortDescriptor(key: "chatMessage", ascending: false)
        let sortDateDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDateDescriptor, sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
    }
  
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        messageTextField.resignFirstResponder()
        view.endEditing(true)
    }
    
    //Pop & Seek Action options
    override func previewActionItems() -> [UIPreviewActionItem] {
        let openAction = UIPreviewAction(title: "Connect Socket", style: .Default) { (_, _) in
            print("Selected 'Open Socket'")
        }
        
        let cancelAction = UIPreviewAction(title: "Cancel", style: .Destructive) { (_, _) in
            print("Selected 'Cancel'")
        }
        
        return [openAction, cancelAction]
    }
    
    func userNameAlert() {
        let alertController = UIAlertController(title: "Username?", message: nil, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default) { [unowned self, alertController] _ in
            let newUsername = alertController.textFields![0]
            self.userName = newUsername.text!
            self.defaults.setValue(newUsername.text!, forKey: "USERNAME")
            self.socket.emit("username", newUsername.text!)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func addHandlers() {

        socket.on("error") { [unowned self] _, _ in
            if let message = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: self.coreDataStack.context) as? Message {
                message.chatMessage = "Server is down. \n"
                self.runAfterDelay(5) {
                    self.managedObjectContext.deleteObject(message)
                }
            }
            self.coreDataStack.saveContext()
        }
        
        socket.on("user joined") { [unowned self] data, _ in
            if let response = data.first as? String {
                if let message = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: self.coreDataStack.context) as? Message {
                    message.chatMessage = "\(response) joined. \n"
                    self.runAfterDelay(5) {
                        self.managedObjectContext.deleteObject(message)
                    }
                }
                self.coreDataStack.saveContext()
            }
        }

        socket.on("user left") { [unowned self] data, _ in
            print("Data Response: \(data)")
            if let response = data.first as? String {
                if let message = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: self.coreDataStack.context) as? Message {
                    message.chatMessage = "\(response) left. \n"
                    self.runAfterDelay(5) {
                        self.managedObjectContext.deleteObject(message)
                    }
                }
                self.coreDataStack.saveContext()
            }
        }

        socket.on("chat message") { [unowned self] data, _ in
            if let response = data as? [String] {
                
                //Lining up 'Repos' to commit changes
                let messageEntity = NSEntityDescription.entityForName("Message", inManagedObjectContext: self.managedObjectContext)
                let personEntity = NSEntityDescription.entityForName("Person", inManagedObjectContext: self.managedObjectContext)
                let message = Message(entity: messageEntity!, insertIntoManagedObjectContext: self.managedObjectContext)
                self.currentUser = Person(entity: personEntity!, insertIntoManagedObjectContext: self.managedObjectContext)
                
                //'Sync' data
                self.currentUser.name = response[0]
                message.chatMessage = response[1]
                message.date = NSDate()
                
                if let messages = self.currentUser.messages?.mutableCopy() as? NSMutableOrderedSet {
                    messages.addObject(message)
                    self.currentUser.messages = messages.copy() as? NSOrderedSet
                }
                
                do {
                    //Commits saved
                    try self.managedObjectContext.save()
                } catch let error as NSError {
                    print("Could not save: \(error)")
                }
            }
        }
        
        socket.on("isTyping") { [unowned self] data, _ in
            if let response = data.first as? String {
                self.isTypingStatusLabel.text = "\(response) is typing"
            }
        }
        
        socket.on("isNotTyping") { [unowned self ] _, _ in
            self.isTypingStatusLabel.text = ""
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        socket.emit("typing")
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("isNotTyping:"), userInfo: textField, repeats: false)
        return true
    }
    
    func isNotTyping(timer: NSTimer) {
        socket.emit("stop typing")
    }
    
    func runAfterDelay(delay: NSTimeInterval, block: dispatch_block_t) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
    
    func configureCell(cell: MessageTableViewCell, indexPath: NSIndexPath) {
        
        cell.messageTextView.contentInset = UIEdgeInsetsMake(10, 5, 5, 5)
        
        if let person = fetchedResultsController.objectAtIndexPath(indexPath) as? Message {
            cell.usernameLabel.text = person.person?.name
            if let date = person.date {
                cell.timeLabel.text = dateFormatter.stringFromDate(date)
            }
            cell.messageTextView.text = person.chatMessage
        }
    
    }

    @IBAction func connectButtonPressed(sender: AnyObject) {
        if connected == 0 {
            addHandlers()
            socket.connect()
        } else {
            socket.connect()
        }
        
        runAfterDelay(0.2) { [unowned self] in
            if self.defaults.objectForKey("USERNAME") as? String == nil {
                self.userNameAlert()
            } else if let unwrapUserName = self.userName {
                self.socket.emit("username", unwrapUserName)
            }
        }
        
        connectButton.enabled = false
        disconnectButton.enabled = true
        connected++
    }
    
    @IBAction func disconnectButtonPressed(sender: AnyObject) {
        socket.emit("disconnect")
        runAfterDelay(0.2) { [unowned self] in
           self.socket.disconnect()
        }
        
        connectButton.enabled = true
        disconnectButton.enabled = false
    }
    
    @IBAction func sendMessageButtonPressed(sender: AnyObject) {
        socket.emit("chat message", withItems: [self.messageTextField.text!])
        self.messageTextField.text = ""
        self.resignFirstResponder()
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("messageCell") as! MessageTableViewCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell 
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = tableView.dequeueReusableCellWithIdentifier("messageCell") as! MessageTableViewCell
        
        print(cell.messageTextView.frame.height)
        
        return 44.0
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! MessageTableViewCell
            configureCell(cell, indexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let indexSet = NSIndexSet(index: sectionIndex)
        
        switch type {
        case .Insert:
            tableView.insertSections(indexSet, withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
        default:
            break
        }
    }
}

