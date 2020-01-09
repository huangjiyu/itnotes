mailx 也可能包含在mailutils 或 s-nail包中

编辑/etc/mail.rc添加
set from=xxxx@qq.com
set smtp=smtp.qq.com
set smtp-auth-user=xxx@qq.com
set smtp-auth-password=nibpgbkksmlbbabe
set smtp-auth=login
set sendcharsets=utf-8
#set smtp-use-starttls #使用starttls
#set ssl-verify=ignore
#set nss-config-dir=/root/.certs

mailx -s "subject" xxx@xx.com <msg_content


证书不信任问题
certutil -A -n "GeoTrust SSL CA - G3" -t "Pu,Pu,Pu" -d ./ -i /root/.certs/xxx.crt



    命令行: mail -s "theme" addressee,回车后输入内容按Ctrl+D发送邮件.
    管道符: echo "mail main content" | mail -s "theme" addressee
    文件内容作为邮件内容: mail -s "theme" addressee < /tmp/t.txt

-a　添加附件
-c　添加抄送

```shell
#Mail From
from=xxxx@qq.com
smtp=smtp.qq.com
user=$from
pwd=$pwd

#Mail To
subject=
content=
addr=  #xx@yy.com
cc=  #xx@zz.com
attachment=  #attachment file

cron_reg="*/10 * * * *"
cron_cmd="/srv/mail.sh"

sudo chmod u+w /etc/mail.rc
sudo echo "
set from=$from
set smtp=$smtp
set smtp-auth-user=$from
set smtp-auth-password=$pwd
set smtp-auth=login
set sendcharsets=utf-8
" > /etc/mail.rc

sudo echo "$cron_reg $cron_cmd" >> /var/spool/cron/root

echo "
if xxxx
then
  echo \"$subject\" | mail -s \"$msg\" $addr $attachment $cc
fi
" > $cron_cmd
```