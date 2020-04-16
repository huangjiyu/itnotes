#!/bin/sh
#By Levin   levinit.github.io

#If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -f $HOME/.bash-powerline.sh ]] && source $HOME/.bash-powerline.sh

#******** Default display ********

innerip=$(ip addr | grep -o -P '1[^2]?[0-9]?(\.[0-9]{1,3}){3}(?=\/)')
gateway=$(ip route | grep 'via' | cut -d ' ' -f 3 | uniq)
echo -e "Hi, $USER, welcome to $HOSTNAME
\e[1;36m$(date)\e[0m
\e[1;32m$gateway\e[0m <-- \e[1;31m$innerip\e[0m"

#\e[37m+++++++=====\e[0m\e[37;5m Tips \e[0m\e[37m=====+++++++\e[0m
#\e[1mrecord terminal: rec\e[0m
#\e[1mplay recordfile: play [filename]\e[0m
#\e[1mbackup configs : backupconfigs\e[0m
#\e[37m+++++=====\e[0m\e[37;5mLet's Begin\e[0m\e[37m====+++++\e[0m"

### bash settings ###
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

#HISTFILESIZE=2000
HISTTIMEFORMAT='%F %T '
HISTSIZE="5000"

# input !^ then press space-button
bind Space:magic-space

export EDITOR='vim'

# ******** important files backup******
configs_files=(.ssh/config .bashrc .gitconfig .vimrc .makepkg.conf .bash-powerline.sh)
path_for_bakcup=~/Documents/it/itnotes/linux/config-backup/userhome

function backupconfigs() {
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      \cp -auv $config ~/Documents/network/ssh/
    else
      \cp -auv ~/$config $path_for_bakcup/
    fi
  done
}

function restoreconfigs() {
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      \cp -auv ~/Documents/network/ssh/config ~/.ssh/config
    else
      \cp -auv  $path_for_bakcup/$config ~/
    fi
  done
}

# ******** alias ********
# ----- device&system -----

#trim for ssd
alias trim='sudo fstrim -v /home && sudo fstrim -v /'

#mount win
alias win='sudo ntfs-3g /dev/nvme0n1p4 /mnt/windata;sudo ntfs-3g /dev/nvme0n1p4 /mnt/winos'

#---power---
alias hs='hybrid-sleep'
alias hn='hibernate'
alias sp='suspend'
alias pf='poweroff'

#no network save power
alias nonetwork='sudo killall syncthing syncthing-gtk megasync smb nmb telegram-desktop workrave' #ss-qt5

#tlp
alias tlpbat='sudo tlp bat'
alias tlpac='sudo tlp ac'
alias tlpcputemp='sudo tlp-stat -t'

#battery info
alias batsate='cat /sys/class/power_supply/BAT0/capacity'

#CPU freq
alias cpuwatch='watch -d -n 1 cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'

#----GPU---
alias nvidiaoff='sudo tee /proc/acpi/bbswitch <<<OFF'
alias nvidiaon='sudo tee /proc/acpi/bbswitch <<<ON'
alias nvidiasettings='sudo optirun -b none nvidia-settings -c :8'

#---audio---
#beep
alias beep='sudo rmmod pcspkr && sudo echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf'

#---wireless---

#bluetooth
alias bluetoothon='sudo systemctl start bluetooth'
alias bluetoothoff='sudo systemctl stop bluetooth'

#---printer---
alias printer='sudo systemctl start org.cups.cupsd.service'

#===system commands===

#---package manager---
if [[ $(which pacman 2>/dev/null) ]]; then
  #pacman
  alias pacman='sudo pacman'
  alias orphan='sudo pacman -Rscn $(pacman -Qtdq)'
  alias pacclean='sudo paccache -rk 2 2>/dev/null'

  #upgrade
  alias up='yay && pacclean -rk 2 && orphan'

  #makepkg aur
  alias aurinfo='makepkg --printsrcinfo > .SRCINFO ; git status'

elif [[ $(which apt 2>/dev/null) ]]; then
  alias apt='sudo apt'
  alias orphan='sudo apt purge $(deborphan)'
  alias up='sudo apt dist-upgrade'
  alias aptclean='sudo apt autoremove && sudo apt autoclean'
fi

#---temporary locale---
#lang
alias sc='export LANG=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 LC_MESSAGES=zh_CN.UTF-8'
alias tc='export LANG=zh_TW.UTF-8 LC_CTYPE=zh_TW.UTF-8 LC_MESSAGES=zh_TW.UTF-8 && startx'
alias en='export LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8'

#startx (.xinitrc)
alias x='cn && startx'
alias xtc='tc && startx'
alias xsc='sc && startx'

# ---logs---
# clear 2 weeks ago logs
alias logclean='sudo journalctl --vacuum-time=1weeks'

alias lastb='sudo lastb'
alias lastlog='lastlog|grep -Ev  "\*{2}.+\*{2}"'

#---file operation---

alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'

[[ -d $HOME/.local/share/Trash/files ]] &&  alias rm='mv -f --target-directory=$HOME/.local/share/Trash/files/'

alias cp='cp -i'

alias grep='grep --color'

alias tree='tree -C -L 1 --dirsfirst'

#---network---
# proxychains
alias px='proxychains'

# ssh server
alias sshstart='sudo systemctl start sshd'

# update hosts
alias hosts='sudo curl -# -L -o /etc/hosts https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts'

#iconv -- file content encoding
alias iconvgbk='iconv -f GBK -t UTF-8'
#convmv -- filename encoding
alias convmvgbk='convmv -f GBK -T UTF-8 --notest --nosmart'

#teamviwer
alias tvstart='sudo systemctl start teamviewerd.service'

#docker
alias dockerstart='sudo systemctl start docker && docker ps -a'
alias hack='sudo systemctl start docker && docker start hack && docker exec -it hack bash'

#libvirtd
alias virtstart='sudo modprobe virtio && sudo systemctl start libvirtd ebtables dnsmasq'

# nmap
#scan alive hosts
alias 'nmap-hosts'="sudo nmap -sS $(echo $gateway | cut -d '.' -f 1-3).0/24"

#install/update geoip database
alias geoipdata="cd /tmp && wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz && wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz && gunzip GeoIP.dat.gz && gunzip GeoIPASNum.dat.gz && gunzip GeoLiteCity.dat.gz && sudo cp GeoIP.dat GeoIPASNum.dat GeoLiteCity.dat /usr/share/GeoIP/ && cd -"

#---vim plugin
#pacman -S vim-plugin --no-comfirm
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

# autojump
[[ -s /usr/share/autojump/autojump.bash ]] && . /usr/share/autojump/autojump.bash

#---for fun---
#cmatrix
alias matrix='cmatrix'

#starwar
alias starwar='telnet towel.blinkenlights.nl'

#asciinema record terminal
alias rec='asciinema rec -i 5 terminal-`date +%Y%m%d-%H%M%S`' #record
alias play='asciinema play'                                   #play record file


#安装中文古诗词
function install_fortune_gushici() {
  git clone --recursive https://github.com/shenyunhang/fortune-zh-data.git
  cd fortune-zh-data
  sudo cp * /usr/share/fortunes/
}
if [[ $(which fortune 2>/dev/null) ]]; then
  fortune -e tang300 song100 #先秦 两汉 魏晋 南北朝 隋代 唐代 五代 宋代 #金朝 元代 明代 清代
#if [[ ! -e /usr/share/fortunes/先秦.dat ]]
#then
#echo "可使用命令"install_fortune_gushici"下载古诗词数据"
#fi
fi

#-----dev-----
# rust chinese mirror
RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
#rustup install stable

#npm -g list --depth=0
alias npmlistg='sudo npm -g list --depth=0 2>/dev/null'
alias npmtaobao=' --registry=https://registry.npm.taobao.org'

#path
export PATH=$HOME/.local/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/lib/:$LD_LIBRARY_PATH

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
