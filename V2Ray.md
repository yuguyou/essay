# v2ray
## 一、v2ray docker安装启动服务端
`https://www.iszy.cc/2019/02/18/docker-v2ray/`
```
# 安装docker
wget -qO- https://get.docker.com/ | sudo sh
# docker-compose 安装
sudo curl -L https://github.com/docker/compose/releases/download/1.23.2/run.sh > /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
docker-compose.yml配置
```
version: "3"
services:
  v2ray:
    image: v2ray/official
    container_name: v2ray
    restart: always
    command: v2ray -config=/etc/v2ray/config.json
    ports:
      # 容器中端口号要与/etc/v2ray/config.json中端口号一致
      #- "127.0.0.1:17794:17794"
      #- "17794:17794"
      - "容器外端口号:容器中端口号"
    volumes:
      - ./v2ray:/etc/v2ray
```
docker-compose相关命令
```
部署 v2ray: docker-compose up -d
启动 v2ray: docker-compose start v2ray
停止 v2ray: docker-compose stop v2ray
重启 v2ray: docker-compose restart v2ray
删除 v2ray: docker stop v2ray && docker rm v2ray
更新 v2ray: docker-compose pull && docker-compose up -d
```
修改防火墙放行监听的端口号

### config.json配置
```
{
  "inbounds": [{
    "port": 17794,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "UUID",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
```
## 二、websocket+tls+web流量伪装
将穿墙流量用常见的https/tls方式包装，大大降低vps被block的几率，在敏感时期保持稳健的外网访问通道
> WebSocket+TLS+Web 实际上就是反代 v2ray 的 WebSocket 端口并套上 https，再将访问地址改为域名，反代的路径要与 wsSettings 中的 path 保持一致，使用 Nginx进行反代，若再配置上CDN即可隐藏IP防止被墙，拯救被墙IP的VPN。
参考： `https://tlanyan.me/v2ray-traffic-mask/`
### 服务端
##### 准备
1. 一个域名(非必须,无域名可直接用IP走https)，无备案要求： 免费域名申请`https://my.freenom.com/`，可能会被回收（备案了流量来往更顺畅，但意味着万一有事，被喝茶更容易了）
2. 为域名申请证书，可以用免费的Let’s Encrypt证书

##### 1. 申请域名
##### 2. 证书安装
```
# 为域名获取证书
$ yum install -y python36 && pip3 install certbot
# 停止域名指向的服务器的80与443端口的服务后执行命令
$ certbot certonly --standalone -d tlanyan.me -d www.tlanyan.me
# 命令可查看获取到所有申请的证书及所在目录
$ certbot certificates
```

* 证书更新: `certbot certificates`命令可以看到证书的有效期是三个月，超过期限则需要续签。证书续期可以手动完成
```
systemctl stop nginx
certbot renew
systemctl restart nginx
```
* 自动续期证书: 配置crontab任务，在/etc/crontab文件末添加一行，证书将每两个月自动续签一次
```
0 0 0 */2 0 root systemctl stop nginx; /usr/bin/certbot renew; systemctl restart nginx
```

##### 3. config.json配置
```
{
  "inbounds": [{
    "port": 17794,
    "protocol": "vmess",
    "settings": {
      "clients": [{
          "id": "UUID",
          "level": 1,
          "alterId": 64
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/ws"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
    "protocol": "blackhole",
    "settings": {},
    "tag": "blocked"
  }],
   "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": ["telegram-in"],
        "outboundTag": "telegram-out"
      }
    ],
    "balancers": []
  }
}
```

##### 4. nginx配置
配置分为两个server段，第一段是所有http请求都导向https；第二段以ssl开头的配置都和证书相关：设置证书和私钥的位置、证书采用的协议、证书的加密算法等信息。
为了增强安全性，`ssl_protocols`、`ssl_ciphers`和`ssl_perfer_server_ciphers`的配置建议采用以上配置。
配置好以后，运行`nginx -t`命令查看有无错误。如果没有可运行`systemctl restart nginx`重新开启web服务。
```
server {
    listen 80;
    server_name djdj.xiaochongfei.tk;
    rewrite ^(.*) https://$server_name$1 permanent;
}


server {
    listen 443 ssl;
    server_name djdj.xiaochongfei.tk;
    charset utf-8;

    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    # ssl_protocols TLSv1.2 TLSv1.3; # TLSv1.3需要nginx 1.13.0以上版本
    # ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_certificate /etc/letsencrypt/live/djdj.xiaochongfei.tk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/djdj.xiaochongfei.tk/privkey.pem;
    ssl_ecdh_curve secp384r1;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    keepalive_timeout 70;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # 这里填写其他配置
    access_log  /var/log/nginx/vpn.access.log;
    error_log /var/log/nginx/vpn.error.log;
    root /usr/share/nginx/html;

    location / {
        index  index.html;
    }

    location /djdj { # 与 V2Ray 配置中的 path 保持一致
      proxy_redirect off;
      proxy_pass http://127.0.0.1:17794;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
```

### 三、 linux客户端配置
docker-compose.yml
```
version: '3.2'
services:
  v2ray:
    image: v2ray/official
    container_name: v2ray
    restart: always
    command: v2ray -config=/etc/v2ray/config.json
    ports:
      - "1080:1080"
    volumes:
      - ./v2ray:/etc/v2ray
```

config.json
```
{
  "inbounds": [{
    "port": 1080,
    "protocol": "socks",
    "domainOverride": ["tls","http"],
    "settings": {
      "auth": "noauth"
    }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "域名或IP",
        "port": 443,
        "users": [{
          "id": "UUID",
          "alterId": 64
        }]
      }]
    },
    "streamSettings":{
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "域名或IP"
        },
        "wsSettings": {
            "path": "/ws"
        }
    }
  },{
    "protocol": "freedom",
    "tag": "direct",
    "settings": {}
  }],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "direct"
    }]
  }
}
```
## 其它
### 时间同步
使用v2ray必须保证服务端与客户端时间同步
```
一、安装NTP服务
yum install ntp ntpdate -y
二、修改配置文件，将server开头的#注释掉，并添加如下NTP服务器，并且启动服务
vi /etc/ntp.conf
server ntp.cloudcone.com
三、同步时间并设置同步
ntpdate -u ntp.cloudcone.com
timedatectl set-ntp yes
systemctl start ntpd
systemctl enable ntpd

将硬件时间设置一致
hwclock --systohc --localtime
timedatectl set-local-rtc 1
clock -w
```

### 安装相关
```
# 配置文件
$ cat /etc/v2ray/config.json
inbounds.port  服务端口号
inbounds.clients.id 用户ID
inbounds.alterId 额外id

# 修改防火墙放行监听的端口号
# firewalld放行端口(CentOS7/8）
开启防火墙: systemctl start firewalld
查看状态： systemctl status firewalld
开机禁用： systemctl disable firewalld
开机启用： systemctl enable firewalld

# 17794改成你配置文件中的端口号
firewall-cmd --permanent --add-port=17794/tcp
# 删除
firewall-cmd --zone= public --remove-port=80/tcp --permanent
firewall-cmd --reload
# 查看所有
firewall-cmd --list-ports
# iptables
iptables -I INPUT -p tcp --dport 17794 -j ACCEPT

# ss -ntlp | grep v2ray 命令可以查看v2ray是否正在运行。如果输出为空，大概率是被selinux限制了，解决办法如下：

# 在另一台机器上查看端口是否正常开启
$ nmap 173.82.153.190 -Pn
```

#### UUID 生成
https://www.uuidgenerator.net/version4


### 配置示例
* https://www.iszy.cc/2019/02/18/v2ray-config/
#### Shadowsocks
```
{
  "inbounds": [
    {
      "port": 6666,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "12345678",
        "ota": false,
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```

### 安装BBR加速网络
```
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```
