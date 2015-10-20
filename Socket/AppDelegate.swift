//
//  AppDelegate.swift
//  Socket
//
//  Created by Jameson Kirby on 10/7/15.
//  Copyright © 2015 Jameson Kirby. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //an example of static 3D Touch Icon Shortcut 
    //(static is before the app ever launches, dynamic is after the app launces for the first time)
    
    //check the Info plist and .strings where I identify 'UIApplicationShortcutItems' and title  
    
    //enum of possible default icons 
    
        //UIApplicationShortcutIconTypeCompose,
        //UIApplicationShortcutIconTypePlay,
        //UIApplicationShortcutIconTypePause,
        //UIApplicationShortcutIconTypeAdd,
        //UIApplicationShortcutIconTypeLocation,
        //UIApplicationShortcutIconTypeSearch,
        //UIApplicationShortcutIconTypeShare
    
    
    enum ShortcutIdentifier: String {
        case goToContacts
        case replyToMessage
        
        init?(fullIdentifier: String) {
            guard let shortIdentifier = fullIdentifier.componentsSeparatedByString(".").last else { return nil }
            self.init(rawValue: shortIdentifier)
        }
    }

    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            handleShortcut(shortcutItem)
            return false
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
            coreDataStack.saveContext()
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        completionHandler(handleShortcut(shortcutItem))
    }
    
    private func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcutItem.type
        
        guard let shortcutIdentifier = ShortcutIdentifier(fullIdentifier: shortcutType) else {
            return false
        }
        return selectedShortcutForIdentifier(shortcutIdentifier)
    }
    
    private func selectedShortcutForIdentifier(identifier: ShortcutIdentifier) -> Bool {
        var handled = false
        
        switch (identifier) {
        case .goToContacts:
            handled = true
        case .replyToMessage:
            handled = true
        }
        
        // Construct an alert using the details of the shortcut used to open the application.
        let alertController = UIAlertController(title: "Shortcut Handled", message: "\"\(identifier)\"", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        
        // Display an alert indicating the shortcut selected from the home screen.
        window!.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        
        return handled
    }

}

