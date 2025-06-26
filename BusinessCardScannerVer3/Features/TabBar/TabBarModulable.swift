//
//  TabBarModulable.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine

// MARK: - TabBar Module Interface
protocol TabBarModulable {
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator
}
