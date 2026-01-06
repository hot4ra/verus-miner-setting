#!/bin/bash

# =================================================================
# Verus Coin & Scash 自動化設定腳本 (增量開發 - 雙重監控自動重啟版)
# =================================================================

while true
do
# --- 步驟 1: 顯示主選單 ---
echo "========================================="
echo "  Verus & Scash 挖礦自動化設定腳本"
echo "========================================="
echo "請選擇您要執行的操作："
echo ""
echo "  1) 設定啟動Termux時自動挖礦 (可選 Verus 或 Scash)"
echo "  2) 完整安裝 ccminer 挖礦程式 (Verus)"
echo "  3) 替換/生成 .start.sh 監控挖礦腳本 (Verus)"
echo "  4) 安裝 xmrigCC 挖礦程式 (Scash)"
echo "  5) 替換/生成 .start_scash.sh 監控腳本 (Scash)"
echo "  6) 退出腳本"
echo ""
read -p "請輸入你的選擇 (1-6)： " CHOICE

# --- 步驟 2: 根據選擇執行程式碼 ---

# [修改後邏輯] 選項 1: 啟動選單設定，確保對應到具備重啟功能的腳本
if [ "$CHOICE" == "1" ]; then
    echo "--- 設定 Termux 啟動自動挖礦項目 ---"
    echo "  1) 啟動時自動挖 Verus (具備自動重啟功能)"
    echo "  2) 啟動時自動挖 Scash (具備自動重啟功能)"
    echo "  3) 關閉自動啟動功能"
    read -p "請輸入選擇 (1, 2, 或 3)： " AUTO_MODE

    case $AUTO_MODE in
        1)
            cat > ~/.bashrc << EOF
termux-wake-lock
cd ~/ccminer
./start.sh
EOF
            echo "已設定：啟動時自動執行 Verus 監控腳本。"
            ;;
        2)
            cat > ~/.bashrc << EOF
termux-wake-lock
cd ~
./start_scash.sh
EOF
            echo "已設定：啟動時自動執行 Scash 監控腳本。"
            ;;
        3)
            > ~/.bashrc
            echo "自動啟動功能已關閉。"
            ;;
        *)
            echo "無效輸入，取消設定。"
            ;;
    esac

    echo "--- 正在安裝 Scash (含環境修復)... ---"
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y
    pkg upgrade -y 
    pkg install wget tar -y

    echo "========================================="
    echo "  升版完成！"
    echo "========================================="
    

# [既有邏輯] 選項 2: Verus 完整安裝
elif [ "$CHOICE" == "2" ]; then
    echo "--- 正在執行 Verus 全自動安裝 (不詢問 Y/N)... ---"
    export DEBIAN_FRONTEND=noninteractive
    yes '' | apt-get update -y
    yes '' | apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    echo "--- 正在安裝編譯所需的套件..."
    yes '' | apt-get install -y git wget proot build-essential cmake libmicrohttpd libuv libuuid boost libjansson -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    if [ $? -ne 0 ]; then
        echo "套件安裝失敗。"
        exit 1
    fi
    echo "--- 正在克隆並編譯 ccminer ---"
    git clone --single-branch -b ARM https://github.com/monkins1010/ccminer.git
    cd ccminer && ./build.sh
    echo "========================================="
    echo "  ccminer 安裝完成！"
    echo "========================================="

# [既有邏輯] 選項 3: Verus 腳本生成 (含自動重啟邏輯)
elif [ "$CHOICE" == "3" ]; then
    echo "--- 正在生成 Verus 挖礦腳本... ---"
    [[ "$(basename "$PWD")" == "ccminer" ]] && cd ..
    if [ ! -d "ccminer" ]; then
        echo "請先安裝 Verus。"
        sleep 2
        continue
    fi
    cd ccminer || exit 1
    rm -f start.sh
    read -p "請輸入錢包地址： " WALLET_ADDRESS
    read -p "礦工名稱 (預設: YH最帥)： " MINER_NAME
    MINER_NAME=${MINER_NAME:-"YH最帥"}
    read -p "核心數 (4, 6, 8)： " THREADS
    cat > start.sh << EOF
#!/bin/bash
LOG_FILE="./mining.log"
while true; do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 ccminer ---" | tee -a "\$LOG_FILE"
  ./ccminer -a verus -o stratum+tcp://verus.farm:9999 -u ${WALLET_ADDRESS}.${MINER_NAME} -p x -t ${THREADS} 2>&1 | tee -a "\$LOG_FILE"
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - ccminer 已停止，5秒後自動重啟 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF
    chmod +x start.sh
    ./start.sh

