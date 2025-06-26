//
//  SettingsModulable.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine


// MARK: - Settings Module Interface
protocol SettingsModulable {
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator
}

protocol SettingsModuleOutput: AnyObject {
    func settingsDidClearAllData()
    func settingsDidUpdateAIConfiguration()
}
