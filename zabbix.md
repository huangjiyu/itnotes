参看[文档](https://www.zabbix.com/documentation)

示例中系统为centos7，均采用postgresql数据库。

安装前添加源

```shell
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm
```

在不同角色的主机安装服务：

- server

  汇总和输出所有被监控主机的信息。

  ```shell
  yum install -y zabbix-serve-pgsql   #or mysql
  ```

- proxy（可选）

  分布式监控中，汇总一个区域内所有agent的信息转发给server，或在数量巨多（通常指大于500台主机）的情况中分担server的采集压力。

  ```shell
  yum install -y zabbix-proxy-pgsql  #or mysql   sqlite3
  ```

- agent

  各个被监控的主机，数据发往proxy或server。

  ```shell
  yum install -y zabbix-agent
  ```

  

此外可安装zabbix的web前端（一般安装在server上）：

```shell
yum install -y zabbix-web-pgsql #或通用的zabbix-web  或zabbix-web-mysql
```

web服务程序是用php编写，需要安装php、php-fpm、nginx/apache、php-pgsql（php-mysql）等，配置并启用服务。

额外要启用和配置的php参数，编辑`etc/php/php.ini`：

```shell
extension=bcmath
extension=gd
extension=sockets
extension=pgsql
;extension=mysqli  #mysql启用
;extension=sqlite #sqlite启用
extension=gettext
post_max_size = 16M
max_execution_time = 300
max_input_time = 300
date.timezone = "UTC"
```





zabbix_get：一个命令行应用，它可以用于与 Zabbix agent 进行通信，并从 Zabbix agent 那里获取所需的信息，通常被用于 Zabbix agent 故障排错。



fping：用于通过ICMP/ping发现新加入主机。



防火墙

关闭，或放行端口如下

- agent: 10050/tcp
- proxy/server: 1051/tcp

```shell
#server or proxy
firewall-cmd --zone=public --add-port=10051/tcp --permanent
#agent
firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd--reload
```



数据库

server和proxy上需要数据库，如果server和proxy在同一主机上，则需要创建不同数据库分别存储。以下以postgresql为例。

1. 创建zabbix数据库及专用用户

   ```shell
   sudo -u postgres createuser zabbix
   #or
   #su - postgres -c "createuser zabbix"
   
    sudo -u postgres createdb -O zabbix -E unicode -T template0 zabbix
   #or
   # su - postgres -c "createdb -O zabbix -E unicode -T template0 zabbix"
   ```

2. 导入数据

   初始数据存放在zabbix安装目录`/usr/share/doc/`（或在`/usr/share`）下，根据数据库(mysql或sqlite)及模块(server或proxy)情况进入相应目录中。

   使用`psql -U <username> -d <dbname> -f <file.sql>`导入数据。

   如果是gz压缩包可以使用zcat解开后通过管道符传给pgsql导入。

   ```shell
   #cd到目中
   pgsql -U zabbix -d zabbix -f schema.sql
   pgsql -U zabbix -d zabbix -f images.sql
   pgsql -U zabbix -d zabbix -f data.sql
   
   #对于gz
   #zcat xx.gz | pgsql _U zabbix -d zabbix
   ```

3. 配置数据库

   编辑`/etc/zabbix/zabbix_server.conf`，根据情况修改如下内容：

   ```shell
   DBHost=localhost
   DBName=zabbix
   DBUser=zabbix
   DBPassword=<password> 
   ```

4. 启动zabbix_server_pgsql服务