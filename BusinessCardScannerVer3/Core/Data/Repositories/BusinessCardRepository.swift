//
//  BusinessCardRepository.swift
//  名片資料存取層
//

import CoreData
import UIKit
class BusinessCardRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
}
