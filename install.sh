#!/bin/bash

# =================================================================
# Verus Coin 自動化設定腳本
# =================================================================

while true
do
# --- 步驟 1: 顯示主選單 ---
echo "========================================="
echo "  Verus Coin 自動化設定腳本"
echo "========================================="
echo "請選擇您要執行的操作："
echo ""
echo "  1) 設定啟動Termux時自動挖礦"
echo "  2) 完整安裝 ccminer 挖礦程式"
echo "  3) 替換/生成 .start.sh 監控挖礦腳本 (可防止挖礦中斷時自動重啟)"
echo "  4) 退出腳本"
echo ""
read -p "請輸入你的選擇 (1, 2, 3, 或 4)： " CHOICE

# --- 步驟 2: 根據選擇執行程式碼 ---
if [ "$CHOICE" == "1" ]; then
    # --- 選項 1: 僅設定自動啟動 ---
    
    echo "--- 正在設定 Termux 自動啟動... ---"
    
    # 自動下載並設定 .bashrc
    echo "--- 正在自動設定 Termux 啟動腳本..."
    curl -o ~/.bashrc https://raw.githubusercontent.com/hot4ra/verus-miner-setting/main/.bashrc
    if [ $? -ne 0 ]; then
        echo "下載 .bashrc 檔案失敗，請手動設定。"
    else
        echo "自動啟動設定成功！"
    fi
    
    echo "========================================="
    echo "  設定完成！"
    echo "========================================="

    # 執行 ~/.bashrc 中的命令以立即啟動挖礦
    echo "--- 正在立即啟動挖礦... ---"
    source ~/.bashrc

elif [ "$CHOICE" == "2" ]; then
    # --- 選項 2: 完整安裝流程 ---
    
    echo "--- 正在執行完整安裝流程... ---"
    
    # 安裝與升級套件
    apt-get update -y
    export DEBIAN_FRONTEND=noninteractive
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    # 安裝依賴套件
    echo "--- 正在安裝編譯所需的套件..."
    apt install -y git wget proot build-essential cmake libmicrohttpd libuv libuuid boost libjansson
    if [ $? -ne 0 ]; then
        echo "套件安裝失敗，請檢查網路連線或儲存空間。"
        exit 1
    fi

    # 克隆並編譯 ccminer
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
    
    echo "========================================="
    echo "  ccminer 安裝和編譯完成！"
    echo "========================================="

elif [ "$CHOICE" == "3" ]; then
    # --- 選項 3: 替換/生成 .start.sh 監控挖礦腳本 (可防止挖礦中斷時自動重啟) ---
    
    echo "--- 正在生成挖礦腳本... ---"
    
    # 判斷是否已在 ccminer 目錄下，若是則返回上一層
    if [[ "$(basename "$PWD")" == "ccminer" ]]; then
        echo "--- 已在 ccminer 目錄，返回上一層..."
        cd ..
    fi
    
    # 確保在正確的目錄下
    if [ ! -d "ccminer" ]; then
        echo "錯誤：ccminer 目錄不存在。請先執行選項 2 安裝程式。"
        continue
    fi
    cd ccminer || exit 1

    # 刪除舊的 start.sh
    echo "--- 正在刪除舊的 start.sh 腳本... ---"
    rm -f start.sh

    # 詢問錢包地址
    while true
    do
        read -p "請輸入你的 Verus Coin 錢包地址，然後按 Enter 鍵： " WALLET_ADDRESS
        if [ -z "$WALLET_ADDRESS" ]; then
            echo "錢包地址不能為空，請重新輸入。"
        else
            break
        fi
    done

    # 詢問核心數
    while true
    do
        echo ""
        read -p "請輸入要使用的挖礦核心數 (4, 6, 或 8)： " THREADS
        if [ "$THREADS" == "4" ] || [ "$THREADS" == "6" ] || [ "$THREADS" == "8" ]; then
            break
        else
            echo "輸入錯誤，請重新輸入。"
        fi
    done

    # 生成 start.sh 腳本
    echo "--- 正在建立 start.sh 腳本..."
    cat > start.sh << EOF
#!/bin/bash

# 指定日誌檔案的路徑
LOG_FILE="./mining.log"

# 使用迴圈自動重啟挖礦程式
while true
do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 ccminer ---" | tee -a "\$LOG_FILE"
  ./ccminer -a verus -o stratum+tcp://verus.farm:9999 -u ${WALLET_ADDRESS} -p x -t ${THREADS} 2>&1 | tee -a "\$LOG_FILE"
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - ccminer 已停止，5秒後將重新啟動 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF

    # 賦予 start.sh 執行權限
    echo "--- 正在賦予 start.sh 執行權限..."
    chmod +x start.sh

    echo "========================================="
    echo "  挖礦腳本建立完成！"
    echo "  挖礦程式將在 5 秒後自動啟動。"
    echo "========================================="
    sleep 5
    ./start.sh

elif [ "$CHOICE" == "4" ]; then
    echo "腳本已退出，謝謝使用！"
    exit 0

else
    # 無效輸入
    echo "無效的選擇，請重新輸入。"
fi
done
