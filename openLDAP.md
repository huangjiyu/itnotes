# 简介

层级关系：

- o
  - ou
    - cn

主要简称含义：

> `o` -> `organization`（组织-公司）
>
> `ou` -> `organization unit`（组织单元-部门）
>
> `cn` -> `common name`（常用名称）
>
> `c` -> `countryName`（国家）
>
> `dc` -> `domainComponent`（域名）
>
> `sn` -> `suer name`（真实名称）



在LDAP中，schema用来指定一个目录中所包含的对象（objects）的类型（objectClass），以及每一个类型（objectClass）中必须提供的属性（Atrribute）和可选的属性。可将schema理解为面向对象程序设计中的类，通过类定义一个具体的对象。

ldap命令常用参数

> -x：进行简单认证。
> -D：用来绑定服务器的dn。
> -w：绑定dn的密码。
> -b：指定要查询的根节点。 
> -H：制定要查询的服务器。
> -h：目录服务的地址

主要是
添加，将name.ldif文件中的条目加入到目录中

> ldapadd -x -D "cn=root,dc=dlw,dc=com" -w secret -f name.ldif

查找，使用ldapsearch命令查询“dc=dlw, dc=com”下的所有条目

> ldapsearch -x -b "dc=dlw,dc=com" 

修改，分为交互式修改和文件修改，推荐文件修改
将sn属性由“Test User Modify”修改为“Test User”

> dn: cn=test,ou=managers,dc=dlw,dc=com  
> changetype: modify  
> replace: sn  
> sn: Test User

输入命令

> ldapmodify -x -D "cn=root,dc=dlw,dc=com" -w secret -f modify  

删除，删除目录数据库中的“cn=test,ou=managers,dc=dlw,dc=com”条目

> ldapdelete -x -D "cn=root,dc=dlw,dc=com" -w secret "cn=test,ou=managers,dc=dlw,dc=com"  

OpenLDAP监听的端口：

   默认监听端口：389（明文数据传输）

   加密监听端口：636（密文数据传输）

# 服务端

1. 安装

   ```shell
   yum install -y openldap openldap-clients openldap-servers migrationtools openldap-devel compat-openldap
   cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
   chown ldap. /var/lib/ldap/DB_CONFIG
   systemctl start slapd
   systemctl enable slapd
   ```

2. 配置管理员

   1. 设置管理员密码

      ```shell
      slappasswd  -s 123456 #123456为示例密码
      ```

      将密码使用`slappasswd`加密生成一段类似字符串：

      > {SSHA}NnNbLKrDr1TqrFvFShhrilkBoFXCH26

   2. 导入管理员账户

      编辑或新建`/etc/openldap/chrootpw.ldif`配置文件，添加如下信息：

      ```shell
      dn: olcDatabase={0}config,cn=config
      changetype: modify
      add: olcRootPW
      olcRootPW: {SSHA}NnNbLKrDr1TqrFvFShhrilkBoFXCH26
      ```

      olcRootPW即前一步中密码生成的字符串。

      执行：

      ```shell
       ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/chrootpw.ldif
      ```

   3. 导入基本schema

      ```shell
      ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
      ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
      ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
      ```

   4. 导入基础域名

      编辑或新建`/etc/openldap/chdomain.ldif `配置文件，添加如下信息：

      ```shell
      dn: olcDatabase={1}monitor,cn=config
      changetype: modify
      replace: olcAccess
      olcAccess: {0}to by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc=beyondh,dc=org" read by none
      
      dn: olcDatabase={2}hdb,cn=config
      changetype: modify
      replace: olcSuffix
      olcSuffix: dc=gongchang,dc=com
      
      dn: olcDatabase={2}hdb,cn=config
      changetype: modify
      replace: olcRootDN
      olcRootDN: cn=admin,dc=gongchang,dc=com
      
      dn: olcDatabase={2}hdb,cn=config
      changetype: modify
      replace: olcRootPW
      olcRootPW: {SSHA}NnNbLKrDr1TqrFvFShhrilkBoFXCH26
      
      dn: olcDatabase={2}hdb,cn=config
      changetype: modify
      replace: olcAccess
      olcAccess: {0}to attrs=userPassword,shadowLastChange by dn="cn=admin,dc=gongchang,dc=com" write by anonymous auth by self write by none
      olcAccess: {1}to dn.base="" by read
      olcAccess: {2}to by dn="cn=admin,dc=gongchang,dc=com" write by read
      ```

      执行：

      ```shell
      ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/openldap/chdomain.ldif
      ```

   5. 重启`slapd`服务

      

# 客户端

安装：

```shell
yum -y install openldap-clients nss-pam-ldapd #sssd authconfig-tui #authconfig-gtk
```

配置：

authconfig-tui和authconfig-gtk可选，分别提供命令行中的图形风格界面和gtk图形前端配置工具。图形界面中需要选择Use LDAP和Use LDAP Authentication，TLS认证可选。

authconfig命令配置LDAP，参数对应者图形界面中的各个选项：

```shell
#基本配置如下
ldapserver=192.9.20.1
ldapbasedn='dc=csmt,dc=com'

authconfig --enableldap --enableldapauth --enablemkhomedir --enableforcelegacy --disablesssd --disablesssdauth --disableldaptls --enablelocauthorize --ldapserver=$ldapserver --ldapbasedn="$ldapbasedn" --enableshadow --update

#如果配置TLS使用--enableldaptls, --enableldapstarttls和--ldaploadcacert=<URL>参数
#authconfig --enableldap --enableldapauth --ldapserver=<server> --ldapbasedn=<dn>  --enableldaptls ldaploadcacert=<URL>
```

检验：

```shell
getent passwd
```

