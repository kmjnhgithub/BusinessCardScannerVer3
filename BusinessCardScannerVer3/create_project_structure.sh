#!/bin/bash

# 建立專案資料夾結構的腳本
# 使用方式：在專案根目錄執行 bash create_project_structure.sh

echo "建立 BusinessCardScannerVer3 專案結構..."

# App 層級
mkdir -p App

# Core 模組
mkdir -p Core/Base
mkdir -p Core/Common/UI
mkdir -p Core/Common/Binding
mkdir -p Core/Common/Extensions
mkdir -p Core/Services
mkdir -p Core/Models/Domain
mkdir -p Core/Models/DTO
mkdir -p Core/Models/CoreData
mkdir -p Core/Data/Repositories
mkdir -p Core/DI

# Features 模組
mkdir -p Features/TabBar
mkdir -p Features/CardList/Views
mkdir -p Features/CardCreation/Services
mkdir -p Features/CardCreation/Camera/Views
mkdir -p Features/CardCreation/PhotoPicker
mkdir -p Features/CardCreation/Edit/Views
mkdir -p Features/CardDetail
mkdir -p Features/AIProcessing/Services
mkdir -p Features/AIProcessing/Models
mkdir -p Features/AIProcessing/Settings
mkdir -p Features/Settings/Services
mkdir -p Features/Settings/Storage

# Resources
mkdir -p Resources

# Supporting Files
mkdir -p "Supporting Files"


echo "✅ 專案結構建立完成！"

# 顯示建立的結構
echo "專案結構預覽："
tree -d -L 3

