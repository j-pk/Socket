//
//  Person+CoreDataProperties.swift
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

extension Person {

    @NSManaged var name: String?
    @NSManaged var messages: NSOrderedSet?

}
