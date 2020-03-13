### SSL和HTTP2

使用ssl和http2，需在listen后的端口号后面加上ssl/http2；填写ssl的证书路径和私钥路径。示例（仅示例server中ssl和http2相关配置部分）：

```nginx
server{
  listen  443 ssl http2;
  ssl_certificate  /etc/letsencrypt/live/xx.xxx/fullchain.pem;
  ssl_certificate_key  /etc/letsencrypt/live/xx.xx/privkey.pem;
  ssl_session_cache  shared:SSL:1m;
  ssl_session_timeout  10m;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
}
```

http地址跳转到https地址可以新建一个server，示例：

```nginx
server{
  listen 80;
  server_name xxx;
  return 301 https://$server_name$request_uri;
  #或rewrite ^(.*) https://$host$1 permanent;
}
```

### 禁止通过ip直接访问网站/防止恶意解析

[禁止使用ip访问](nginx/conf.d/donotvisitbyip.conf)以防止恶意解析，添加一个新的server：

```nginx
server{
  listen 80;
  server_name ip;    #ip处写上ip地址
  return 444;
}
```

或者使用下面的方法：

```shell
server{
        listen 80 default;
        server_name  _;
        return 501;
    }
server{
        listen 443 default;
        server_name  _;
        return 501;
    }
```

### 配置websocket

WebSocket协议的握手兼容于HTTP的，使用HTTP的`Upgrade`设置可以将连接从HTTP升级到WebSocket。配置示例（server内其他内容略）：

```nginx
location /wsapp/ {
  proxy_pass https://wsapp.xx.xxx;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
}
```

### 子域名访问对应的子目录

*如abc.xx.com访问xx.com/abc*

1. 确保在域名解析服务商设置了泛解析：使用A记录，主机记录填写`*`

2. 配置一个server，示例：

   ```nginx
   server{
     listen 80;
     server_name ~^(?<subdomain>.+).xx.com$;
     root   /srv/web/$subdomain;
     index index.html;
   }
   ```

### 目录浏览

在server（或者指定的location中）添加（示例[autoindex](nginx/conf.d/indexview/autoindex) ）：

```nginx
autoindex on;
autoindex_exact_size off;
autoindex_localtime on;
```

- [fancy插件](https://github.com/aperezdc/ngx-fancyindex) ：如果要修改目录浏览页面的样式需要使用

  1. 在server中添加[fancy配置](nginx/conf.d/indexview/fancy)（使用fancy配置就不要再添加autoindex相关配置了）：

  ```nginx
  fancyindex on;
  fancyindex_exact_size off;
  fancyindex_localtime on;
  fancyindex_name_length 255;
  
  fancyindex_header "/fancyindex/header.html";
  fancyindex_footer "/fancyindex/footer.html";
  fancyindex_ignore "/fancyindex";
  ```

  2. 添加相应位置的header.html和footer.html页面（可以是空白页面）

     在header.html和footer.html进行目录浏览页面相关配置。


  3. 配置fancy后提示unknown directive "fancyindex" :

     在/etc/nginx/nginx.conf文件中加载fancy模块（例如该模块位于/usr/lib/nginx/modules下）：`load_module "/usr/lib/nginx/modules/ngx_http_fancyindex_module.so";` 。

### 页面加密

可以用htpasswd工具来生成密码，使用以下命令生成一个密码文件：

```shell
#username是要添加的用以在加密页面登录的用户 password是对应的密码
htpasswd -b -p /etc/nginx/conf.d/lock username password
#可以重复添加用户 参照上一条命令
#删除用户
htpasswd -D /etc/nginx/conf.d/lock username
#修改密码参照添加用户的方法 使用一个新密码即可
```

- -b 在命令行中一并输入用户名和密码而不是根据提示输入密码
- -c 创建passwdfile.如果passwdfile 已经存在,那么它会重新写入并删去原有内容.
- -n 不更新passwordfile，直接显示密码
- -m 使用MD5加密（默认）
- -d 使用CRYPT加密（默认）
- -p 使用普通文本格式的密码
- -s 使用SHA加密
- -D 删除指定的用户

然后在要加密的目录的location中单独[配置](nginx/conf.d/passlock)：

```nginx
auth_basic "tips";  #tips是要提示给用户的信息
auth_basic_user_file /etc/nginx/conf.d/lock;  #密码文件路径
```

## 