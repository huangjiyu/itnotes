#!/bin/sh
if [[ $USER != root ]]; then
  echo "need root or sudo."
  exit
fi

#-----
jail_file=/etc/fail2ban/jail.d/jail.local

jails=(sshd mongodb-auth mysqld-auth vsftpd vnc-auth)

default_jail=(sshd)

logpath=''

#log path

bandtime=8640000 #默认秒s m h d w
findtime=6000
maxretry=5

#-----

function check_fail2ban_app() {
  which pacman 2>/dev/null || pacman -Syy fail2ban --no-confirm

  if [[ ! $(which fail2ban-server) ]]; then
    echo "please install fail2ban"
    exit
  fi
}

function add_vnc_auth_filter() {
  echo "[Definition]
failregex = authentication failed from <HOST>
ignoreregex =" >/etc/fail2ban/filter.d/vnc-auth.conf
}

function gen_jail_file() {
  [[ -f $jail_file ]] && mv $jail_file $jail_file.bak

  echo "[DEFAULT]
bantime = $bandtime
findtime = $findtime
maxretry = $maxretry
" >$jail_file
}

function services_logpath() {
  case $1 in
  mongodb-auth)
    logpath=/var/log/mongodb/mongod.log
    ;;
  vnc-auth)
    echo -e "!!! should add \e[1m logpath \e[0m and \e[1m port \e[0m below \e[33m vnc-auth \e[0m section in /etc/fail2ban/$jail_file"
    echo "===eg:
    [vnc-auth]
    port=5901
    logpath=/home/testuser/.vnc/*.log
    "
    ;;
  *)
    echo ''
    ;;
  esac
}

function add_jails() {
  echo "$(tput bold)Select filter service：$(tput sgr0)"
  local i=0
  for jail in ${jails[*]}; do

    echo "$i) $jail $([[ $i -eq 0 ]] && echo [default])"
    i=$((i + 1))
  done

  echo "-------------"
  read select_jails

  [[ "$select_jails" ]] || select_jails='0'
  for select_jail in $select_jails; do
    local this_jail=${jails[$select_jail]}

    [[ $this_jail ]] || continue

    #gen jail
    services_logpath $this_jail
    local log=''
    [[ $logpath ]] && log="logpath = $logpath"

    echo "[$this_jail]
enabled = true
"$log"
" >>$jail_file

    logpath=''
    unset log
    unset logpath
  done

  systemctl restart fail2ban
  systemctl enable fail2ban
}

function gen_scripts() {
  #banip
  echo '#!/bin/sh
sudo fail2ban-client set sshd banip "$@"
' >/usr/local/bin/banip

  #unbanip
  echo '#!/bin/sh
case "$@" in
  all)
    sudo fail2ban-client unban --all
    ;;
  *)
    sudo fail2ban-client set sshd unbanip "$@"
  ;;
esac
' >/usr/local/bin/unbanip

  #ignore ip
  echo '#!/bin/sh
sudo fail2ban-client set sshd addignoreip "$@"
' >/usr/local/bin/ignoreip

  ##delete ignore ip
  echo '#!/bin/sh
sudo fail2ban-client set sshd delignoreip "$@"
' >/usr/local/bin/delignoreip

  ##sshd blacklist
  echo '#!/bin/sh
jail=$1
jail=${jail:-sshd}
sudo fail2ban-client status ${jail}

echo "usage blacklist [jail_name]
eg. blacklist sshd
"
if [[ $jail == sshd ]]
then
  echo "=====commands for sshd jail=====
banip [ip1 ip2]         : ban 1 IP or more IPs, eg, banip 8.8.8.8 9.9.9.9
unbanip [ip1 ip2]       : unban 1 IP or more IPs
unbanip all             : unban all IPs
ignoreip [ip1 ip2]     : ignore 1 IP or more IPs
delignoreip [ip1 ip2]  : delete a ignored IP"
fi
' >/usr/local/bin/blacklist

  chmod +x /usr/local/bin/{banip,unbanip,delignoreip,ignoreip,blacklist}
}

#=====
check_fail2ban_app
gen_jail_file
add_jails
gen_scripts

#=====
echo "Generate jail file done. see $jail_file"
echo -e "It add some commands for sshd jail:
\e[1mblacklist [jail name] \e[0m : show jail info (default jail is sshd）

=====commands for sshd jail=====
banip [ip1 ip2]         : ban 1 IP or more IPs, eg, banip 8.8.8.8 9.9.9.9
unbanip [ip1 ip2]       : unban 1 IP or more IPs
unbanip all             : unban all IPs
ignore_ip [ip1 ip2]     : ignore 1 IP or more IPs
delignore_ip [ip1 ip2]  : delete a ignored IP"
