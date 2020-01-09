# yum

- `/usr/bin/yum”, line 29, in...`

修改/etc/yum.conf，将plugins=1 改为 0；

修改/etc/yum/pluginconf.d/fastestmirror.conf，将enabled=1 改为 0;

执行`yum clean all`
