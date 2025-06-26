//
//  BusinessCardService.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit

class BusinessCardService {
    private let repository: BusinessCardRepository
    private let photoService: PhotoService
    private let visionService: VisionService
    private let parser: BusinessCardParser
    
    init(repository: BusinessCardRepository,
         photoService: PhotoService,
         visionService: VisionService,
         parser: BusinessCardParser) {
        self.repository = repository
        self.photoService = photoService
        self.visionService = visionService
        self.parser = parser
    }
}
