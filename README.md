# Scripts
1、InstallNET.sh：用法：bash <(wget --no-check-certificate -qO- 'https://github.com/cgicsj/Scripts/raw/main/InstallNET.sh') -d 10 -v 64 -p "自定义root密码" -port "自定义ssh端口".  默认密码： MoeClub.org，甲骨文机器加 “-firmware  额外的驱动支持”

2、ss-caddy.sh：用法： wget --no-check-certificate -O ss-caddy.sh https://github.com/cgicsj/Scripts/raw/main/ss-caddy.sh && chmod a+x ss-caddy.sh   ，
需要手动配置服务器域名，自动证书邮箱，SS密码。默认采用CADDY自动申请证书。若需服务器使用IPV6，在config.json中增加"ipv6_first": true。采用Shadowsocks-libev + v2ray-plugin over websocket (HTTP) + TLS + caddy + CDN，客户端插件选项填 tls;host=mydomain.me;path=/ray


3、Vaultwarden_docker.sh：用法：  wget --no-check-certificate -O Vaultwarden_docker.sh https://github.com/cgicsj/Scripts/raw/main/Vaultwarden_docker.sh && bash chmod a+x  Vaultwarden_docker.sh  ,需手动配置域名，端口号，SSL证书。

4、申请SSL证书：
URL=xxx.xx.com ;
echo 'XX.XX.XX.XX  '$URL >> /etc/hosts ;
apt-get install -y socat ;
apt-get install -y curl ;
curl https://get.acme.sh | sh ;
/root/.acme.sh/acme.sh --register-account -m $URL;
/root/.acme.sh/acme.sh --issue -d $URL --standalone ;
/root/.acme.sh/acme.sh --installcert -d $URL --key-file /root/$URL.key --fullchain-file /root/$URL.cer ;



5、优化TCP
wget -O tools.sh "http://sh.nekoneko.cloud/tools.sh" && chmod +x tools.sh && ./tools.sh

6、流媒体解锁检测
bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)


7、三网回程路由检测
curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh|bash



8、一键WARP
wget -N --no-check-certificate https://cdn.jsdelivr.net/gh/kkkyg/CFwarp/CFwarp.sh && chmod +x CFwarp.sh


9、测速脚本
wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash
-------------------------------------------
wget -qO- bench.sh | bash
