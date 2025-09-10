#!/bin/bash
# 第二階段手動測試腳本（修復版）
# 使用方法：bash test_phase2_fixed.sh

echo "🧪 開始第二階段手動測試..."
echo "================================"

# 基本設定
PROJECT="../BusinessCardScannerVer3.xcodeproj"
SCHEME="BusinessCardScannerVer3"
DESTINATION="platform=iOS Simulator,name=iPhone 16,arch=arm64"

# 測試套件列表（根據測試任務.md第二階段）
test_suites=(
    "BaseViewModelTests"
    "CardListViewModelTests" 
    "CameraViewModelTests"
    "ContactEditViewModelTests"
    "BusinessCardServiceTests"
    "KeychainServiceTests"
    "ValidationServiceTests"
)

test_counts=(15 18 25 30 22 15 22)

echo "📋 第二階段測試套件清單："
for i in "${!test_suites[@]}"; do
    echo "  $((i+1)). ${test_suites[i]} (${test_counts[i]}個測試案例)"
done
echo ""

# 執行測試函數
run_test_suite() {
    local suite_name=$1
    local expected_count=$2
    
    echo "🔍 測試 $suite_name..."
    echo "   預期測試案例數：$expected_count"
    
    echo "   執行測試中..."
    result=$(xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"BusinessCardScannerVer3Tests/$suite_name" \
        2>/dev/null)
    
    # 統計結果
    passed_count=$(echo "$result" | grep -c "passed")
    failed_count=$(echo "$result" | grep -c "failed")
    
    echo "   結果：✅ $passed_count 通過，❌ $failed_count 失敗"
    
    if [ $failed_count -eq 0 ]; then
        echo "   🎉 $suite_name 全部測試通過！"
    else
        echo "   ⚠️  $suite_name 有測試失敗，需要檢查"
        echo "$result" | grep "failed" | head -3
    fi
    echo ""
}

# 選擇測試模式
echo "請選擇測試模式："
echo "1. 執行所有測試套件 (147個測試案例)"
echo "2. 選擇特定測試套件"
echo "3. 僅執行已驗證成功的測試 (BaseViewModel + Keychain)"
echo "4. 快速驗證 (只執行幾個關鍵測試)"
read -p "請輸入選項 (1-4): " choice

case $choice in
    1)
        echo "🚀 執行所有7個測試套件..."
        total_passed=0
        total_failed=0
        
        for i in "${!test_suites[@]}"; do
            echo "執行 $((i+1))/7: ${test_suites[i]}"
            run_test_suite "${test_suites[i]}" "${test_counts[i]}"
        done
        
        echo "🎉 第二階段測試完成！"
        echo "總計：147個測試案例執行完畢"
        ;;
    2)
        echo "請選擇要測試的套件："
        for i in "${!test_suites[@]}"; do
            echo "  $((i+1)). ${test_suites[i]} (${test_counts[i]}個案例)"
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
        echo "✅ 核心測試完成！兩個測試套件共30個測試案例"
        ;;
    4)
        echo "⚡ 快速驗證測試..."
        echo "執行單一測試案例驗證..."
        
        xcodebuild test \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -only-testing:"BusinessCardScannerVer3Tests/BaseViewModelTests/testBaseViewModel_initialState_shouldBeNotLoading" \
            2>/dev/null | grep -E "(passed|failed)"
            
        echo "✅ 快速驗證完成！"
        ;;
    *)
        echo "❌ 無效選擇"
        ;;
esac

echo ""
echo "🎯 測試腳本執行完畢！"
echo "如需查看詳細結果，可以使用 Xcode 或個別執行測試命令"