
        while true; do
        clear
          echo "--------------"
          echo -e "${green}1.安装Reality${re}"
          echo -e "${red}2.卸载Reality${re}"
          echo -e "${yellow}3.更换Reality端口${re}"          
          echo "--------------"
          echo -e "${skyblue}0. 返回上一级菜单${re}"
          echo "--------------"
          read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            case $sub_choice in
                1)
                  clear
                    read -p $'\033[1;35m请输入reality节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：\033[0m' port
                    [[ -z $port ]]
                    until [[ -z $(netstat -tuln | grep -w tcp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; do
                        if [[ -n $(netstat -tuln | grep -w tcp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; then
                            echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                            read -p $'\033[1;35m设置 reality 端口[1-65535]（回车跳过将使用随机端口）：\033[0m' port
                            [[ -z $PORT ]] && port=$(shuf -i 2000-65000 -n 1)
                        fi
                    done
                    if [ -f "/etc/alpine-release" ]; then
                        PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/test.sh)"
                    else
                        PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/reality.sh)"
                    fi
                    sleep 1
                    break_end
                    ;;
                2)
                if [ -f "/etc/alpine-release" ]; then
                    pkill -f '[w]eb'
                    pkill -f '[n]pm'
                    cd && rm -rf app
                    clear
                else
                    sudo systemctl stop xray
                    sudo rm /usr/local/bin/xray
                    sudo rm /etc/systemd/system/xray.service
                    sudo rm /usr/local/etc/xray/config.json
                    sudo rm /usr/local/share/xray/geoip.dat
                    sudo rm /usr/local/share/xray/geosite.dat
                    sudo rm /etc/systemd/system/xray@.service

                    # Reload the systemd daemon
                    sudo systemctl daemon-reload

                    # Remove any leftover Xray files or directories
                    sudo rm -rf /var/log/xray /var/lib/xray
                    clear
                  fi

                    echo -e "\e[1;32mReality已卸载\033[0m"
                    break_end
                    ;;
                3)
                    clear
                        read -p $'\033[1;35m设置 reality 端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                        [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                        until [[ -z $(netstat -tuln | grep -w tcp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; do
                            if [[ -n $(netstat -tuln | grep -w tcp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; then
                                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p $'\033[1;35m设置reality端口[1-65535]（回车跳过将使用随机端口）：\033[0m' new_port
                                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        install jq 
                        if [ -f "/etc/alpine-release" ]; then
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /root/app/config.json > tmp.json && mv tmp.json /root/app/config.json
                            pkill -f '[w]eb'
                            cd ~ && cd app
                            nohup ./web -c config.json >/dev/null 2>&1 &
                        else
                            clear
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                            systemctl restart xray.service
                        fi
                        echo -e "${green}Reality端口已更换成$new_port,请手动更改客户端配置!${re}"
                        sleep 1   
                        break_end
                    ;;
                0)
                    break

                    ;;
                *)
                    echo -e "${red}无效的输入!${re}"
                    ;;
            esac  
        done
        ;;
