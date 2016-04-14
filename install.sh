#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Install AutoVPN for Debian or Ubuntu
#   Author: Anson Hu <anson2048.com>
#   Intro:  http://anson2048.com
#===============================================================================================

clear
echo ""
echo "#############################################################"
echo "# Install AutoVPN for Debian or Ubuntu"
echo "# Intro: http://anson2048.com"
echo "#"
echo "# Author: Anson Hu <anson2048.com>"
echo "#"
echo "#############################################################"
echo ""

# Install autovpn
function install_autovpn(){
    rootness
    disable_selinux
    pre_install
    download_files
    config_autovpn
    install
}

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Disable selinux
function disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Pre-installation settings
function pre_install(){
    echo "网络连接列表:"
    nmcli con list | grep vpn
    #Set autovpn config uuid
    echo "####################################"

    read -p "(输入你vpn的名称 | 默认为:VPN connection 1 ): " vpn_name
    if [ "$vpn_name" = "" ]; then
        vpn_name="VPN connection 1"
    fi
    firstVPN=$(nmcli con list | grep "$vpn_name" | grep -o -E '[0-9,a-f,A-F,/-]{36}' | head -n 1)

    if [ "$firstVPN" = "" ]; then
        echo "找不到你的vpn， 安装失败"
        exit 1
    fi

    echo "比对uuid是否正确，不正确请手动输入:"
    read -p "(Default uuid: $firstVPN):" vpn_uuid
    if [ "$vpn_uuid" = "" ]; then
        vpn_uuid=$firstVPN
    fi

    boot=true
    echo "是否需要开机启动:(y/n)"
    read -p "(Default: y):" bootInput
    if [ "$bootInput" = "n" ]; then
        boot=false
    fi

    chnRoute=true
    echo "是否需要修改路由表科学上网:(y/n)"
    read -p "(Default: y):" chnRouteInput
    if [ "$chnRouteInput" = "n" ]; then
        chnRoute=false
    fi

    echo "####################################"
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "按任意键继续，或者 Ctrl+C 退出安装"
    char=`get_char`

    cur_dir=`pwd`
    cd $cur_dir
}

# Download latest autovpn
function download_files(){
    if [ -f autovpn.zip ];then
        echo "autovpn.zip [found]"
    else
        if ! wget --no-check-certificate https://github.com/Anson2048/autovpn/archive/master.zip -O autovpn.zip;then
            echo "Failed to download autovpn.zip"
            exit 1
        fi
    fi
    unzip autovpn.zip
    if [ $? -eq 0 ];then
        cd $cur_dir/autovpn-master/
        if ! wget --no-check-certificate https://raw.githubusercontent.com/Anson2048/autovpn/master/install.sh; then
            echo "Failed to download autovpn start script!"
            exit 1
        fi
    else
        echo ""
        echo "Unzip autovpn failed!"
        exit 1
    fi
}

# Config autovpn
function config_autovpn(){
    if [ ! -d /etc/autovpn ];then
        mkdir /etc/autovpn
    fi
    cat > /etc/autovpn/config<<-EOF
    #!/bin/bash

    # 配置需要连接vpn的用户名
    USER=`whoami`

    #配置VPNUUID
    VPNUUID="${vpn_uuid}"

    MAX=10
EOF

}

# Install
function install(){
    # Build and Install autovpn
    if [ -s /usr/sbin/autovpn ];then
        echo "autovpn has been installed!"
        exit 0
    else
        if [ -s $cur_dir/autovpn-master/autovpn ];then
            mv $cur_dir/autovpn-master/autovpn /usr/sbin/autovpn
            chmod +x /usr/sbin/autovpn
        else
            echo "autovpn install failed! File missing"
            exit 1
        fi

        if [ $? -eq 0 ]; then
            if [ -s $cur_dir/autovpn-master/init.d/autovpn ]; then
                # Add run on system start up
                mv $cur_dir/autovpn-master/init.d/autovpn /etc/init.d/autovpn
                chmod +x /etc/init.d/autovpn

                if [ "$boot"]; then
                    update-rc.d autovpn defaults
                fi

                if [ "$chnRoute"]; then
                    mv /etc/ppp/ip-pre-up /etc/ppp/ip-pre-up.bk
                    mv /etc/ppp/ip-down.d/ip-down /etc/ppp/ip-down.d/ip-down.bk
                    mv $cur_dir/autovpn-master/chnroutes/ip-pre-up /etc/ppp/ip-pre-up
                    mv $cur_dir/autovpn-master/chnroutes/ip-down /etc/ppp/ip-down.d/ip-down
                fi

                # Run autovpn in the background
                /etc/init.d/autovpn start
                # Run success or not
                if [ $? -eq 0 ]; then
                    echo "autovpn start success!"
                else
                    echo "autovpn start failure!"
                fi
            else
                echo "autovpn install failed! File missing"
                exit 1
            fi
        else
            echo ""
            echo "autovpn install failed! Please visit http://anson2048.com and contact."
            exit 1
        fi
    fi
    cd $cur_dir
    # # Delete autovpn floder
    rm -rf $cur_dir/autovpn-master/
    # # Delete autovpn zip file
    rm -f autovpn.zip
    clear
    echo ""
    echo "Congratulations, autovpn install completed!"
    echo -e "Your vpn_uuid: \033[41;37m ${vpn_uuid} \033[0m"
    echo -e "Your max: \033[41;37m 10 \033[0m"
    echo ""
    echo "Welcome to visit:http://anson2048.com"
    echo "Enjoy it!"
    echo ""
    exit 0
}

# Uninstall autovpn
function uninstall_autovpn(){
    rootness
    disable_selinux
    printf "Are you sure uninstall autovpn? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        ps -ef | grep -v grep | grep -v ps | grep -i "autovpn" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/autovpn stop
        fi
        # remove auto start script
        update-rc.d -f autovpn remove
        # delete config file
        rm -rf /etc/autovpn
        # delete autovpn
        rm -rf /usr/sbin/autovpn
        rm -rf /etc/init.d/autovpn

        if [ -s /etc/ppp/ip-pre-up.bk ]; then
            mv /etc/ppp/ip-pre-up.bk /etc/ppp/ip-pre-up
            mv /etc/ppp/ip-down.d/ip-down.bk /etc/ppp/ip-down.d/ip-down
        fi

        echo "autovpn uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_autovpn
    ;;
uninstall)
    uninstall_autovpn
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