# 修正後的選項 4 邏輯
elif [ "$CHOICE" == "4" ]; then

    wget https://release-assets.githubusercontent.com/github-production-release-asset/105634072/2d9c7f00-6738-4729-8d06-5e0e911f36c2?sp=r&sv=2018-11-09&sr=b&spr=https&se=2026-01-05T17%3A08%3A55Z&rscd=attachment%3B+filename%3DxmrigCC-miner_only-3.4.9-android-dynamic-arm64.tar.gz&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2026-01-05T16%3A08%3A00Z&ske=2026-01-05T17%3A08%3A55Z&sks=b&skv=2018-11-09&sig=jrXizM9Qh6Lc84qyYbOb3vcU3CCK%2FU5ZQv2Kr34MRq8%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc2NzYzMDI1NCwibmJmIjoxNzY3NjI5OTU0LCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.Hn7_9b-20ve9fTmguawocfC6U9SNYJWh1DbL586FFKM&response-content-disposition=attachment%3B%20filename%3DxmrigCC-miner_only-3.4.9-android-dynamic-arm64.tar.gz&response-content-type=application%2Foctet-stream -y
    tar -xf * -y
    chmod +x xmrigMiner -y
    echo "Scash 安裝修復完成！"

# [修正後邏輯] 選項 5: Scash 監控腳本 (同步 Verus 的重啟邏輯)
elif [ "$CHOICE" == "5" ]; then
    echo "--- 正在生成 Scash 挖礦監控腳本... ---"
    read -p "請輸入 Scash 錢包地址： " S_WALLET
    read -p "礦工名稱 (預設: YH)： " S_NAME
    S_NAME=${S_NAME:-"YH"}
    read -p "核心數 (建議 6)： " S_THREADS
    S_THREADS=${S_THREADS:-"6"}

    # 生成 config.json (100% 原始 JSON 結構)
    cat > config.json << EOF
{
    "api": { "id": null, "worker-id": null },
    "http": { "enabled": false, "host": "127.0.0.1", "port": 0, "access-token": null, "restricted": true },
    "autosave": true, "background": false, "colors": true, "title": true,
    "randomx": { "init": -1, "init-avx2": -1, "mode": "auto", "1gb-pages": false, "rdmsr": true, "wrmsr": true, "cache_qos": false, "numa": true, "scratchpad_prefetch_mode": 1 },
    "cpu": {
        "enabled": true, "huge-pages": false, "huge-pages-jit": false, "hw-aes": null, "priority": null, "memory-pool": false, "yield": true, "force-autoconfig": false, "max-threads-hint": 100, "max-cpu-usage": null, "asm": true, "argon2-impl": null,
        "rx": $(seq -s, 0 $((S_THREADS-1)) | sed 's/^/[/;s/$/]/'),
        "cn/0": false, "cn-lite/0": false
    },
    "donate-level": 1, "donate-over-proxy": 1, "log-file": "miner.log",
    "pools": [
        { "algo": "rx/scash", "coin": null, "url": "pool.scash.pro:8888", "user": "${S_WALLET}.${S_NAME}", "pass": "x", "rig-id": null, "nicehash": false, "keepalive": true, "enabled": true, "tls": false, "tls-fingerprint": null, "daemon": false, "socks5": null, "self-select": null, "submit-to-origin": false }
    ],
    "cc-client": { "enabled": false, "servers": [ { "url": "localhost:3344", "access-token": "mySecret", "use-tls": false, "http-proxy": null, "socks-proxy": null } ], "use-remote-logging": true, "upload-config-on-start": true, "worker-id": null, "reboot-cmd": null, "update-interval-s": 10, "retries-to-failover": 5 },
    "print-time": 60, "health-print-time": 60, "dmi": true, "retries": 5, "retry-pause": 5, "syslog": false, "user-agent": null, "verbose": 0, "watch": true, "pause-on-battery": false, "pause-on-active": false
}
EOF

    # 建立 start_scash.sh 並同步 Verus 的重啟與日誌邏輯
    cat > start_scash.sh << EOF
#!/bin/bash
LOG_FILE="./scash_mining.log"
while true; do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 xmrigDaemon ---" | tee -a "\$LOG_FILE"
  ./xmrigDaemon -c config.json 2>&1 | tee -a "\$LOG_FILE"
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - xmrigDaemon 已停止，5秒後自動重啟 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF
    chmod +x start_scash.sh
    ./start_scash.sh

# [既有邏輯] 選項 6: 退出
elif [ "$CHOICE" == "6" ]; then
    echo "腳本已退出。"
    exit 0
else
    echo "無效選擇。"
fi
done
