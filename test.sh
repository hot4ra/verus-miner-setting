#!/bin/bash

# 清屏
clear

echo "歡迎使用名字設定工具"
echo "-----------------------------"

# 提示使用者輸入英文名字
read -p "請輸入你的英文名字: " USER_NAME

# 生成 start.sh 檔案內容
START_SCRIPT_CONTENT="#!/bin/bash
echo \"你的名字是: $USER_NAME\"
"

# 將內容寫入 start.sh 檔案 (在目前目錄)
echo "$START_SCRIPT_CONTENT" > start.sh

# 給予 start.sh 可執行權限 (在目前目錄)
chmod +x start.sh

echo "-----------------------------"
echo "start.sh 檔案已成功生成在目前目錄下 (./start.sh)。"
echo "你可以執行 ./start.sh 查看你的名字。"

echo "程式結束。"
