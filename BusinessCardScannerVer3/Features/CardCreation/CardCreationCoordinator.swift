//
//  CardCreationCoordinator.swift
//  BusinessCardScanner
//
//  Card creation and editing flow coordinator
//

import UIKit
import Combine
import PhotosUI

class CardCreationCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    weak var moduleOutput: CardCreationModuleOutput?
    private let dependencies: ServiceContainer
    private let sourceType: CardCreationSourceType
    private let editingCard: BusinessCard?
    private var currentViewController: UIViewController?
    private var cancellables = Set<AnyCancellable>()
    private var temporaryPhoto: UIImage? // 追蹤暫存照片以便清理
    
    // 持有子 Coordinator 的引用
    private var photoPickerCoordinator: PhotoPickerCoordinator?
    
    // 追蹤當前的ContactEditViewController用於照片更新
    private weak var currentEditViewController: ContactEditViewController?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController, 
         dependencies: ServiceContainer,
         sourceType: CardCreationSourceType,
         editingCard: BusinessCard? = nil) {
        self.dependencies = dependencies
        self.sourceType = sourceType
        self.editingCard = editingCard
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Flow
    
    override func start() {
        print("📱 CardCreationCoordinator: 啟動，來源類型: \(sourceType)")
        
        // 檢查是否有既有名片要編輯
        if let editingCard = editingCard {
            print("📝 編輯既有名片: \(editingCard.name)")
            showEditForm(for: editingCard)
            return
        }
        
        // 否則根據來源類型啟動相應流程
        switch sourceType {
        case .camera:
            startCameraFlow()
        case .photoLibrary:
            startPhotoLibraryFlow()
        case .manual:
            startManualEntryFlow()
        }
    }
    
    /// 啟動手動輸入流程
    private func startManualEntryFlow() {
        showManualEntry()
    }
    
    // MARK: - Public Methods
    
    /// 啟動相機拍攝流程
    func startCameraFlow() {
        checkCameraPermissionAndProceed { [weak self] in
            self?.presentCamera()
        }
    }
    
    /// 啟動相簿選擇流程
    func startPhotoLibraryFlow() {
        checkPhotoLibraryPermissionAndProceed { [weak self] in
            self?.presentPhotoLibrary()
        }
    }
    
    /// 處理拍攝或選擇的圖片
    func processSelectedImage(_ image: UIImage) {
        print("📱 CardCreationCoordinator: 開始處理選擇的圖片")
        
        // 儲存暫存照片供後續清理使用
        temporaryPhoto = image
        
        print("📱 CardCreationCoordinator: 呼叫 BusinessCardService.processImage")
        // 使用 BusinessCardService 處理圖片
        dependencies.businessCardService.processImage(image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                print("📱 CardCreationCoordinator: 收到 BusinessCardService 處理結果")
                switch result {
                case .success(let parsedData, let croppedImage):
                    print("✅ 圖片處理成功，顯示編輯表單（使用裁切後的圖片）")
                    self?.showEditForm(with: parsedData, photo: croppedImage)
                    
                case .ocrFailed(let originalImage):
                    print("⚠️ OCR 失敗，提供選項讓用戶繼續")
                    self?.handleOCRFailure(with: originalImage)
                    
                case .processingFailed(let error):
                    print("❌ 圖片處理失敗: \(error.localizedDescription)")
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 顯示新增名片編輯頁面（來自 OCR 結果）
    func showEditForm(with initialData: ParsedCardData, photo: UIImage?) {
        print("📱 CardCreationCoordinator: 準備顯示編輯表單")
        let editViewModel = ContactEditViewModel(
            repository: dependencies.businessCardRepository,
            photoService: dependencies.photoService,
            businessCardService: dependencies.businessCardService,
            existingCard: nil,
            initialData: initialData,
            initialPhoto: photo
        )
        
        let editViewController = ContactEditViewController(viewModel: editViewModel)
        editViewController.delegate = self
        editViewController.sourceType = sourceType // 設置來源類型
        
        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .pageSheet
        
        currentViewController = navController
        navigationController.present(navController, animated: true)
    }
    
    /// 顯示編輯現有名片頁面
    func showEditForm(for existingCard: BusinessCard) {
        let editViewModel = ContactEditViewModel(
            repository: dependencies.businessCardRepository,
            photoService: dependencies.photoService,
            businessCardService: dependencies.businessCardService,
            existingCard: existingCard
        )
        
        let editViewController = ContactEditViewController(viewModel: editViewModel)
        editViewController.delegate = self
        editViewController.sourceType = sourceType // 設置來源類型
        
        // 追蹤當前編輯控制器用於照片更新
        currentEditViewController = editViewController
        
        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .pageSheet
        
        currentViewController = navController
        navigationController.present(navController, animated: true)
    }
    
    /// 顯示手動新增名片頁面
    func showManualEntry() {
        let editViewModel = ContactEditViewModel(
            repository: dependencies.businessCardRepository,
            photoService: dependencies.photoService,
            businessCardService: dependencies.businessCardService
        )
        
        let editViewController = ContactEditViewController(viewModel: editViewModel)
        editViewController.delegate = self
        editViewController.sourceType = sourceType // 設置來源類型
        
        // 追蹤當前編輯控制器用於照片更新
        currentEditViewController = editViewController
        
        let navController = UINavigationController(rootViewController: editViewController)
        navController.modalPresentationStyle = .pageSheet
        
        currentViewController = navController
        navigationController.present(navController, animated: true)
    }
}

// MARK: - Private Methods

private extension CardCreationCoordinator {
    
    /// 檢查相機權限並繼續
    func checkCameraPermissionAndProceed(completion: @escaping () -> Void) {
        dependencies.permissionManager.requestCameraPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion()
                case .denied, .restricted:
                    self?.showPermissionDeniedAlert(for: .camera)
                case .notDetermined:
                    self?.showPermissionDeniedAlert(for: .camera)
                @unknown default:
                    self?.showPermissionDeniedAlert(for: .camera)
                }
            }
        }
    }
    
    /// 檢查相簿權限並繼續
    func checkPhotoLibraryPermissionAndProceed(completion: @escaping () -> Void) {
        dependencies.permissionManager.requestPhotoLibraryPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion()
                case .denied, .restricted:
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                case .notDetermined:
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                @unknown default:
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                }
            }
        }
    }
    
    /// 顯示相機
    func presentCamera() {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: cameraViewController)
        navController.modalPresentationStyle = .fullScreen
        
        currentViewController = navController
        navigationController.present(navController, animated: true)
    }
    
    /// 從指定的ViewController顯示相機
    private func presentCameraFrom(_ parentController: UIViewController) {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: cameraViewController)
        navController.modalPresentationStyle = .fullScreen
        
        parentController.present(navController, animated: true)
    }
    
    /// 顯示相簿選擇器
    func presentPhotoLibrary() {
        print("📁 CardCreationCoordinator: 準備啟動相簿選擇器")
        
        let moduleFactory = ModuleFactory()
        let coordinator = PhotoPickerCoordinator(
            navigationController: navigationController,
            moduleFactory: moduleFactory
        )
        coordinator.moduleOutput = self
        
        // 持有引用以防止過早釋放
        self.photoPickerCoordinator = coordinator
        
        // 啟動 coordinator
        coordinator.start()
        
        print("✅ CardCreationCoordinator: 相簿選擇器啟動完成")
    }
    
    /// 從指定的ViewController顯示相簿選擇器
    private func presentPhotoLibraryFrom(_ parentController: UIViewController) {
        print("📁 CardCreationCoordinator: 從編輯頁面啟動相簿選擇器")
        
        // 先檢查權限
        dependencies.permissionManager.requestPhotoLibraryPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.presentPhotoPickerDirectly(from: parentController)
                default:
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                }
            }
        }
    }
    
    /// 直接呈現相簿選擇器
    private func presentPhotoPickerDirectly(from parentController: UIViewController) {
        // 配置 PHPicker
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        // 建立選擇器
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        
        // 在指定的controller上呈現
        parentController.present(picker, animated: true)
        
        print("✅ CardCreationCoordinator: 相簿選擇器啟動完成")
    }
    
    /// 處理 OCR 失敗情況
    func handleOCRFailure(with image: UIImage) {
        let alert = UIAlertController(
            title: "文字識別失敗",
            message: "無法從圖片中識別文字，您可以選擇手動輸入資料或重新拍攝。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "手動輸入", style: .default) { [weak self] _ in
            let emptyData = ParsedCardData()
            self?.showEditForm(with: emptyData, photo: image)
        })
        
        alert.addAction(UIAlertAction(title: "重新拍攝", style: .default) { [weak self] _ in
            self?.startCameraFlow()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.moduleOutput?.cardCreationDidCancel()
        })
        
        navigationController.present(alert, animated: true)
    }
    
    /// 顯示錯誤提示
    func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "處理失敗",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            self?.moduleOutput?.cardCreationDidCancel()
        })
        
        navigationController.present(alert, animated: true)
    }
    
    /// 顯示權限拒絕提示
    func showPermissionDeniedAlert(for type: PermissionManager.PermissionType) {
        dependencies.permissionManager.showPermissionSettingsAlert(
            for: type,
            from: navigationController
        )
    }
    
    /// 清理暫存資源
    private func cleanupTemporaryResources() {
        print("🧹 CardCreationCoordinator: 清理暫存資源")
        
        // 根據架構文檔，取消時需要清理暫存照片
        if temporaryPhoto != nil {
            print("📸 清理暫存照片")
            // 在這裡可以實現特定的照片清理邏輯
            // 例如：從暫存目錄刪除、釋放記憶體等
            self.temporaryPhoto = nil
        }
        
        // 清理其他暫存資源
        cancellables.removeAll()
    }
}

