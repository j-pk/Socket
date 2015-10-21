//
//  Message+CoreDataProperties.swift
//  
//
//  Created by Jameson Kirby on 10/21/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Message {

    @NSManaged var chatMessage: String?
    @NSManaged var date: NSDate?
    @NSManaged var person: Person?

}
