### 步骤
1. 下载ArchLinux安装镜像并 制作U盘启动工具
2. 开机从U盘启动
3. 进行联网
4. 编辑镜像站文件(选择一个比较快的中国镜像源)
5. 开始分区(UEFI+GPT)
6. 格式化分区，并挂载
7. 开始安装基本操作系统
8. 配置基础系统
9. 用户管理
10. 引导系统

### 一. 制作启动盘
* 下载系统镜像，使用rufus用dd模式制作启动盘（或使用UltraISO的raw写入方式写入硬盘映像）
### 二. 启动
验证启动模式
* 如果在 UEFI 主板上启用 UEFI 模式，Archiso 将会使用 systemd-boot 来 启动Arch Linux。可以列出 efivars 目录以验证启动模式：`ls /sys/firmware/efi/efivars`如果目录不存在，系统可能以 BIOS 或 CSM 模式启动，详见您的主板手册。

### 三. 连接到因特网
* 守护进程 dhcpcd 已被默认启用来探测 有线网络设备，并会尝试连接。可以使用 ping 验证连接是否正常。
* 如果没有可用网络连接，利用 systemctl stop dhcpcd 网络接口，停用 dhcpcd 进程，网络接口名可以通过 Tab补全。
* 更新系统时间
使用 timedatectl(1) 确保系统时间是准确的：`timedatectl set-ntp true`。可以使用 timedatectl status 检查服务状态。

### 四. 编辑镜像站文件(选择一个比较快的中国镜像源)
* 文件 `/etc/pacman.d/mirrorlist` 定义了软件包会从哪个镜像源 下载。在列表中越前的镜像在下载软件包时有越高的优先权。你可以相应的修改文件 /etc/pacman.d/mirrorlist，并将地理位置最近的镜像源挪到文件的头部，同时你也应该考虑一些其他标准。

### 五. 建立硬盘分区
磁盘若被系统识别到，就会被分配为一个块设备，如 /dev/sda 或者 /dev/nvme0n1。可以使用 lsblk 或者 fdisk 查看：
```
 fdisk -l
```
结果中以 rom，loop 或者 airoot 结束的可以被忽略。
1. 选择 GPT 还是 MBR分区表
GUID Partition Table （GPT）是一种更灵活的分区方式。它正在逐步取代Master Boot Record （MBR）系统。GPT相对于诞生于MS-DOS时代的MBR而言，有许多优点。新版的fdisk（MBR）和gdisk（GPT）使得使用GPT或者MBR在可靠性和性能最大化上都非常容易。
在做出选择前，需要考虑如下内容：
* 如果使用 GRUB legacy 作为bootloader，必须使用MBR。
* 如果使用传统的BIOS，并且双启动中包含 Windows （无论是32位版还是64位版），必须使用MBR。
* 如果使用 UEFI 而不是BIOS，并且双启动中包含 Windows 64位版，必须使用GPT。
* 非常老的机器需要使用 MBR，因为 BIOS 可能不支持 GPT.
* 如果不属于上述任何一种情况，可以随意选择使用 GPT 还是 MBR。由于 GPT 更先进，建议选择 GPT。
* 建议在使用 UEFI 的情况下选择 GPT，因为有些 UEFI firmware 不支持从 MBR 启动。
注意: 为了使 GRUB 从一台有 GPT 分区的基于 BIOS 的系统上启动，需要创建一个 BIOS 启动分区, 这个分区和 /boot 没关系，仅仅是 GRUB 使用，不要建立文件系统和挂载。

