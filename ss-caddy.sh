#设置域名，SSL证书邮箱，SS密码
URL=web.example.com
EMAIL=web@example.com
SSPASSWORD=Password

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
mkdir -p /root/compose/caddy
curl https://get.acme.sh | sh
/root/.acme.sh/acme.sh --issue -d $URL --standalone
/root/.acme.sh/acme.sh --installcert -d $URL --key-file /root/compose/caddy/$URL.key --fullchain-file /root/compose/caddy/$URL.cer

#设置caddy 和 shadowsocks-libev配置文件
cat >/root/compose/caddy/Caddyfile <<EOF 
$URL:12366 {
    tls /root/caddy/$URL.cer /root/caddy/$URL.key
    proxy / https://www.bing.com
    proxy /ray 127.0.0.1:9000 {
        websocket
        header_upstream -Origin
    }
}
EOF

cat >/root/compose/config.json <<EOF
{
    "server":"127.0.0.1",
    "server_port":9000,
    "password":"$SSPASSWORD",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open":false,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server;path=/ray"
}
EOF

#设置docker-compose配置文件
cat >/root/compose/docker-compose.yml <<EOF
version: "3"
services:
    caddy:
      image: cgicsj/caddy:latest
      container_name: caddy
      restart: always
      volumes:
         - /root/compose/caddy:/root/caddy
      network_mode: "host"

    shadowsocks:
      image: cgicsj/shadowsocks-libev:latest
      container_name: shadowsocks
      restart: always
      volumes:
        - /root/compose/config.json:/etc/shadowsocks-libev/config.json
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
