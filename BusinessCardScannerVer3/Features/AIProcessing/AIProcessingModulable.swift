//
//  AIProcessingModulable.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine

// MARK: - AI Processing Module Interface

protocol AIProcessingModulable {
    var isAvailable: Bool { get }
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator
}

protocol AIProcessingModuleOutput: AnyObject {
    func aiProcessingDidComplete(with data: ParsedCardData)
    func aiProcessingDidFail(with error: Error)
}
