### ubuntu 18.04 国内安装kubernetes
#### 替换源
替换阿里源/etc/apt/sources.list
```
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
```

```bash
$ apt-get update
```



#### 安装docker
```bash
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
$ curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入docker软件源信息
$ sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装Docker-CE  kubernetes对docker的版本号有依赖需求，部署kubernetes前先部署指定版本的docker
$ sudo apt-get -y update
$ sudo apt-get -y install docker-ce

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# apt-cache madison docker-ce
# docker-ce | 17.03.1~ce-0~ubuntu-xenial |https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.1~ce-0~ubuntu-xenial)
# sudo apt-get -y install docker-ce=[VERSION]

$ systemctl start docker
$ systemctl enable docker
```
将数据添加到docker用户组中

```bash
$ sudo usermod -aG docker $USER
```

#### K8S安装

###### 环境准备

1. 内核开启ip4转发

```bash
# 编辑 /etc/sysctl.conf，开启ipv4转发
$ sudo vim /etc/sysctl.conf
$ sudo sysctl -p
```

2. 禁用 Swap 分区，Swap会影响性能(测试环境物理资源不够时可以不禁用)

```bash
# 临时禁用
$ sudo swapoff -a
# 将swap挂载注释
$ vim /etc/fstab
```

3. 各节点禁用SElinux

4. 各节点时间同步

5. 关闭iptables或firewalld
6. 启用ipvs内核模块

##### 安装 Kubernetes服务

###### 测试环境

* 可以使用单Master节点、单etcd实例
* Node主机数量：按需求而定
* 存储：额外使用nfs或gluisterfs提供储存服务

###### 生产环境

* 高可用Master
	* kube-apiserver无状态，可多实例
		* 在多实例前端通过HAProxy或Nginx反向代理，借助keepalived对代理服务器进行冗余
	* kube-scheduler、kube-controller-manager各自只能有一个活动实例，但可以有多个备用
		* 各自自带leader选举的功能，并且默认处于启用状态
* 高可用etcd集群，建立3、5、7个节点
* Node 主机数量： 数量越多冗余能力越强
* 存储：ceph、glusterfs、iSCSI、FC SAN等专业的存储设备

###### 部署工具

* 常用的部署环境
	* IaaS公有云环境： AWS,GCE,Azure
	* IaaS私有云或公有云环境：OpenStack和vSphere
	* Baremetal环境： 物理服务器、裸金属服务器（底层没有云基础的环境）或独立的虚拟机等
* 常用的部署工具
	* kubeadm k8s官方部署工具（还是alpha版本不能在生成环境使用）
	* kops 亚马逊的云计算机上的部署工具
	* 手动部署

###### 二次封装的常用发行版
k8s是比较原始，使用很复杂，二次封装发行版方便使用
* Rancher 2.0
* Tectonic
* Openshift

###### k8s部署运行方式

* 容器运行方式 (使用kubeadm部署的是容器运行方式)
* 守护进程运行方式

###### 安装kubernetes基础工具 kubeadm、 kubelet、 kubectl

```bash
$ sudo apt-get install -y apt-transport-https curl
# 设置使用国内（阿里）镜像源进行安装
$ sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
$ sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF
$ sudo apt-get update

# 安装最新版本的 kubelet kubeadm 和 kubectl
# kubelet 是 work node 节点负责 Pod 生命周期状态管理以及和 master 节点交互的组件
# kubectl k8s 的命令行工具，负责和 master 节点交互
# kubeadm 搭建 k8s 的官方工具
$ sudo apt-get install -y kubelet kubeadm kubectl
# 将 kubelet 设置为开启启动
$ sudo systemctl start kubelet
$ sudo systemctl enable kubelet
```

###### 安装其它容器工具

获取镜像文件

```bash
$ kubeadm config images list
# 系统输出:
k8s.gcr.io/kube-apiserver:v1.21.0
k8s.gcr.io/kube-controller-manager:v1.21.0
k8s.gcr.io/kube-scheduler:v1.21.0
k8s.gcr.io/kube-proxy:v1.21.0
k8s.gcr.io/pause:3.4.1
k8s.gcr.io/etcd:3.4.13-0
k8s.gcr.io/coredns/coredns:v1.8.0
```

编辑一个文件, 命名为： install_k8s_images.sh
```bash
#! /bin/bash
images=(
    kube-apiserver:v1.21.0
    kube-controller-manager:v1.21.0
    kube-scheduler:v1.21.0
    kube-proxy:v1.21.0
    pause:3.4.1
    etcd:3.4.13-0
    coredns/coredns:v1.8.0
)


for imageName in ${images[@]} ; do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
done
```
执行命令
```bash
$ bash install_k8s_images.sh
需要单独在国外环境pull
$ docker pull k8s.gcr.io/coredns/coredns:v1.8.0
$ docker save -o coredns.tar k8s.gcr.io/coredns/coredns:v1.8.0
```

配置Master节点
```bash
$ sudo hostnamectl set-hostname HOSTNAME
```
将主机名映射为IP地址，如下
```
192.168.1.218 kubemaster
192.168.1.219 kubenode1
192.168.1.220 kubenode2
```

初始化Master
```bash
$ sudo kubeadm init --pod-network-cidr=192.168.1.90/16
# init 常用主要参数：
#    –kubernetes-version: 指定Kubenetes版本，如果不指定该参数，会从google网站下载最新的版本信息。
#    –pod-network-cidr: 指定pod网络的IP地址范围，它的值取决于你在下一步选择的哪个网络网络插件。
#    –apiserver-advertise-address: 指定master服务发布的Ip地址，如果不指定，则会自动检测网络接口，通常是内网IP。
#    kubeadm init 输出的token用于master和加入节点间的身份认证，token是机密的，需要保证它的安全，因为拥有此标记的人都可以随意向集群中添加节点。
```

仅在master上创建下面目录：
```bash
$ mkdir -p $HOME/.kube
# 将相应的配置你文件拷贝到该目录下：
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

部署Pod网络，在将worker node加入到master之前，必须先部署pod网络(否则，所有事情都无法按照预期那样正常工作），[Flannel](https://tonybai.com/2017/01/17/understanding-flannel-network-for-kubernetes/)是可选的Pod网络之一。
```bash
部署一个 Flannel pod network
$ sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
查看pod网络的状态:
$ kubectl get pods --all-namespaces
```

将worker node加入到master
```bash
获取添加节点部署命令
$ kubeadm token create --print-join-command

$ kubeadm join 192.168.43.10:6443 --token mg39mb.hmfz2bao1t90fcdc --discovery-token-ca-cert-hash sha256:4343f8637818221cc153a4c556a6a29606f5a14ea040b3e9ee1e5e29af6e7381

$ kubectl get nodes
```



## 部署 Dashboard UI

```bash
# Dashboard 是基于网页的 Kubernetes 用户界面。 你可以使用 Dashboard 将容器应用部署到 Kubernetes 集群中，也可以对容器应用排错，还能管理集群资源。 你可以使用 Dashboard 获取运行在集群中的应用的概览信息，也可以创建或者修改 Kubernetes 资源 （如 Deployment，Job，DaemonSet 等等）。 例如，你可以对 Deployment 实现弹性伸缩、发起滚动升级、重启 Pod 或者使用向导创建新的应用。
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

# 部署成功后，启动 Kubernetes API Server 访问代理。
$ kubectl proxy --address='host ip' --accept-hosts='host ip'
http://host ip:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/


```