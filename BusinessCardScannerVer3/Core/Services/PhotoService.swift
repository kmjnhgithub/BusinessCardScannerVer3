//
//  PhotoService.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit


class PhotoService {
    func savePhoto(_ image: UIImage, for cardId: UUID) -> String? {
        // 實際實作會在 Task 5.4
        return "photo_\(cardId.uuidString).jpg"
    }
    
    func loadPhoto(path: String) -> UIImage? {
        // 實際實作會在 Task 5.4
        return nil
    }
}
