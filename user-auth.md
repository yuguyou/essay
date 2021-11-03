## 添加用户
可以直接用 root 用户，但是毕竟不安全，有些软件不能直接用 root 
```
# 查看所有组
$ cat /etc/group
# 产看用户/组的id号
$ id
# wheel组用户才能通过su命令切换到root用户
$ useradd -m -g users -G wheel -s /bin/bash vk
# 设置用户密码
$ passwd vk
```
8. 安装 sudo
 要使用 sudo 命令提权的话需要安装 sudo 并且做相应配置
```
pacman -S sudo
#找到 root ALL=(ALL) ALL 并依葫芦画瓢添加 vk ALL=(ALL) ALL 即可。因为/etc/sudoers是只读文件，保存修改时需要":w!"强制写入
vi /etc/sudoers
```
#### 例：非root使用docker
```
# 查看所有组
$ cat /etc/group
创建docker用户组
$ groupadd docker
将当前用户加入组docker
$ gpasswd -a ${USER} docker
将当前用户移出组docker
$ gpasswd -d ${USER} docker
# usermod -G命令将用户加入到新的群组后会将之前加入的群组清空
# $ sudo usermod -G docker ${USER} 
重启docker服务(生产环境请慎用)：
$ sudo systemctl restart docker
# 服务器普通用户不允许使用sudo
```