// MARK: - CameraViewController Delegate

extension CardCreationCoordinator: CameraViewControllerDelegate {
    
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
        print("📸 CardCreationCoordinator: 收到拍攝的圖片")
        
        // 關閉相機界面
        currentViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // 檢查是否為手動輸入模式
            if self.sourceType == .manual {
                print("📸 手動輸入模式：直接更新照片，不進行 OCR")
                // 手動輸入模式：直接更新照片，不進行 OCR
                self.updateEditViewPhoto(image)
            } else if self.currentEditViewController != nil {
                print("📸 編輯頁面拍攝：嘗試偵測名片區域後更新")
                // 編輯頁面拍攝：嘗試偵測和裁切名片，但不進行 OCR
                self.processPhotoForEditing(image)
            } else {
                print("📸 處理照片進行完整 OCR 流程")
                // 其他情況：進行完整的 OCR 處理
                self.processSelectedImage(image)
            }
        }
    }
    
    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        print("❌ CardCreationCoordinator: 使用者取消拍攝")
        
        // 關閉相機界面
        currentViewController?.dismiss(animated: true) { [weak self] in
            // 清理暫存資源
            self?.cleanupTemporaryResources()
            self?.moduleOutput?.cardCreationDidCancel()
        }
    }
    
    func cameraViewControllerDidRequestGallery(_ controller: CameraViewController) {
        print("📁 CardCreationCoordinator: 使用者從相機切換到相簿")
        
        // 關閉相機界面
        currentViewController?.dismiss(animated: true) { [weak self] in
            // 直接啟動相簿選擇流程
            self?.startPhotoLibraryFlow()
        }
    }
}

