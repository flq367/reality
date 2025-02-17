#!/bin/bash

# 颜色定义
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
skyblue="\033[36m"
re="\033[0m"

# 端口检测函数
check_port() {
    while netstat -tuln | grep -w tcp | awk '{print $4}' | sed 's/.*://g' | grep -w "$1" &>/dev/null; do
        echo -e "${red}端口 $1 已被占用，请输入新的端口:${re}"
        read -p "新的 Reality 端口 [1-65535]: " new_port
        [ -z "$new_port" ] && new_port=$(shuf -i 2000-65000 -n 1)
        set -- "$new_port"
    done
    echo "$1"
}

# 安装 Reality
install_reality() {
    clear
    echo -e "${green}开始安装 Reality...${re}"
    
    # 提示用户输入 Reality 端口
    read -p "请输入Reality端口 (留空则随机生成): " port
    [ -z "$port" ] && port=$(shuf -i 2000-65000 -n 1)
    port=$(check_port "$port")

    # 提示用户输入伪装访问网站
    read -p "请输入伪装访问网站 (留空则使用默认值 www.apple.com): " sni
    [ -z "$sni" ] && sni="www.apple.com"

    if [ -f "/etc/alpine-release" ]; then
        PORT=$port SNI=$sni bash -c "$(curl -L https://raw.githubusercontent.com/flq367/reality/main/reality.sh)"
    else
        PORT=$port SNI=$sni bash -c "$(curl -L https://raw.githubusercontent.com/flq367/reality/main/reality.sh)"
    fi

    echo -e "${green}Reality 安装完成，监听端口: $port, 伪装网站: $sni${re}"
}

# 卸载 Reality
uninstall_reality() {
    echo -e "${red}正在卸载 Reality...${re}"
    if [ -f "/etc/alpine-release" ]; then
        pkill -f '[w]eb'
        pkill -f '[n]pm'
        cd && rm -rf app
    else
        sudo systemctl stop xray
        sudo rm -rf /usr/local/bin/xray /usr/local/etc/xray /var/log/xray /var/lib/xray
        sudo systemctl daemon-reload
    fi
    echo -e "${green}Reality 已卸载！${re}"
}

# 修改 Reality 端口
change_port() {
    clear
    echo -e "${yellow}修改 Reality 端口...${re}"
    read -p "请输入新的 Reality 端口 (留空则随机生成): " new_port
    [ -z "$new_port" ] && new_port=$(shuf -i 2000-65000 -n 1)
    new_port=$(check_port "$new_port")

    if ! command -v jq &>/dev/null; then
        echo -e "${yellow}正在安装 jq 依赖...${re}"
        sudo apt update && sudo apt install -y jq
    fi

    if [ -f "/etc/alpine-release" ]; then
        jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /root/app/config.json > tmp.json && mv tmp.json /root/app/config.json
        pkill -f '[w]eb'
        cd ~/app && nohup ./web -c config.json >/dev/null 2>&1 &
    else
        jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
        systemctl restart xray.service
    fi
    echo -e "${green}Reality 端口已更换为: $new_port，请手动更新客户端配置！${re}"
}

# 菜单
echo -e "${skyblue}Reality 管理脚本${re}"
echo "----------------------"
echo -e "${green}1. 安装 Reality${re}"
echo -e "${red}2. 卸载 Reality${re}"
echo -e "${yellow}3. 修改 Reality 端口${re}"
echo "----------------------"
read -p "请输入你的选择: " choice

case "$choice" in
    1) install_reality ;;
    2) uninstall_reality ;;
    3) change_port ;;
    *) echo -e "${red}无效输入！${re}" ;;
esac
