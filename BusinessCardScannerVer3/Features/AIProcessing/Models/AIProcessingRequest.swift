//

//
//  Created by mike liu on 2025/6/25.
//

import Foundation

struct AIProcessingRequest {
    let ocrText: String
    let imageData: Data?
    let language: String = "zh-TW"
}
