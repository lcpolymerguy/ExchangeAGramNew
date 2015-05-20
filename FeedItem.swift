//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Morgan Hart on 5/19/15.
//  Copyright (c) 2015 Morgan Hart. All rights reserved.
//

import Foundation
import CoreData

@objc(FeedItem)

class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbNail: NSData

}
