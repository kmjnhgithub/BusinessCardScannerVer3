//
//  CardCreationModulable.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine

// MARK: - Card Creation Module Interface

protocol CardCreationModulable {
    func makeCoordinator(
        navigationController: UINavigationController,
        sourceType: CardCreationSourceType,
        editingCard: BusinessCard?
    ) -> Coordinator
}

enum CardCreationSourceType {
    case camera
    case photoLibrary
    case manual
}

protocol CardCreationModuleOutput: AnyObject {
    func cardCreationDidFinish(with card: BusinessCard)
    func cardCreationDidCancel()
    func cardCreationRequestsContinue()
}