// MARK: - PhotoPickerCoordinator Delegate

extension CardCreationCoordinator: PhotoPickerModuleOutput {
    
    func photoPickerDidSelectImage(_ image: UIImage) {
        print("📷 CardCreationCoordinator: 收到選擇的相簿圖片，尺寸: \(image.size)")
        
        // 清理 PhotoPickerCoordinator 引用
        photoPickerCoordinator = nil
        
        print("📷 CardCreationCoordinator: 開始處理選擇的圖片")
        // 處理選擇的圖片
        processSelectedImage(image)
    }
    
    func photoPickerDidCancel() {
        print("❌ CardCreationCoordinator: 使用者取消相簿選擇")
        
        // 清理 PhotoPickerCoordinator 引用
        photoPickerCoordinator = nil
        
        // 清理暫存資源
        cleanupTemporaryResources()
        moduleOutput?.cardCreationDidCancel()
    }
}

// MARK: - ContactEditViewControllerDelegate

extension CardCreationCoordinator: ContactEditViewControllerDelegate {
    
    func contactEditViewController(_ controller: ContactEditViewController, didSaveCard card: BusinessCard) {
        print("✅ CardCreationCoordinator: 名片儲存成功 - \(card.name)")
        
        // 關閉編輯頁面
        currentViewController?.dismiss(animated: true) { [weak self] in
            // 通知父 Coordinator
            self?.moduleOutput?.cardCreationDidFinish(with: card)
        }
    }
    
    func contactEditViewControllerDidCancel(_ controller: ContactEditViewController) {
        print("❌ CardCreationCoordinator: 使用者取消編輯")
        
        // 關閉編輯頁面
        currentViewController?.dismiss(animated: true) { [weak self] in
            // 清理暫存資源（根據架構文檔）
            self?.cleanupTemporaryResources()
            // 通知父 Coordinator
            self?.moduleOutput?.cardCreationDidCancel()
        }
    }
    
