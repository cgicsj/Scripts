#设置域名，SSL证书邮箱，SS密码
URL=ny.bestss.xyz
EMAIL=ny@bestss.xyz
SSPASSWORD=helloworld123

#开启bbr
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

#下载docker环境
apt install -y curl
curl -sSL https://get.docker.com/ | sh

#安装docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

#设置caddy 和 shadowsocks-libev配置文件
mkdir -p /root/compose/caddy /root/compose/shadowsocks-libev

cat >/root/compose/caddy/mycaddyfile <<EOF 
$URL:443 {
    tls $EMAIL
    proxy / https://www.bing.com
    proxy /ray 127.0.0.1:9000 {
        websocket
        header_upstream -Origin
    }
}
EOF

cat >/root/compose/shadowsocks-libev/config.json <<EOF
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
         - /root/compose/mycaddyfile:/root/caddy/Caddyfile
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
