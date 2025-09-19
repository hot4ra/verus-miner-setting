#!/bin/bash

# =================================================================
# Verus Coin 自動挖礦安裝與啟動腳本
# =================================================================

# --- 步驟 1: 歡迎與初始檢查 ---
echo "========================================="
echo "  Verus Coin 自動安裝與挖礦腳本"
echo "========================================="
echo "正在準備您的 Termux 環境，這可能需要幾分鐘..."
sleep 2

# --- 步驟 2: 更新與升級套件 ---
apt-get update -y
apt-get upgrade -y

# --- 步驟 3: 安裝依賴套件 ---
echo "--- 正在安裝編譯所需的套件..."
apt install -y git wget proot build-essential cmake libmicrohttpd libuv libuuid boost libjansson
if [ $? -ne 0 ]; then
    echo "套件安裝失敗，請檢查網路連線或儲存空間。"
    exit 1
fi

# --- 步驟 4: 克隆並編譯 ccminer ---
echo "--- 正在克隆 ccminer 程式碼..."
git clone --single-branch -b ARM https://github.com/monkins1010/ccminer.git
if [ ! -d "ccminer" ]; then
    echo "ccminer 程式碼克隆失敗，請檢查網路連線。"
    exit 1
fi

echo "--- 正在編譯 ccminer..."
cd ccminer
./build.sh
if [ $? -ne 0 ]; then
    echo "編譯失敗，請檢查錯誤訊息。"
    exit 1
fi
echo "--- 編譯完成。---"

# --- 步驟 5: 詢問錢包地址並生成 start.sh ---
echo "-----------------------------------------"
echo "安裝核心檔案完成，接下來將建立挖礦腳本。"
echo "-----------------------------------------"
read -p "請輸入你的 Verus Coin 錢包地址，然後按 Enter 鍵： " WALLET_ADDRESS

# 如果使用者沒有輸入，則退出
if [ -z "$WALLET_ADDRESS" ]; then
    echo "錢包地址不能為空，安裝中止。"
    exit 1
fi

# 生成 start.sh 腳本
echo "--- 正在建立 start.sh 腳本..."
# 使用 cat << EOF 語法，將 $WALLET_ADDRESS 變數的值直接寫入檔案
cat > start.sh << EOF
#!/bin/bash

# 指定日誌檔案的路徑
LOG_FILE="./mining.log"

# 使用迴圈自動重啟挖礦程式
while true
do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 ccminer ---" | tee -a "\$LOG_FILE"
  # 將使用者輸入的錢包地址直接寫入指令
  ./ccminer -a verus -o stratum+tcp://verus.farm:9999 -u ${WALLET_ADDRESS} -p x -t 8 2>&1 | tee -a "\$LOG_FILE"
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - ccminer 已停止，5秒後將重新啟動 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF

# --- 步驟 6: 賦予 start.sh 執行權限 ---
echo "--- 正在賦予 start.sh 執行權限..."
chmod +x start.sh

# --- 步驟 7: 下載 .bashrc 檔案 ---
echo "--- 正在自動設定 Termux 啟動腳本..."
# 將 GitHub 上的 .bashrc 檔案下載到家目錄
curl -o ~/.bashrc https://raw.githubusercontent.com/你的用戶名/你的倉庫名/main/.bashrc
if [ $? -ne 0 ]; then
    echo "下載 .bashrc 檔案失敗，請手動設定。"
    # 這裡可以選擇退出，或繼續執行後續步驟
fi

# --- 步驟 8: 啟動挖礦 ---
echo "========================================="
echo "  所有設定完成！"
echo "  挖礦程式將在 5 秒後自動啟動。"
echo "  下一次重新開啟 Termux 時將會自動啟動挖礦。"
echo "========================================="
sleep 5
./start.sh
