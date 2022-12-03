#!/bin/bash
#设置域名，SSL证书邮箱，Trojan-go密码，代理端口等
URL=web.example.com
EMAIL=web@example.com
TROJAN_PASSWORD=Password
PORT=8443
REMOTE_PORT=443
WSSTATUS=true  #ws is true,tcp is false
WSPATH=videos
REMARKS=trojan-us

#开启bbr
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

#下载docker环境
apt-get install -y curl
apt-get install -y socat
curl -sSL https://get.docker.com/ | sh

#安装docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#获取证书
mkdir -p /root/compose/trojan-go
mkdir -p /root/compose/caddy
curl https://get.acme.sh | sh
/root/.acme.sh/acme.sh --set-default-ca  --server letsencrypt --issue -d $URL --standalone
/root/.acme.sh/acme.sh --installcert -d $URL --key-file /root/compose/trojan-go/$URL.key --fullchain-file /root/compose/trojan-go/$URL.cer
/root/.acme.sh/acme.sh --installcert -d $URL --key-file /root/compose/caddy/$URL.key --fullchain-file /root/compose/caddy/$URL.cer

#设置caddy,index.html 和 trojan-go配置文件

cat >/root/compose/caddy/Caddyfile <<EOF
:$REMOTE_PORT {
    log /etc/caddy/caddy.log
    root /etc/caddy
    tls /etc/caddy/$URL.cer /etc/caddy/$URL.key
    index index.html
    proxy / https://www.bing.com
    proxy /$WSPATH https://www.bing.com
}
EOF

cat >/root/compose/caddy/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
        }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF

cat >/root/compose/trojan-go/config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": $PORT,
    "remote_addr": "127.0.0.1",
    "remote_port": $REMOTE_PORT,
    "password": [
        "$TROJAN_PASSWORD"
    ],
    "ssl": {
        "cert": "/etc/trojan-go/$URL.cer",
        "key": "/etc/trojan-go/$URL.key",
        "sni": "$URL",
        "fallback_addr": "127.0.0.1",
        "fallback_port": $REMOTE_PORT 
    },
    "websocket": {
        "enabled": $WSSTATUS,
        "path": "/$WSPATH",
        "host": "$URL"
    }
}
EOF

#设置docker-compose配置文件
cat >/root/compose/docker-compose.yml <<EOF
version: "3"
services:
    caddy:
        image: teddysun/caddy:latest
        container_name: caddy
        restart: always
        volumes:
            - /root/compose/caddy:/etc/caddy
        network_mode: "host"
    trojan-go:
        image: teddysun/trojan-go:latest
        container_name: trojan-go
        restart: always
        volumes:
            - /root/compose/trojan-go:/etc/trojan-go
        network_mode: "host"
EOF

#启动docker
docker-compose -f /root/compose/docker-compose.yml up -d

#开机自动启动
cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
# bash /root/bindip.sh
docker-compose -f /root/compose/docker-compose.yml up -d
exit 0
EOF

chmod +x /etc/rc.local 
systemctl enable rc-local 
systemctl start rc-local.service

echo "trojan-go链接为："
if [ $WSSTATUS = "true" ]; then
    echo "trojan://$TROJAN_PASSWORD@$URL:$PORT?security=tls&sni=$URL&type=ws&host=$URL&path=%2F$WSPATH#$REMARKS"
else
    echo "trojan://$TROJAN_PASSWORD@$URL:$PORT?security=tls&sni=$URL&type=tcp&host=$URL#$REMARKS"
fi

echo ""
