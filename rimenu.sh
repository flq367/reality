#!/bin/bash

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

while true; do
    clear
    echo "================================"
    echo "        Reality 管理脚本        "
    echo "================================"
    echo "1. 安装 Reality"
    echo "2. 卸载 Reality"
    echo "3. 修改 Reality 端口"
    echo "4. 查看 Reality 链接"
    echo "0. 退出"
    echo "================================"
    
    read -p "请输入选项 [0-4]: " choice

    case $choice in
        1)
            clear
            echo -e "${green}开始安装 Reality...${re}"
            
            read -p "请输入Reality端口 (留空则随机生成): " port
            [ -z "$port" ] && port=$(shuf -i 2000-65000 -n 1)
            port=$(check_port "$port")

            read -p "请输入伪装访问网站 (留空则使用默认值 www.apple.com): " sni
            [ -z "$sni" ] && sni="www.apple.com"

            if [ -f "/etc/alpine-release" ]; then
                PORT=$port SNI=$sni bash -c "$(curl -L https://raw.githubusercontent.com/flq367/reality/main/reality-alpine.sh)"
            else
                PORT=$port SNI=$sni bash -c "$(curl -L https://raw.githubusercontent.com/flq367/reality/main/reality.sh)"
            fi

            echo -e "${green}Reality 安装完成，监听端口: $port, 伪装网站: $sni${re}"
            read -p "按回车键继续..."
            ;;
            
        2)
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
            read -p "按回车键继续..."
            ;;
            
        3)
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
            read -p "按回车键继续..."
            ;;
            
        4)
            clear
            echo -e "${skyblue}正在查看 Reality 链接...${re}"
            config_file="/usr/local/etc/xray/config.json"

            if [ -f "/etc/alpine-release" ]; then
                if [ -f "/root/app/list.txt" ]; then
                    echo -e "${green}以下是 Reality 链接:${re}"
                    cat /root/app/list.txt
                else
                    echo -e "${red}未找到 Reality 链接文件，请确保 Reality 已正确安装！${re}"
                fi
            else
                if [ -f "$config_file" ]; then
                    ip=$(curl -s ipv4.ip.sb)
                    port=$(jq -r '.inbounds[0].port' $config_file)
                    uuid=$(jq -r '.inbounds[0].settings.clients[0].id' $config_file)
                    sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' $config_file)
                    public_key=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey' $config_file)
                    sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' $config_file)
                    isp=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

                    if [ "$public_key" == "null" ] || [ -z "$public_key" ]; then
                        echo -e "${red}未能正确解析 publicKey，请检查配置文件！${re}"
                    else
                        echo -e "${green}以下是 Reality 链接:${re}"
                        echo -e "vless://${uuid}@${ip}:${port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${sni}&fp=chrome&pbk=${public_key}&sid=${sid}&type=tcp&headerType=none#$isp"
                    fi
                else
                    echo -e "${red}未找到 Reality 配置文件，请确保 Reality 已正确安装！${re}"
                fi
            fi
            read -p "按回车键继续..."
            ;;
            
        0)
            echo "退出程序..."
            exit 0
            ;;
            
        *)
            echo -e "${red}无效选项，请重新选择${re}"
            read -p "按回车键继续..."
            ;;
    esac
done
