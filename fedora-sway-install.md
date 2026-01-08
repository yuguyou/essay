安装 Sway: 使用 dnf 安装 Sway 和一些基本工具。
```bash
sudo dnf install sway swaylock swayidle wofi waybar
```
sway: 平铺窗口管理器本身。
swaylock: 锁屏工具。
swayidle: 自动休眠/锁定工具。
wofi: 类似 dmenu 的应用启动器/菜单。
waybar: 一个高度可定制的 Wayland 状态栏（可选）。

添加配置文件
```bash
mkdir -p .config/sway
cp /etc/sway/config ~/.config/sway/
```

安装交互润滑剂:kuid(Kinetic UI Dameon)
```bash
git clone https://github.com/milgra/kuid
cd kuid
meson setup build
ninja -C build
sudo ninja -C build install
```
安装wcp(Wayland Control Panel)
```bash
git clone https://github.com/milgra/wcp
cd wcp
mkdir ~/.config/wcp
cp wcp-debian.sh ~/.config/wcp/wcp.sh
cp -R res ~/.config/wcp/
```