    // 新增：處理儲存成功後的選項
    func contactEditViewController(_ controller: ContactEditViewController, didSaveCard card: BusinessCard, shouldShowContinueOptions: Bool) {
        print("✅ CardCreationCoordinator: 名片儲存成功 - \(card.name), 需要繼續選項: \(shouldShowContinueOptions)")
        
        // 關閉編輯頁面
        currentViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            if shouldShowContinueOptions {
                // 使用者選擇「繼續」- 根據來源類型重新啟動相應流程
                self.handleContinueFlow()
            } else {
                // 使用者選擇「完成」- 結束模組
                self.moduleOutput?.cardCreationDidFinish(with: card)
            }
        }
    }
    
    /// 處理繼續流程
    private func handleContinueFlow() {
        print("🔄 CardCreationCoordinator: 處理繼續流程，來源類型: \(sourceType)")
        
        // 清理之前的暫存資源
        temporaryPhoto = nil
        
        // 根據來源類型重新啟動相應流程
        switch sourceType {
        case .camera:
            // 重新啟動相機流程
            startCameraFlow()
        case .photoLibrary:
            // 重新啟動相簿選擇流程
            startPhotoLibraryFlow()
        case .manual:
            // 手動輸入不應該到這裡，但以防萬一
            showManualEntry()
        }
    }
    
    // MARK: - Photo Selection Delegate Methods
    
    func contactEditViewControllerDidRequestCameraPhoto(_ controller: ContactEditViewController) {
        print("📸 CardCreationCoordinator: 用戶請求相機拍照")
        
        // 檢查權限並啟動相機
        checkCameraPermissionAndProceed { [weak self] in
            // 在編輯頁面之上present相機
            self?.presentCameraFrom(controller)
        }
    }
    
    func contactEditViewControllerDidRequestLibraryPhoto(_ controller: ContactEditViewController) {
        print("🖼️ CardCreationCoordinator: 用戶請求相簿選擇")
        
        // 檢查權限並啟動相簿選擇
        checkPhotoLibraryPermissionAndProceed { [weak self] in
            // 在編輯頁面之上present相簿選擇器
            self?.presentPhotoLibraryFrom(controller)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CardCreationCoordinator: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            print("❌ CardCreationCoordinator: 沒有選擇照片")
            return
        }
        
        // 處理選擇的照片
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ CardCreationCoordinator: 載入照片失敗: \(error.localizedDescription)")
                    return
                }
                
                guard let image = object as? UIImage else {
                    print("❌ CardCreationCoordinator: 照片格式不正確")
                    return
                }
                
                print("✅ CardCreationCoordinator: 成功載入照片")
                
                // 檢查是否為手動輸入模式
                if self.sourceType == .manual {
                    print("📷 手動輸入模式：直接更新照片，不進行 OCR")
                    // 手動輸入模式：直接更新照片，不進行 OCR
                    self.updateEditViewPhoto(image)
                } else if self.currentEditViewController != nil {
                    print("📷 編輯頁面選擇照片：嘗試偵測名片區域後更新")
                    // 編輯頁面選擇照片：嘗試偵測和裁切名片，但不進行 OCR
                    self.processPhotoForEditing(image)
                } else {
                    print("📷 處理照片進行完整 OCR 流程")
                    // 其他情況：進行完整的 OCR 處理
                    self.processSelectedImage(image)
                }
            }
        }
    }
    
    /// 處理編輯頁面的照片選擇（嘗試偵測名片區域但不進行 OCR）
    private func processPhotoForEditing(_ image: UIImage) {
        print("📷 CardCreationCoordinator: 嘗試偵測和裁切名片區域")
        
        // 使用 VisionService 嘗試偵測和裁切名片
        dependencies.visionService.detectRectangle(in: image) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let observation):
                    print("✅ 偵測到名片區域，進行裁切")
                    // 偵測成功，進行裁切
                    self.dependencies.visionService.cropCard(from: image, observation: observation) { cropResult in
                        DispatchQueue.main.async {
                            switch cropResult {
                            case .success(let croppedImage):
                                print("✅ 名片裁切成功，更新編輯頁面照片")
                                self.updateEditViewPhoto(croppedImage)
                            case .failure(_):
                                print("⚠️ 名片裁切失敗，使用原圖")
                                self.updateEditViewPhoto(image)
                            }
                        }
                    }
                case .failure(_):
                    print("⚠️ 未偵測到名片區域，使用原圖")
                    // 偵測失敗，直接使用原圖
                    self.updateEditViewPhoto(image)
                }
            }
        }
    }
    
    /// 更新編輯頁面的照片
    private func updateEditViewPhoto(_ image: UIImage) {
        print("📷 CardCreationCoordinator: 更新編輯頁面照片")
        // 使用追蹤的編輯控制器更新照片
        currentEditViewController?.updatePhoto(image)
    }
}

// MARK: - CardCreationCoordinator Factory

extension CardCreationCoordinator {
    
    static func make(navigationController: UINavigationController, 
                    dependencies: ServiceContainer,
                    sourceType: CardCreationSourceType,
                    editingCard: BusinessCard? = nil) -> CardCreationCoordinator {
        return CardCreationCoordinator(
            navigationController: navigationController,
            dependencies: dependencies,
            sourceType: sourceType,
            editingCard: editingCard
        )
    }
}