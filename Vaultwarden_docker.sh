#设置域名，端口号，SSL证书
URL=web.example.com
PORT=12345
CERTFULLNAME=/root/ssl/example.crt
KEYFULLNAME=/root/ssl/example.key

#创建目录
mkdir -p /root/bitwarden/nginx
mkdir -p /root/bitwarden/bw-data

CERTNAME=${CERTFULLNAME##*/}
KEYNAME=${KEYFULLNAME##*/}

mv $CERTFULLNAME /root/bitwarden/nginx
mv $KEYFULLNAME /root/bitwarden/nginx

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


#设置nginx配置文件
cat >/root/bitwarden/nginx/nginx.conf <<EOF 
upstream vaultwarden-default { server bitwarden:80; }
upstream vaultwarden-ws { server bitwarden:3012; }

server {
    listen $PORT ssl http2;
    server_name $URL;
    ssl_certificate /usr/share/nginx/html/$CERTNAME;
    ssl_certificate_key /usr/share/nginx/html/$KEYNAME;
    client_max_body_size 128M;
    location / {
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_pass http://vaultwarden-default;
    }
    location /notifications/hub/negotiate {
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_pass http://vaultwarden-default;
    }
    location /notifications/hub {
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $http_connection;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_pass http://vaultwarden-ws;
    }
}

EOF

#设置docker-compose配置文件
cat >/root/bitwarden/docker-compose.yml <<EOF
version: "3"

services:
  mybitwarden:
    image: vaultwarden/server 
    container_name: bitwarden
    restart: always
    volumes:
      - /root/bitwarden/bw-data:/data
    environment:
      WEBSOCKET_ENABLED: "true" 
      SIGNUPS_ALLOWED: "true" 
      WEB_VAULT_ENABLED: "true"
    networks:
      - bitwarden_net

  mynginx:
     image: nginx
     container_name: nginx
     restart: always
     depends_on:
       - mybitwarden
     ports: 
       - $PORT:$PORT
     networks:
       - bitwarden_net
     volumes:
       - /root/bitwarden/nginx/nginx.conf:/etc/nginx/conf.d/default.conf 
       - /root/bitwarden/nginx:/usr/share/nginx/html
       - /root/bitwarden/nginx:/var/log/nginx 

networks:
  bitwarden_net:
    driver: bridge

EOF

#启动docker
docker-compose -f /root/bitwarden/docker-compose.yml up -d

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
docker-compose -f /root/bitwarden/docker-compose.yml up -d
exit 0
EOF

chmod +x /etc/rc.local 
systemctl enable rc-local 
systemctl start rc-local.service
