#!/usr/bin/env bash

# Selinux Disable
setenforce 1
sed -i "s/SELINUX=disabled/SELINUX=enforcing/" /etc/selinux/config

# vim configuration 
echo "sudo su - clex" >> .bashrc

# swapoff -a to disable swapping
#swapoff -a
# sed to comment the swap partition in /etc/fstab
#sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# config sshd
#Disable Message when using ssh 'Are you sure you want to continue connecting'
sudo sed -i '/StrictHostKeyChecking/a StrictHostKeyChecking no' /etc/ssh/ssh_config

echo ">>>> ssh-config <<<<<<"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config

#sudo sed -i '/PermitRootLogin no/d' /etc/ssh/sshd_config
#sudo sed -i '/#PermitRootLogin yes/a PermitRootLogin no' /etc/ssh/sshd_config

# config chrony server
#sed -i 's/^server*/#server/g' /etc/chrony.conf
#sed -i '/server 3/a server control01 iburst' /etc/chrony.conf

# SSH UseDNS disable, disable root login, login grace 5m
sudo sed -i '/UseDNS no/d' /etc/ssh/sshd_config
sudo sed -i '/#UseDNS/a UseDNS no' /etc/ssh/sshd_config
echo -e "TMOUT=300\nexport TMOUT" | sudo tee -a /etc/profile
source /etc/profile

systemctl restart sshd

# Clex User Create
adduser clex -u 1100 -G wheel -p $(echo 'cloud!234' | openssl passwd -1 -stdin)

# RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
#cat <<EOF >  /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#modprobe br_netfilter
#sysctl --system

# local small dns & vagrant cannot parse and delivery shell code.
for (( i=1; i<=$3; i++  )); do echo "192.168.20.1$i control0$i" >> /etc/hosts; done
for (( i=1; i<=$2; i++  )); do echo "192.168.20.10$i compute0$i" >> /etc/hosts; done
for (( i=1; i<=$3; i++  )); do echo "192.168.20.20$i ceph0$i" >> /etc/hosts; done
for (( i=1; i<=$2; i++  )); do echo "192.168.20.15$i network$i" >> /etc/hosts; done

# add pcadmin to sudoers
#perl -p -i -e '$.==104 and print "%wheel        ALL=(ALL)       NOPASSWD: ALL\n"' /etc/sudoers

sed -i '110 a %wheel        ALL=(ALL)       NOPASSWD: ALL\n' /etc/sudoers

# ulimit openfiles set all users to 1024000
echo "###### ulimit openfiles set all users to 1024000"
echo -e "\n*\tsoft\tnofile\t1024000\n*\thard\tnofile\t1024000" | sudo tee -a /etc/security/limits.conf

# config DNS  
cat <<EOF > /etc/resolv.conf
#nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

# Ignore ACPI logs
echo "###### Ignore ACPI logs"
sed -i '/ACPI/d' /etc/rsyslog.conf && sed -i '/\/var\/log\/messages/i :rawmsg, contains, "ACPI" ~' /etc/rsyslog.conf
sudo systemctl restart rsyslog
sudo modprobe -r acpi_power_meter
cat <<EOF | sudo tee /etc/modprobe.d/acpi_power_meter.conf
blacklist acpi_power_meter
EOF

# Separate kubelet logs
#echo "###### Separate kubelet logs"
#echo -e "if \$programname == 'kubelet' then /var/log/kubelet.log\n& stop" | sudo tee /etc/rsyslog.d/kubelet.conf
#sudo systemctl restart rsyslog

# Separate kernel logs
echo "###### Separate kernel logs"
sudo sed -i '/kern.log/d' /etc/rsyslog.conf && sudo sed -i '/#kern.*/a kern.*                                                 -/var/log/kern.log' /etc/rsyslog.conf
sudo systemctl restart rsyslog

# logrotate - syslog
echo "###### logrotate - syslog"
cat <<EOF | sudo tee /etc/logrotate.d/syslog
/var/log/cron
/var/log/kern.log
/var/log/kubelet.log
/var/log/maillog
/var/log/messages
/var/log/secure
/var/log/sulog
/var/log/spooler
{
    missingok
    rotate 24
    weekly
    compress
    sharedscripts
    create 0600 root root
    postrotate
        /bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true
    endscript
}
EOF

###### yum clean all
#sudo yum install -y net-tools telnet dstat sysstat chrony lsof vim
yum clean all

