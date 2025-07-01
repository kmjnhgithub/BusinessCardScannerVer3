//
//  CardListModulable.swift

//
//  Created by mike liu on 2025/6/25.
//

// MARK: - Card List Module Interface
// 最終位置：Features/CardList/CardListModulable.swift

import UIKit
import Combine

protocol CardListModulable {
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator
}



protocol CardListModuleOutput: AnyObject {
    func cardListDidSelectCard(_ card: BusinessCard)
    func cardListDidRequestNewCard()
    func cardListDidRequestNewCard(with option: AddCardOption)
}
