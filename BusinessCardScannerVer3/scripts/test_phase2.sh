#\!/bin/bash
# 第二階段手動測試腳本
# 使用方法：bash test_phase2.sh

echo "🧪 開始第二階段手動測試..."
echo "================================"

# 基本設定
PROJECT="../BusinessCardScannerVer3.xcodeproj"
SCHEME="BusinessCardScannerVer3"
DESTINATION="platform=iOS Simulator,name=iPhone 16,arch=arm64"

# 測試套件列表（根據測試任務.md第二階段）
declare -a test_suites=(
    "BaseViewModelTests"
    "CardListViewModelTests" 
    "CameraViewModelTests"
    "ContactEditViewModelTests"
    "BusinessCardServiceTests"
    "KeychainServiceTests"
    "ValidationServiceTests"
)

declare -a test_counts=(15 18 25 30 22 15 22)

echo "📋 第二階段測試套件清單："
for i in "${\!test_suites[@]}"; do
    echo "  $((i+1)). ${test_suites[i]} (${test_counts[i]}個測試案例)"
done
echo ""

# 執行測試函數
run_test_suite() {
    local suite_name=$1
    local expected_count=$2
    
    echo "🔍 測試 $suite_name..."
    echo "   預期測試案例數：$expected_count"
    
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"BusinessCardScannerVer3Tests/$suite_name" \
        2>/dev/null | grep -E "(passed|failed|Test Suite)" | tail -5
    
    echo "   ✅ $suite_name 測試完成"
    echo ""
}

# 選擇測試模式
echo "請選擇測試模式："
echo "1. 執行所有測試套件"
echo "2. 選擇特定測試套件"
echo "3. 僅執行成功驗證的測試"
read -p "請輸入選項 (1-3): " choice

case $choice in
    1)
        echo "🚀 執行所有7個測試套件..."
        for i in "${\!test_suites[@]}"; do
            run_test_suite "${test_suites[i]}" "${test_counts[i]}"
        done
        ;;
    2)
        echo "請選擇要測試的套件："
        for i in "${\!test_suites[@]}"; do
            echo "  $((i+1)). ${test_suites[i]}"
        done
        read -p "請輸入套件編號 (1-7): " suite_choice
        if [[ $suite_choice -ge 1 && $suite_choice -le 7 ]]; then
            idx=$((suite_choice-1))
            run_test_suite "${test_suites[idx]}" "${test_counts[idx]}"
        else
            echo "❌ 無效選擇"
        fi
        ;;
    3)
        echo "🎯 執行已驗證成功的測試..."
        run_test_suite "BaseViewModelTests" 15
        run_test_suite "KeychainServiceTests" 15
        ;;
    *)
        echo "❌ 無效選擇"
        ;;
esac

echo "🎉 第二階段手動測試完成！"
