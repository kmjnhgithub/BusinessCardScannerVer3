//
//  CardDetailModulable.swift
//  BusinessCardScannerVer3
//
//  Created by mike liu on 2025/6/25.
//

import UIKit

// MARK: - Card Detail Module Interface

protocol CardDetailModulable {
    func makeCoordinator(
        navigationController: UINavigationController,
        card: BusinessCard
    ) -> Coordinator
}

protocol CardDetailModuleOutput: AnyObject {
    func cardDetailDidDeleteCard(_ card: BusinessCard)
    func cardDetailDidUpdateCard(_ card: BusinessCard)
}
