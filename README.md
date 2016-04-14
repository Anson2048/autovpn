
# 自动安装

```shell
wget --no-check-certificate https://raw.githubusercontent.com/Anson2048/autovpn/master/install.sh &&
chmod +x install.sh &&
./install.sh 2>&1 | tee auto-vpn.log
```

# 手动安装

## setp 1 install autovpn

将ip-pre-up移入/etc/ppp/，ip-down移入/etc/ppp/ip-down.d/

```shell
sudo mv autovpn /usr/sbin/autovpn

cd init.d
sudo mv autovpn /etc/init.d/autovpn

cd ../chnroutes
sudo mv ip-pre-up /etc/ppp/ip-pre-up
sudo mv ip-down /etc/ppp/ip-down.d/ip-down

sudo chmod +x /etc/init.d/autovpn
sudo chmod +x /usr/sbin/autovpn

# 如果你想开机启动可以打开
cd /etc/init.d

sudo update-rc.d autovpn defaults
```

## setp 2 configuration autovpn

```shell
# 使用命令查看vpnuuid
nmcli con list

创建配置文件 config， 写入
    USER=`whoami`

    #配置VPNUUID
    VPNUUID="${vpn_uuid}"

    MAX=10

sudo mv config， /etc/autovpn/config

```


# 其他

[chnroutes](https://github.com/fivesheep/chnroutes)
