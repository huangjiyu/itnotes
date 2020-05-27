#!/bin/sh
if [[ $USER != root ]]; then
  echo "need root or sudo."
  exit
fi

#-----
jail_file=/etc/fail2ban/jail.d/jail.local

jails=(sshd mongodb-auth mysqld-auth vsftpd)

#log path

bandtime=8640000 #默认秒s m h d w
findtime=6000
maxretry=5

#-----

#install fail2ban
which pacman 2>/dev/null || pacman -Syy fail2ban --no-confirm

if [[ ! $(which fail2ban-server) ]]; then
  echo "please install fail2ban"
  exit
fi

function services_logs() {
  case $1 in
  mongodb-auth)
    echo "/var/log/mongodb/mongod.log"
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
    log=$(services_logs $this_jail)
    [[ $log ]] && logpath="logpath = $log"

    echo "[$this_jail]
enabled = true
"$logpath"
" >>$jail_file

    unset log
    unset logpath
  done

  systemctl restart fail2ban
  systemctl enable fail2ban
}

function gen_scripts() {
  ##ban_ip
  echo '#!/bin/sh
fail2ban-client set sshd banip "$*"
' >/usr/local/bin/ban_ip

  ##unban_ip
  echo '#!/bin/sh
case "$*" in
  all)
    fail2ban-client unban --all
    ;;
  *)
    fail2ban-client set sshd unbanip "$*"
  ;;
esac
' >/usr/local/bin/unban_ip

  #ignore ip
  echo '#!/bin/sh
fail2ban-client set sshd addignoreip "$*"
' >/usr/local/bin/ignore_ip

  ##delete ignore ip
  echo '#!/bin/sh
fail2ban-client set sshd delignoreip "$*"
' >/usr/local/bin/delignore_ip

  ##sshd blacklist
  echo '#!/bin/sh
fail2ban-client status sshd
echo "=====for sshd jail====="
echo "see all banned IP: blacklist"
echo "ban IP example: ban_ip 8.8.8.8"
echo "unban IP example: unban_ip 8.8.8.8"
echo "unban all IP example: unban_ip all"
echo "ignore IP example: ignore_ip 8.8.8.8"
echo "delete ignore IP example: delignore_ip 8.8.8.8"

' >/usr/local/bin/blacklist

  chmod +x /usr/local/bin/{ban_ip,unban_ip,delignore_ip,ignore_ip,blacklist}
}

function gen_jail_file() {
  [[ -f $jail_file ]] && mv $jail_file $jail_file.bak

  echo "[DEFAULT]
bantime = $bandtime
findtime = $findtime
maxretry = $maxretry
" >$jail_file
}

gen_jail_file
add_jails
gen_scripts
blacklist

echo "-----fail2ban jail list-----"
fail2ban-client status
