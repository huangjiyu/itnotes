# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
[[ -d /usr/share/oh-my-zsh ]] && export ZSH=/usr/share/oh-my-zsh
[[ -d $HOME/.oh-my-zsh ]] && export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="ys"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git autojump)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

ZSH_CACHE_DIR=$HOME/.oh-my-zsh-cache
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

source $ZSH/oh-my-zsh.sh

autoload -U compinit
compinit


###
unalias -a

export HOSTNAME=$HOST

innerip=$(ip addr | grep -o -P '1[^2]?[0-9]?(\.[0-9]{1,3}){3}(?=\/)')
gateway=$(ip route | grep 'via' | cut -d ' ' -f 3 | uniq)
echo -e "\e[1;36m$(date)\e[0m
\e[1;32m$gateway\e[0m <-- \e[1;31m$innerip\e[0m"

# ******** important files backup******
configs_files=(.ssh/config .bashrc .zshrc .gitconfig .vimrc .makepkg.conf .bash-powerline.sh)
path_for_bakcup=~/Documents/it/itnotes/linux/config-backup/userhome

function backupconfigs() {
  cd $HOME
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      cp -auv $config ~/Documents/network/ssh/
    else
      cp -auv ~/$config $path_for_bakcup/
    fi
  done
}

function restoreconfigs() {
  for config in ${configs_files[*]}; do
    if [[ $config == .ssh/config ]]; then
      cp -auv ~/Documents/network/ssh/config ~/.ssh/config
    else
      cp -auv  $path_for_bakcup/$config ~/
    fi
  done
}

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

#iconv -- file content encoding
alias iconvgbk='iconv -f GBK -t UTF-8'
#convmv -- filename encoding
alias convmvgbk='convmv -f GBK -T UTF-8 --notest --nosmart'

#teamviwer
alias tvstart='sudo systemctl start teamviewerd.service'

#docker
alias dockerstart='sudo systemctl start docker && docker ps -a'

#libvirtd
alias virtstart='sudo modprobe virtio && sudo systemctl start libvirtd ebtables dnsmasq'

# nmap
#scan alive hosts
alias 'nmap-hosts'="sudo nmap -sS $(echo $gateway | cut -d '.' -f 1-3).0/24"

#---vim plugin
#pacman -S vim-plugin --no-comfirm
alias vimpluginstall="curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

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
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
#rustup install stable

#npm -g list --depth=0
alias npmlistg='sudo npm -g list --depth=0 2>/dev/null'
alias npmtaobao=' --registry=https://registry.npm.taobao.org'

#path
export PATH=$HOME/.local/bin:$PATH
export LD_LIBRARY_PATH=$HOME/.local/lib/:$LD_LIBRARY_PATH

