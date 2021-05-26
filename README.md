# Scripts
1、AutoReinstall.sh：用法：wget --no-check-certificate -O AutoReinstall.sh https://github.com/cgicsj/Scripts/raw/main/AutoReinstall.sh && bash AutoReinstall.sh ，Centos 7 默认密码是 Pwd@CentOS，其他系统密码是 Pwd@Linux

2、ss-caddy.sh：用法： wget --no-check-certificate -O ss-caddy.sh https://github.com/cgicsj/Scripts/raw/main/ss-caddy.sh && chmod a+x ss-caddy.sh   ，
需要手动配置服务器域名，自动证书邮箱，SS密码。默认采用CADDY自动申请证书。


3、Vaultwarden_docker.sh：用法：  wget --no-check-certificate -O Vaultwarden_docker.sh https://github.com/cgicsj/Scripts/raw/main/Vaultwarden_docker.sh && bash chmod a+x  Vaultwarden_docker.sh  ,需手动配置域名，端口号，SSL证书。

4、申请SSL证书：
apt-get install -y socat
apt-get install -y curl
curl https://get.acme.sh | sh
/root/.acme.sh/acme.sh --issue -d $URL --standalone
/root/.acme.sh/acme.sh --installcert -d $URL --key-file /root/$URL.key --fullchain-file /root/$URL.cer
