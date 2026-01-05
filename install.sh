#!/bin/bash

# =================================================================
# Verus Coin & Scash 自動化設定腳本 (增量開發 - 自動化安裝版)
# =================================================================

while true
do
# --- 步驟 1: 顯示主選單 ---
echo "========================================="
echo "  Verus & Scash 挖礦自動化設定腳本"
echo "========================================="
echo "請選擇您要執行的操作："
echo ""
echo "  1) 設定啟動Termux時自動挖礦 (Verus)"
echo "  2) 完整安裝 ccminer 挖礦程式 (Verus)"
echo "  3) 替換/生成 .start.sh 監控挖礦腳本 (Verus)"
echo "  4) 安裝 xmrigCC 挖礦程式 (Scash)"
echo "  5) 替換/生成 .start_scash.sh 監控腳本 (Scash)"
echo "  6) 退出腳本"
echo ""
read -p "請輸入你的選擇 (1-6)： " CHOICE

# --- 步驟 2: 根據選擇執行程式碼 ---

# [既有邏輯] 選項 1: Verus 自動啟動
if [ "$CHOICE" == "1" ]; then
    echo "--- 正在設定 Termux 自動啟動... ---"
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

# [既有邏輯 - 已加入自動化參數] 選項 2: Verus 完整安裝
elif [ "$CHOICE" == "2" ]; then
    echo "--- 正在執行完整安裝流程... ---"
    
    # 設定環境變數為非互動模式，並強制套用舊設定檔 (選 N)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    echo "--- 正在安裝編譯所需的套件..."
    # 加入 -y 確保套件安裝自動同意
    apt install -y git wget proot build-essential cmake libmicrohttpd libuv libuuid boost libjansson -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    if [ $? -ne 0 ]; then
        echo "套件安裝失敗，請檢查網路連線或儲存空間。"
        exit 1
    fi
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

# [既有邏輯] 選項 3: Verus 腳本生成
elif [ "$CHOICE" == "3" ]; then
    echo "--- 正在生成挖礦腳本... ---"
    if [[ "$(basename "$PWD")" == "ccminer" ]]; then
        echo "--- 已在 ccminer 目錄，返回上一層..."
        cd ..
    fi
    if [ ! -d "ccminer" ]; then
        echo "ccminer 目錄不存在，請執行選項 2 進行安裝..."
        sleep 3
        CHOICE="2"
        continue
    fi
    cd ccminer || exit 1
    echo "--- 正在刪除舊的 start.sh 腳本... ---"
    rm -f start.sh
    while true
    do
        read -p "請輸入你的 Verus Coin 錢包地址，然後按 Enter 鍵： " WALLET_ADDRESS
        if [ -z "$WALLET_ADDRESS" ]; then
            echo "錢包地址不能為空，請重新輸入。"
        else
            break
        fi
    done
    read -p "請輸入礦工名稱 (可留空，預設為 YH最帥 )： " MINER_NAME
    if [ -z "$MINER_NAME" ]; then
        MINER_NAME="YH最帥"
    fi
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
    echo "========================================="
    echo "  您的設定摘要："
    echo "  錢包地址: $WALLET_ADDRESS"
    echo "  礦工名稱: $MINER_NAME"
    echo "  核心數: $THREADS"
    echo "========================================="
    read -p "確認以上資訊是否正確？ (y/n)： " CONFIRMATION
    if [ "$CONFIRMATION" != "y" ] && [ "$CONFIRMATION" != "Y" ]; then
        echo "取消操作，回到主選單..."
        continue
    fi    
    echo "--- 正在建立 start.sh 腳本..."
    cat > start.sh << EOF
#!/bin/bash
LOG_FILE="./mining.log"
while true
do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 ccminer ---" | tee -a "\$LOG_FILE"
  ./ccminer -a verus -o stratum+tcp://verus.farm:9999 -u ${WALLET_ADDRESS}.${MINER_NAME} -p x -t ${THREADS} 2>&1 | tee -a "\$LOG_FILE"
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - ccminer 已停止，5秒後將重新啟動 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF
    chmod +x start.sh
    echo "========================================="
    echo "  挖礦腳本建立完成！"
    echo "  挖礦程式將在 5 秒後自動啟動。"
    echo "========================================="
    sleep 5
    ./start.sh

