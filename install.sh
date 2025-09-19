# --- 步驟 7: 下載 .bashrc 檔案 ---
echo "--- 正在自動設定 Termux 啟動腳本..."
# 將 GitHub 上的 .bashrc 檔案下載到家目錄
curl -o ~/.bashrc https://raw.githubusercontent.com/你的用戶名/你的倉庫名/main/.bashrc
if [ $? -ne 0 ]; then
    echo "下載 .bashrc 檔案失敗，請手動設定。"
    # 這裡可以選擇退出，或繼續執行後續步驟
fi
