# arch 基本环境配置
```
pacman -Syy   同步软件包数据库
pacman -Sy    仅同步源
pacman -Syu   同步源，并更新系统
pacman -Sc    清理/var/cache/pacman/pkg目录下的旧包
pacman -Scc   清除所有下载的包和数据库
```
### 一. 联网
安装NetworkManager 以及 图形化前端来实现便捷的无线网络管理 ：  
```
$ ip link
$ ip link set eth0 up
$ dhcpcd
有线连接：
$ systemctl enable dhcpcd
$ pacman -S networkmanager nm-connection-editor network-manager-applet hidapi
$ systemctl enable NetworkManager
$ systemctl start NetworkManager
```

### 二. 显卡驱动
执行如下命令查询显卡类型：
```
$ lspci | grep -e VGA -e 3D
```
安装对应的驱动，输入下面命令，查看所有开源驱动:
```
$ pacman -Ss xf86-video
```

### 三. 安装图形界面
安装Xwindow 图形界面的基础 。 Xorg是 X窗口系统提供基本的图形用户界面支持。使用桌面环境之前，必须首先安装X服务器。Xorg是这套系统的开源实现。 提供基本图形用户界面框架 ， X使用了类似服务器客户端的形式，后台运行X服务器，打开终端即打开终端客户端，打开浏览器即打开浏览器客户端 ，xorg-server是x window的实现，是用于显示图形界面。 如果想从xinit启动i3，那么就装上xorg-xinit，如果你想通过显示管理器启动则不用装xorg-xinit，且启动配置文件为.xprofile。
```
pacman -S xorg xorg-server vim
```
* 使用xinit启动图形界面
```
pacman -S xorg-xinit
cp /etc/X11/xinit/xinitrc ~/.xinitrc  
vim .xinitrc
# -----------------
在最前面加上下面三行：
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:en_US
export LC_CTYPE=en_US.UTF-8
# -----------------
```
* 使用显示管理器(登录管理器)： 
```
pacman -S lightdm  lightdm-gtk-greeter   lightdm-gtk-greeter-settings
sudo systemctl enable lightdm
```
vim /etc/lightdm/lightdm.conf
```
[Seat:*]
...
greeter-session=lightdm-gtk-greeter
greeter-hide-users=true
allow-guest=false
```
编辑.xprofile，功能同xinit的.xinitrc
```
在最前面加上下面三行：
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:en_US
export LC_CTYPE=en_US.UTF-8
```

### 四. 安装i3
```
$ pacman -S i3 i3-wm i3status i3lock conky dmenu
```
编辑 .xinitrc
```
cp /etc/X11/xinit/xinitrc ~/.xinitrc
```
加入 
```
xxxxxxxxxx &
exec i3 -V >> ~/i3log-$(date +'%F-%k-%M-%S') 2>&1&
```
运行i3wm
```
$ startx
```

### 五. 安装终端：
```
sudo pacman -S xfce4-terminal [功能多但轻量易配]专为Xfce桌面环境而设计的轻量级现代、易用的终端,支持透明搜索等
# sudo pacman -S rxvt-unicode  超轻量级终端，文件配置
# sudo pacman -S lxterminal 轻量级终端，支持界面配置不支持透明
```

### 六. 安装yaourt
添加yaourt源(Arch Linux 中文社区仓库)
```
# vim /etc/pacman.conf
# --------------------------
# [archlinuxcn]
# SigLevel = Optional TrustAll
# Server = http://mirrors.163.com/archlinux-cn/$arch
# --------------------------
# 更新源并安装yaourt
pacman -Syy
pacman -S yaourt
```
安装xfce4套件
```
# 系统设置
sudo pacman -S xfce4-settings
# 电源
sudo pacman -S xfce4-power-manager xfce4-goodies
# 文件浏览
sudo pacman -S thunar tumbler thunar-volman
```

### 七. 安装常用软件
```
sudo pacman -S wget curl git zsh unrar unzip google-chrome  file-roller
# 显示器及分辨率管理 
arandr
# 安装网易云音乐
netease-cloud-music
# 声音软件
pulseaudio pasystray paman paprefs pavucontrol pavumeter
# pdf
okular 
# email
thunderbird
# file manager
thunar
# markdown
typora
# 图形化文本编辑器
leafpad
# 微信
https://github.com/geeeeeeeeek/electronic-wechat
```

### 八. 蓝牙
```
sudo pacman -S bluez bluez-utils bluez-hid2hci blueberry pulseaudio-bluetooth bluez-tools
sudo systemctl enable bluetooth
添加用户到lp组
sudo gpasswd -a vk lp
vim /etc/bluetooth/main.conf
# [Policy]
# AutoEnable=true
# 蓝牙图形管理
sudo pacman -S blueberry
```

### 九. 安装字体
```
pacman -S wqy-microhei noto-fonts noto-fonts-cjk wqy-zenhei
pacman -S adobe-source-code-pro-fonts    // adobe出品的一款很适合编程的等宽字体
pacman -S adobe-source-han-sans-cn-fonts  // 思源黑体
pacman -S ttf-dejavu    //没有此字体，会使某些符号不够漂亮，建议在安装桌面环境时选择此字体作为桌面环境的默认依赖字体
```

### 十. 安装输入法、搜狗拼音、图形化配置等工具
```
pacman -S fcitx-im fcitx-configtool fcitx-sogoupinyin
```
配置fcitx
```
cp /etc/xdg/autostart/fcitx-autostart.desktop ~/.config/autostart/
vim ~/.xprofile
# --------------------
# 加入
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx
# export XMODIFIERS=@im=fcitx
# --------------------
```

### 虚拟机安装Virtualbox增强功能
```
pacman -S virtualbox-guest-utils
# VBoxClient-all    //手工启动增强服务
# modprobe -a vboxguest vboxsf vboxvideo    //手工在Linux Kernel中开启相应的功能模块,这一步非必须
# systemctl enable vboxservice    //开机自动启动这个服务后可以实现虚机与Host之间的时间自动同步
# vim /etc/xdg/openbox/autostart    //编辑增加一行VBoxClient-all实现开机自动启动增强服务
```
