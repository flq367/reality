#!/bin/bash

# Initial Installation Dependencies
install_dependencies() {
    packages="gawk curl openssl"
    install=""

    for pkg in $packages; do
        if ! command -v $pkg &>/dev/null; then
            install="$install $pkg"
        fi
    done

    if [ -z "$install" ]; then
        echo -e "\e[1;32mAll packages are already installed\e[0m"
        return
    fi

    if command -v apt &>/dev/null; then
        pm="apt-get install -y -q"
    elif command -v dnf &>/dev/null; then
        pm="dnf install -y"
    elif command -v yum &>/dev/null; then
        pm="yum install -y"
    elif command -v apk &>/dev/null; then
        pm="apk add"
    else
        echo -e "\e[1;33m暂不支持的系统!\e[0m"
        exit 1
    fi
    $pm $install
}
install_dependencies

# Define Environment Variables
export PORT=${PORT:-$(shuf -i 2000-65000 -n 1)}
export FILE_PATH=${FILE_PATH:-'./app'}
export SNI=${SNI:-'www.yahoo.com'}
export UUID=$(openssl rand -hex 16 | awk '{print substr($0,1,8)"-"substr($0,9,4)"-"substr($0,13,4)"-"substr($0,17,4)"-"substr($0,21,12)}')

echo -e "\e[1;32mInstallation is in progress, please wait...\e[0m"

# Download Dependency Files
DOWNLOAD_DIR="${FILE_PATH}" && mkdir -p "$DOWNLOAD_DIR"
URL="https://github.com/eooce/test/releases/download/xray"  # 假设 URL 是固定的
NEW_FILENAME="web"
FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"

# Download the file if it doesn't exist
if [ -e "$FILENAME" ]; then
    echo -e "\e[1;32m$FILENAME already exists, skipping download\e[0m"
else
    echo -e "\e[1;32mDownloading $FILENAME\e[0m"
    curl -L -sS -o "$FILENAME" "$URL"
    
    # Check if the downloaded file is a valid binary
    if ! file "$FILENAME" | grep -q "executable"; then
        echo -e "\e[1;31mError: Downloaded file is not a valid executable. Please check the URL.\e[0m"
        rm -f "$FILENAME"  # Remove invalid file
        exit 1
    fi
fi

# Make the file executable
chmod +x "$FILENAME"

# Generating Configuration Files
generate_config() {
    X25519Key=$(./"${FILE_PATH}/web" x25519)
    PrivateKey=$(echo "${X25519Key}" | head -1 | awk '{print $3}')
    PublicKey=$(echo "${X25519Key}" | tail -n 1 | awk '{print $3}')
    shortid=$(openssl rand -hex 8)

    cat > ${FILE_PATH}/config.json << EOF
{
    "inbounds": [
        {
            "port": $PORT,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "1.1.1.1:443",
                    "xver": 0,
                    "serverNames": [
                        "$SNI"
                    ],
                    "privateKey": "$PrivateKey",
                    "minClientVer": "",
                    "maxClientVer": "",
                    "maxTimeDiff": 0,
                    "shortIds": [
                        "$shortid"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        }
    ]    
}
EOF
}
generate_config

# Running files
run() {
  if [ -e "${FILE_PATH}/web" ]; then
    # Check if the file is executable
    if ! file "${FILE_PATH}/web" | grep -q "executable"; then
        echo -e "\e[1;31mError: ${FILE_PATH}/web is not a valid executable file.\e[0m"
        exit 1
    fi

    # Run the file
    nohup "${FILE_PATH}/web" -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
    sleep 1

    # Check if the process is running
    if ps aux | grep -q "[w]eb"; then
        echo -e "\e[1;32mweb is running\e[0m"
    else
        echo -e "\e[1;35mweb is not running, restarting...\e[0m"
        pkill -x "web" 2>/dev/null
        nohup "${FILE_PATH}/web" -c ${FILE_PATH}/config.json >/dev/null 2>&1 &
        sleep 2
        if ps aux | grep -q "[w]eb"; then
            echo -e "\e[1;32mweb restarted\e[0m"
        else
            echo -e "\e[1;31mError: Failed to start web. Please check the file and configuration.\e[0m"
            exit 1
        fi
    fi
  else
    echo -e "\e[1;31mError: ${FILE_PATH}/web does not exist.\e[0m"
    exit 1
  fi
}
run

# Get IP and ISP information
IP=$(curl -s ipv4.ip.sb)
ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')

# Save connection information
cat > ${FILE_PATH}/list.txt <<EOF
vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PublicKey}&sid=${shortid}&type=tcp&headerType=none#$ISP
EOF

cat ${FILE_PATH}/list.txt
echo -e "\n\e[1;32m${FILE_PATH}/list.txt saved successfully\e[0m"
echo ""
echo -e "\n\e[1;32mInstall success!\e[0m"

exit 0
