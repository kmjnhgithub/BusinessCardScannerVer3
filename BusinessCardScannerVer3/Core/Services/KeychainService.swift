//
//  KeychainService.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit

class KeychainService {
    private var storage: [String: String] = [:]
    
    func saveString(_ string: String, for key: String) -> Bool {
        storage[key] = string
        return true
    }
    
    func loadString(for key: String) -> String? {
        return storage[key]
    }
}
