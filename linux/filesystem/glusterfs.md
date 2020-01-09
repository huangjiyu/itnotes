# 简介

GlusterFS 是一个高扩展性、高可用性、高性能、可横向扩展的分布式网络文件系统。

- **无集中式元数据服务**
- 全局统一命名空间
- 采用哈希算法定位文件
- 弹性卷管理

（目前版本来看）适用于大文件存储场景，对海量小文件存储和访问效率不佳。多用于云存储、虚拟化存储、HPC领域。

## 基本概念

- cluster集群

  相互连接的一组服务器，他们协同工作共同完成某一个功能，对外界来说就像一台主机。

- Server / Node / Peer  节点

  单台服务器，在glusterfs中单个节点被称为peer，是运行gluster和分享“卷”的服务器。

- Trusted Storage Pool  可信的存储池

  peer节点的集合，是存储服务器所组成的可信网络。

- Brick “砖块” 即存储块

   可信主机池中由主机提供的用于物理存储的专用分区。

- Volume 卷（逻辑卷）

  Brick组成的逻辑集合，是存储数据的逻辑设备。

  - SubVolume 分卷

    由多个Brick逻辑构成的卷，是其它卷的子卷，特定[卷类型](卷类型)中存在。
    
    *比如在`分布复制卷`中每一组复制的Brick就构成了一个复制的分卷(subvolume)，而这些分卷又组成了逻辑卷(volume)。*

- Client 客户端

  挂载glusterfs共享的Volume（卷）的主机。

# 卷类型

- 基本卷
  - 分布式卷(Distributed Volume)
  - 复制卷(Replicated Volume)
  - 条带卷(Striped Volumes)

- 复合卷
  - 分布式复制卷(Distributed Replicated Volume)
  - 分布式条带卷(Distributed Striped Volume)
  - 复制条带卷(Replicated Striped Volume)
  - 分布式复制条带卷(Distributed Replicated Striped Volume)



## 基本卷

从可用容量上看，分布式卷和条带卷是将各个存储块存储容量叠加以扩大存储空间（二者区别在于是否对文件进行切片存储），复制卷则是将文件复制到多个存储块上（文件多个备份，文件亦不切块），卷容量为所有存储块总容量除以副本数量。



### 分布式卷(Distributed Volume)

文件通过hash算法分布到brick server上（又称为哈希卷）。（文件完整存储到某个brick，可在该brick所在server上看到**完整的文件**）

文件级RAID0，不存在容错能力，如果有一个存储块所在硬盘损坏，**对应的数据也丢失**。

### 条带卷(Striped Volumes)

**文件切分成数据块**（chunk）以Round Robin方式分布到brick server上。（文件切块分散到多个brick）

类似RAID0，同分布式卷一样不存在容错能力（而且由于文件切块较之分布式卷损失更大），并发粒度是数据块，支持超大文件，大文件性能高，适用于大文件存储。

### 复制卷(Replicated Volume)

文件同步复制到多个brick上。（文件副本）

可定义副本数量（两副本是即是文件级RAID1），具有容错能力，写性能下降，读性能提升。

### 散列卷



## 复合卷

基本卷的组合形式。



### 分布式复制卷(Distributed Replicated)

分布式+复制，brick server数量是镜像数的倍数，可以在2个或多个节点之间复制数据。

类似RAID10，多个brick组成一个分布式子卷(subvolume)，子卷又组成复制卷（即每个子卷内容相同，互为备份）。

### 条带复制卷(Replicated Striped Volume)

条带+复制，

类似RAID10，多个brick组成一个条带子卷(subvolume)，子卷又组成复制卷（即每个子卷内容相同，互为备份）。

### 分布式条带卷(Distributed Striped Volume)

分布式+条带，brick server数量是条带数的倍数。

多个brick组成一个分布式子卷(subvolume)，子卷又组成条带卷。



### 分布式复制条带卷(Distributed Replicated Striped



# 安装配置

## 准备

- 各个节点hostname及hosts文件

- selinux和防火墙关闭或配置放行策略

- 为各个节点上将用作glusterfs存储块的物理分区创建文件系统并挂载这些分区

  示例：

  ```shell
  mkfs.xfs /dev/sdc
  mkdir -p /mnt/brick1
  mount /dev/sdc /mnt/brick1
  ```

  

## 安装和启用服务



## 配置存储池并创建卷

在其中一个glusterfs节点上添加其他glusterfs节点以组建存储池

```shell
gluster peer probe <node-hostname>  #<node-hostname>即要被添加的节点的主机名
#gluster peer probe ... 逐个添加glusterfs 节点主机  无需添加执行该命令的节点本身
```

根据需求创建指定类型的glusterfs卷：

```shell
#创建时写上所有要被加到新建卷中的存储块
gluster volume create <volume-name> replica 2 transport rdma node1:/mnt/brick1 node2:/mnt/brick2 node3:/mnt/md0 [force]
```

- `volume-name`是为卷起的名字
- `node1:/mnt/brick1` 表示添加node1节点上`/mnt/brick1`存储块到该卷中



### 扩容、收缩和迁移

扩容：

1. 添加新的节点（新节点完成了各种[准备](#准备)操作）

2. 添加新的存储块

   ```shell
   gluster volume add-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 # 合并卷
   ```

收缩：危险操作，有数据丢失风险，收缩卷前先移动数据到其他位置以确保数据安全。

```shell
gluster volume remove-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 start 

#可查看完成状态
gluster volume remove-brick GPUFS node4:/mnt/md0 node5:/mnt/md0 status 
```

迁移：迁移一个brick上的数据到另一个brick

```shell
gluster volume replace-brick GPUFS node5:/mnt/md0 node6:/mnt/md0 start 

# 查看迁移状态 
gluster volume replace-brick GPUFS node5:/mnt/md0 node6:/mnt/md0 status

gluster volume heal  <volume-name>  full # 同步整个卷
```



### 客户端挂载

```shell
mount -t glusterfs node1:/GPUFS /glusterfs
```

fstab：

```shell
<server>:<volume-name>    <mount-point>    glusterfs  defaults,_netdev    0 0
```

server可以是任意一个peer节点