# [新增功能 - 已加入自動化參數] 選項 4: Scash (xmrigCC) 安裝
elif [ "$CHOICE" == "4" ]; then
    echo "--- 正在執行 Scash (xmrigCC) 自動安裝流程... ---"
    
    # 同樣套用非互動參數
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt install -y wget tar openssl libcurl -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    # 使用官方永久下載連結
    SCASH_URL="https://github.com/Bendr0id/xmrigCC/releases/download/3.4.9/xmrigCC-miner_only-3.4.9-android-dynamic-arm64.tar.gz"
    echo "--- 正在下載 xmrigCC 3.4.9 (Miner Only) ---"
    wget -O xmrigCC-scash.tar.gz "$SCASH_URL"
    
    echo "--- 正在自動解壓縮... ---"
    mkdir -p xmrigCC-scash
    tar -xf xmrigCC-scash.tar.gz -C xmrigCC-scash --strip-components=1
    
    # 賦予執行權限並清理
    chmod +x xmrigCC-scash/xmrigMiner
    rm xmrigCC-scash.tar.gz
    
    echo "========================================="
    echo "  xmrigCC (Scash) 自動安裝完成！"
    echo "========================================="

# [新增功能] 選項 5: Scash 啟動腳本與設定生成
elif [ "$CHOICE" == "5" ]; then
    echo "--- 正在生成 Scash 挖礦腳本... ---"
    SCASH_DIR="$HOME/xmrigCC-scash"
    
    if [ ! -d "$SCASH_DIR" ]; then
        echo "Scash 目錄不存在，請先執行選項 4 安裝。"
        sleep 2
        continue
    fi

    cd "$SCASH_DIR" || exit 1

    # 1. 詢問 Scash 錢包
    while true; do
        read -p "請輸入你的 Scash 錢包地址 (scash1q...)： " S_WALLET
        if [ -z "$S_WALLET" ]; then echo "不能為空！"; else break; fi
    done

    # 2. 詢問礦工名稱
    read -p "請輸入礦工名稱 (預設: YH)： " S_NAME
    if [ -z "$S_NAME" ]; then S_NAME="YH"; fi

    # 3. 詢問核心數
    while true; do
        read -p "請輸入挖礦核心數 (建議 4 或 6)： " S_THREADS
        if [[ "$S_THREADS" =~ ^[0-9]+$ ]]; then break; else echo "請輸入數字！"; fi
    done

    # 生成 config.json (包含 Donate 1% 邏輯與 rx/scash 優化)
    cat > config.json << EOF
{
    "api": { "id": null, "worker-id": null },
    "donate-level": 1,
    "pools": [
        {
            "algo": "rx/scash",
            "url": "pool.scash.pro:8888",
            "user": "${S_WALLET}.${S_NAME}",
            "pass": "x",
            "keepalive": true,
            "enabled": true,
            "tls": false
        }
    ],
    "cpu": {
        "enabled": true,
        "huge-pages": false,
        "rx": $(seq -s, 0 $((S_THREADS-1)) | sed 's/^/[/;s/$/]/')
    }
}
EOF

    # 生成啟動監控腳本
    cat > start_scash.sh << EOF
#!/bin/bash
while true
do
  echo "--- \$(date) - 啟動 Scash 挖礦 ---"
  ./xmrigMiner -c config.json
  echo "--- 偵測到停止，5秒後重啟 ---"
  sleep 5
done
EOF
    chmod +x start_scash.sh

    echo "========================================="
    echo "  Scash 腳本設定完成！"
    echo "  即將啟動挖礦程式..."
    echo "========================================="
    sleep 2
    ./start_scash.sh

# [既有邏輯] 選項 6: 退出
elif [ "$CHOICE" == "6" ]; then
    echo "腳本已退出，謝謝使用！"
    exit 0

else
    echo "無效的選擇，請重新輸入。"
fi
done
