#!/bin/bash

# 清屏
clear

echo "Verus 挖礦設定工具"
echo "-----------------------------"

# 固定礦池位置
POOL_ADDRESS="stratum+tcp://ap.luckpool.net:3956"

# 提示使用者輸入錢包地址
read -p "請輸入你的 Verus 錢包地址: " WALLET_ADDRESS

# 檢查錢包地址是否為空
while [ -z "$WALLET_ADDRESS" ]; do
  echo "錢包地址不能為空，請重新輸入。"
  read -p "請輸入你的 Verus 錢包地址: " WALLET_ADDRESS
done

# 提示使用者輸入線程數
read -p "請輸入使用的線程數: " THREADS

# 檢查線程數是否為空
while [ -z "$THREADS" ]; do
  echo "線程數不能為空，請重新輸入。"
  read -p "請輸入使用的線程數: " THREADS
done

# 檢查線程數是否為數字
if ! [[ "$THREADS" =~ ^[0-9]+$ ]]; then
  echo "線程數格式不正確，請輸入數字。"
  exit 1 # 以錯誤碼退出
fi

# 生成 start.sh 檔案內容
START_SCRIPT_CONTENT="#!/bin/bash
./ccminer -a verus -o \"$POOL_ADDRESS\" -u \"$WALLET_ADDRESS\" -p x -t $THREADS
"

# 將內容寫入 start.sh 檔案 (在目前目錄)
echo "$START_SCRIPT_CONTENT" > start.sh

# 給予 start.sh 可執行權限 (在目前目錄)
chmod +x start.sh

echo "-----------------------------"
echo "start.sh 檔案已成功生成在目前目錄下 (./start.sh)。"
echo "你可以執行 ./start.sh 開始挖礦。"

# 詢問是否立即執行
read -p "是否立即執行挖礦腳本？ (y/n): " RUN_NOW

if [[ "$RUN_NOW" == "y" || "$RUN_NOW" == "Y" ]]; then
  ./start.sh
fi

echo "程式結束。"