###### dnf clean all
dnf clean all

###### cmd logging
cat <<EOF | sudo tee /etc/profile.d/cmdlog.sh
function cmdlog
{
f_ip=\`who am i | awk '{print \$5}'\`
cmd=\`history | tail -1\`
if [ "\$cmd" != "\$cmd_old" ]; then
  logger -p local1.notice "[1] From_IP=\$f_ip, PWD=\$PWD, Command=\$cmd"
fi
  cmd_old=\$cmd
}
trap cmdlog DEBUG
EOF

sudo sed -i '/cmdlog/d' /etc/rsyslog.conf
sudo sed -i '/cron.none/i local1.notice\t\t\t\t\t\t/var/log/cmdlog' /etc/rsyslog.conf
sudo sed -i 's/cron.none/cron.none;local1.none/g' /etc/rsyslog.conf

cat <<EOF | sudo tee /etc/logrotate.d/cmdlog
/var/log/cmdlog {
    missingok
    minsize 30M
    create 0600 root root
}
EOF

sudo systemctl restart rsyslog
#sudo systemctl disable NetworkManager
sudo systemctl disable firewalld

# Kernel Parameters for Docker

cat <<EOF | sudo tee -a /etc/sysctl.conf
# enable the setting in order for Docker remove the containers cleanly
#fs.may_detach_mounts = 1
# enable forwarding so the Docker networking works as expected
net.ipv4.ip_forward = 1
# Make sure the host doesn't swap too early
#vm.swappiness = 1
# Enable Memory Overcommit
vm.overcommit_memory = 1
# kernel not to panic when it runs out of memory
vm.panic_on_oom = 0
# Increasing the amount of inotify watchers
fs.inotify.max_user_watches = 524288
fs.file-max = 2048000
fs.nr_open = 2048000
EOF

# Tune Network Setting

cat << EOF | sudo tee /etc/sysctl.d/70-cloudpcnetwork.conf

net.netfilter.nf_conntrack_max = 1000000

net.core.somaxconn=1000
net.ipv4.netdev_max_backlog=5000
net.core.rmem_max=16777216
net.core.wmem_max=16777216

net.ipv4.tcp_rmem=4096 12582912 16777216
net.ipv4.tcp_wmem=4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=10240 65535
net.ipv4.tcp_abort_on_overflow = 1
EOF

# Increase bash history size and time format
cat <<EOF | sudo tee -a /etc/bashrc
export HISTTIMEFORMAT="%h %d %H:%M:%S "
export HISTSIZE=10000
EOF

# disable local-link network
echo "NOZEROCONF=yes"| sudo tee -a /etc/sysconfig/network

# Add provider nic eth3 config"
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth3
TYPE=Ethernet
BOOTPROTO=none
DEVICE=eth3
ONBOOT=yes
ONPARENT=yes
MTU=1500
EOF

# Disk Parttion Resize
parted /dev/vda resizepart 2 100%
pvresize /dev/vda2
lvextend -l +100%FREE /dev/bkos/root
xfs_growfs /dev/bkos/root

##### [U-69] login warning message banner
cat << EOF |sudo tee /etc/motd
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

cat << EOF |sudo tee /etc/issue.net
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

cat << EOF |sudo tee /etc/banner
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

sudo sed -i '1iBanner /etc/banner' /etc/ssh/sshd_config

#remove cockpit
cd /etc/motd.d
sudo rm -rf cockpit

# BKOS install package all node
#sudo dnf -y install epel-release
#sudo dnf -y install python3



# CloudPC install package download
if [ `echo $(hostname)` = "control01" ]
then
sed -i 's/server control01 iburst/local stratum 10/'  /etc/chrony.conf
sed -i 's/#allow 192.168.0.0\/16/allow 192.168.20.0\/24/' /etc/chrony.conf
#curl -LO -s http://192.168.151.50:8090/iso/v2/cloudx-pkg-2.0.7.tar -u skb:agilE^@66
#curl -LO -s http://192.168.151.50:8090/iso/v2/cloudpc-helm-v18.tar.gz -u skb:agilE^@66 
#mv cloudx-pkg-2.0.7.tar cloudpc-helm-v18.tar.gz /home/clex
chown clex.clex -R /home/clex/
echo "You shuld wait for 3min to connect contro01. it need rebooting time" 
fi

systemctl restart chronyd

# reboot after installing
reboot