2. 分区策略（分区功能查看该笔记本《linux分区结构》）:
```
├─sda1    vfat    300M(UEFI系统至少512M)    /boot/EFI
├─sda2    ext4    30G                      /
├─sda3    ext4    100%                     /home
└─sda4    swap    4G(内存的2倍)             [SWAP]
```
3. 使用parted分区
mkpart [ part-type fs-type start end ]    4 个参数，分别是 分区类型、文件系统类型、起始点、结束点，分区类型就主分区还是逻辑分区
```
parted /dev/sda
(parted) mklabel  msdos 或 gpt                   使用MBR或GPT引导格式
(parted) mkpart primary ext4 1 1G              引导分区boot 
(parted) set 1 boot on               对指定编号的分区标记FLAG  常用分区标记有boot(引导)，hidden，lvm等
(parted) mkpart primary ext4 1G 30G            挂载系统root
(parted) mkpart primary linux-swap 30G 34G     交互分区（虚存）
(parted) mkpart primary ext4 34G 100%          剩下的所有划分一个分区，用来挂载系统home
(parted) quit
```
### 六. 格式化与挂载分区
格式化
```
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkswap /dev/sda3
mkfs.ext4 /dev/sda4
```
挂载分区
```
mount /dev/sda2 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/sda4 /mnt/home
swapon /dev/sda3
```

### 七. 安装基本系统
使用 pacstrap 脚本，安装 base 组：
```
# pacstrap -i /mnt base linux-lts linu-firmware base-devel
```

### 八. 配置系统
1. Fstab
用以下命令生成 fstab 文件 (用 -U 或 -L 选项设置UUID 或卷标)：
```
$ genfstab -U /mnt >> /mnt/etc/fstab
# 在执行完以上命令后，后检查一下生成的 /mnt/etc/fstab 文件是否正确
$ cat /mnt/etc/fstab
```

2. Chroot
Change root 到新安装的系统：
```
$ arch-chroot /mnt
```

3. 设置 时区：
```
$ ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 运行 hwclock(8) 以生成 /etc/adjtime：
$ hwclock --systohc
```
4. 本地化
* 本地化的程序与库若要本地化文本，都依赖Locale，后者明确规定地域、货币、时区日期的格式、字符排列方式和其他本地化标准等等。在下面两个文件设置：locale.gen 与 locale.conf

```bash
# 只需移除对应行前面的注释符号（＃）即可，建议选择带 UTF-8 的项
vim /etc/locale.gen
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
```
* 执行locale-gen 以生成 locale 讯息：
```bash
$ locale-gen  # /etc/locale.gen生成指定的本地化文件。
# 创建 locale.conf 并编辑LANG变量
$ echo "LANG=en_US.UTF-8" > /etc/locale.conf
```
`Tip: 将系统 locale 设置为 en_US.UTF-8，系统的 Log 就会用英文显示，这样更容易问题的判断和处理。不推荐在此设置任何中文 locale，会导致 TTY 乱码`

5. 主机名
要设置hostname，将其添加 到 /etc/hostname:
```bash
$ echo "hostname" > /etc/hostname
```

6. 设置 Root 密码：
```bash
$ passwd root
```
7. 添加用户
虽然你也可以直接用 root 用户，但是毕竟不安全，有些软件不能直接用 root 
```
# wheel组用户才能通过su命令切换到root用户
$ useradd -m -g users -G wheel -s /bin/bash vk
$ passwd vk
```

8. 安装 sudo
 要使用 sudo 命令提权的话需要安装 sudo 并且做相应配置
```
pacman -S sudo
#找到 root ALL=(ALL) ALL 并依葫芦画瓢添加 vk ALL=(ALL) ALL 即可。因为/etc/sudoers是只读文件，保存修改时需要":w!"强制写入
vi /etc/sudoers
```

### 九. 安装引导程序
本文推荐 GRUB 作为引导程序
* BIOS 系统：
```bash
$ pacman -S grub os-prober
$ grub-install --target=i386-pc [目标磁盘(/dev/sdX)]
$ grub-mkconfig -o /boot/grub/grub.cfg
```
* UEFI 系统：
```bash
$ pacman -S dosfstools grub efibootmgr
$ grub-install --target=x86_64-efi --efi-directory=</boot(EFI 分区挂载点)> --bootloader-id=grub
$ grub-mkconfig -o /boot/grub/grub.cfg
``` 
### 十. 重启
1. 输入 exit 或按 Ctrl+D 退出 chroot 环境。
2. `umount -R /mnt` 手动卸载被挂载的分区：这有助于发现任何「繁忙」的分区，并通过 fuser(1) 查找原因。
3. 通过执行 reboot 重启系统，systemd 将自动卸载仍然挂载的任何分区。不要忘记移除安装介质，然后使用 root 帐户登录到新系统。
