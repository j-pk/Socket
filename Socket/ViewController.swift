//
//  ViewController.swift
//  Socket
//
//  Created by Jameson Kirby on 10/7/15.
//  Copyright © 2015 Jameson Kirby. All rights reserved.
//

import UIKit
import Socket_IO_Client_Swift

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var sendMessage: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var isTypingStatusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
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
    let defaults = NSUserDefaults.standardUserDefaults()
    var timer: NSTimer? = nil
    var connected = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.grayColor()
        disconnectButton.enabled = false
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
        socket.on("user joined") { [unowned self] data, _ in
            if let response = data.first as? String {
                self.textView.text.appendContentsOf("\(response) joined. \n")
            }
        }

        socket.on("user left") { [unowned self] data, _ in
            print("Data Response: \(data)")
            if let response = data.first as? String {
                self.textView.text.appendContentsOf("\(response) left. \n")
            }
        }

        socket.on("chat message") { [unowned self] data, _ in
            if let response = data as? [String] {
                self.textView.text.appendContentsOf("\(response[0]): \(response[1]) \n")
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

